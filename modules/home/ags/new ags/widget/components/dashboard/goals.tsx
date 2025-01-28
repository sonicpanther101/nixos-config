import { readFileAsync, Variable, execAsync, bind } from "astal"
import { Gtk, Gdk, Widget, Astal } from "astal/gtk4";
import Pango from "gi://Pango?version=1.0";

const goal_list = Variable<GoalDefinition[]>([])
const changed = Variable<boolean>(false)
const input = Variable("")
const displayMode = Variable(true)
let gistID = ""
let token = ""

function changedHandler() {
  changed.set(!changed.get())
}

readFileAsync(`/home/adam/.cache/astal/secrets.json`).then((secrets) => {
  let parsed = JSON.parse(secrets)
  gistID = parsed.goals_gist_id
  token = parsed.token
  if (gistID === "") {
    print("goals id not found in secrets.json")
    return
  } else if (token === "") {
    print("token not found in secrets.json")
    return
  }
  readUpdate()
}).catch(print)

const refresh = <button
  className="goal-refresh"
  visible={bind(displayMode).as(b => !b)}
  onClicked={() => {
    readUpdate()
  }}
>
  <label label="↻" className="goal-button-label" />
</button>;

const Entry = new Widget.Entry({
  text: bind(input),
  visible: bind(displayMode).as(b => !b),
  hexpand: true,
  canFocus: true,
  placeholderText: "Enter goal",
  className: "goals-entry",
  onActivate: (self: Widget.Entry) => {
    if (self.get_text() === "") {
      return
    }
    goal_list.set([{label: self.get_text()}, ...goal_list.get()])
    input.set("")
    writeUpdate()
  },
  setup: (self) => {
    self.hook(self, "notify::text", () => {
      input.set(self.get_text());
    });
  }
});

const displayToggle = <button
  hexpand={false}
  className={bind(displayMode).as(b => `goal-display-toggle ${b ? "display-toggle-rounded" : ""}`)}
  onClicked={() => {
    displayMode.set(!displayMode.get())
  }}
>
  <label label="✎" className="goal-button-label" />
</button>;

interface GoalDefinition {
  label: string;
  subgoals?: GoalDefinition[];
  editMode?: boolean;
  subgoalsShown?: boolean;
  status?: number;
}

function getTarget(treePosition: number[], handler: (target: GoalDefinition) => void) {
  let temp = goal_list.get();
  const target = treePosition.slice(1).reduce((acc, curr, index) => {
    if (index >= treePosition.length - 1) {
      return acc;
    } else {
      return acc.subgoals?.[curr] || acc; 
    }
  }, temp[treePosition[0]]); 

  handler(target);
  goal_list.set(temp); 
  changedHandler();
}

function getTargetParent(treePosition: number[], handler: (parent: GoalDefinition) => any) {
  let temp = goal_list.get();
  const parent = treePosition.slice(1).reduce((acc, curr, index) => {
    if (index >= treePosition.length - 2) {
      return acc;
    } else {
      return acc.subgoals?.[curr] || acc; 
    }
  }, temp[treePosition[0]]); 
  
  handler(parent)
  goal_list.set(temp); 
  changedHandler();
}

function createGoals(definition: GoalDefinition, i: number, treePosition: number[]) {
  
  let parent = treePosition.slice(1).reduce((acc, curr, index) => {
    if (index >= treePosition.length - 2) {
      return acc;
    } else {
      return acc.subgoals?.[curr] || acc; 
    }
  }, goal_list.get()[treePosition[0]]);

  const onScroll: (_: Widget.EventBox, e: Astal.ScrollEvent) => void = (_: Widget.EventBox, e: Astal.ScrollEvent) => {
    let direction: -1 | 1 | null = null;
    if (e.direction == Gdk.ScrollDirection.SMOOTH) {
        direction = Math.sign(e.delta_y) as 1 | -1;
    } else if (e.direction == Gdk.ScrollDirection.UP) {
        direction = 1;
    } else if (e.direction == Gdk.ScrollDirection.DOWN) {
        direction = -1;
    }
    if (direction === null) return
    getTarget(treePosition, (target) => {
      target.status = (typeof target.status === "number") ? Math.min(100, Math.max(0, (Math.round(target.status/5)*5 === target.status ? (target.status - direction*5) : (Math.round(target.status/5)*5)))) : undefined;
    })
    writeUpdate()
  };

  return (
  <box
    hexpand
    className={i % 2 === 0 ? "even-scroll" : "odd-scroll"}
  >
    <box
      vertical
      vexpand={false}
    >
      <button
        vexpand
        className={`goal-up ${i === 0 ? "goal-up-disabled" : ""}`}
        onClick={() => {
          if (i === 0) return
          let temp = definition
          if (treePosition.length === 1) {
            let templist = goal_list.get()
            templist.splice(i, 1)
            templist.splice(i - 1, 0, temp)
            goal_list.set(templist)
            changedHandler()
          } else {
            getTargetParent(treePosition, (parent) => {
              parent.subgoals?.splice(i, 1)
              parent.subgoals?.splice(i - 1, 0, temp)
            })
          }
          writeUpdate()
        }}
      >
        <label label="⏶" className={`goal-button-label ${i === 0 ? "goal-up-disabled" : ""}`} />
      </button>
      <button
        vexpand
        className={`goal-down ${(treePosition.length === 1 ? i === goal_list.get().length - 1 : i + 1 === parent.subgoals?.length) ? "goal-down-disabled" : ""}`}
        onClick={() => {
          if (treePosition.length === 1 ? i === goal_list.get().length - 1 : i + 1 === parent.subgoals?.length) return
          let temp = definition
          if (treePosition.length === 1) {
            let templist = goal_list.get()
            templist.splice(i, 1)
            templist.splice(i + 1, 0, temp)
            goal_list.set(templist)
            changedHandler()
          } else {
            getTargetParent(treePosition, (parent) => {
              parent.subgoals?.splice(i, 1)
              parent.subgoals?.splice(i + 1, 0, temp)
            })
          }
          writeUpdate()
        }}
      >
        <label label="⏷" className="goal-button-label" />
      </button>
    </box>
    <button
      className={`goal-edit ${definition.subgoals?.length ? "" : "rounded"}`}
      onClick={() => {
        getTarget(treePosition, (target) => {
          target.editMode = !target.editMode
        })
      }}
    >
      <label label="✎" className="goal-button-label" />
    </button>
    {definition.subgoals?.length && <button
      className="toggle-subgoals"
      onClick={() => {
        getTarget(treePosition, (target) => {
          target.subgoalsShown = !target.subgoalsShown
        })
      }}
    >
      <label label={definition.subgoalsShown ? "▼" : "▶"} css="font-size: 1rem;"className="goal-button-label" />
    </button>}
    <box vertical>
      {definition.editMode ?
        <entry
          text={definition.label}
          widthChars={120}
          className="goal edit"
          onActivate={(self) => getTarget(treePosition, (target) => { target.editMode = false; target.label = self.get_text(); writeUpdate() })}
          hexpand
          onRealize={(self) => { self.grab_focus() }}
          halign={Gtk.Align.START}
        /> :
        <label hexpand label={definition.label} wrap wrapMode={Pango.WrapMode.WORD_CHAR} halign={Gtk.Align.START} className="goal" />}
      {definition.subgoalsShown && definition.subgoals && definition.subgoals.map((goal, i) => createGoals(goal, i, [...treePosition, i]))}
    </box>
      {(typeof definition.status === "number") ?
        <eventbox onScroll={onScroll}>
          <box>
            <slider max={100} step={1} className="status-slider" onDragged={self => { getTarget(treePosition, (target) => { target.status = Math.round(self.get_value()); writeUpdate() }); }} value={definition.status} />
            <label className="status-label" label={` ${definition.status === 100 ? "" : definition.status < 10 ? "  " : " "}${definition.status}%`} />
          </box>
        </eventbox> :
        <button
          className="status-add"
          onClick={() => {
            getTarget(treePosition, (target) => {
              target.status = 0
            })
          }}
        >
          <label label="Add Status" css="font-size: 0.6rem;" className="goal-button-label" />
        </button>
      }
    <button
      className="subgoal-add"
      onClick={() => {
        getTarget(treePosition, (target) => {
          target.subgoals = target.subgoals || []
          target.subgoals.splice(0, 0, { label: "", editMode: true })
          target.subgoalsShown = true
        })
      }}
    >
      <label label="+" className="goal-button-label" />
    </button>
    <button
      className="goal-delete"
      onClick={() => {
        if (treePosition.length === 1) {
          let temp = goal_list.get()
          temp.splice(i, 1)
          goal_list.set(temp)
          changedHandler()
        } else {
          getTargetParent(treePosition, (parent) => {
            parent.subgoals?.splice(i, 1)
          })
        }
        writeUpdate()
      }}
      >
        <label label="✕" className="goal-button-label" />
      </button>
  </box>
  )
};

function createDisplayGoals(definition: GoalDefinition, i: number, treePosition: number[]) {

  return (
  <box
    hexpand
    className={i % 2 === 0 ? "even-scroll" : "odd-scroll"}
  >
    <label label="●" className={`goal-button-label point ${definition.subgoals?.length ? "" : "rounded"}`} />
    {definition.subgoals?.length && <button
      className={`toggle-subgoals ${definition.subgoalsShown ? "" : "not-toggled"}`}
      onClick={() => {
        getTarget(treePosition, (target) => {
          target.subgoalsShown = !target.subgoalsShown
        })
        writeUpdate()
      }}
    >
      <label label={definition.subgoalsShown ? "▼" : "▶"} css="font-size: 1rem;"className="goal-button-label" />
    </button>}
    <box vertical>
      <label hexpand label={definition.label} wrap wrapMode={Pango.WrapMode.WORD_CHAR} halign={Gtk.Align.START} className="goal" />
      {definition.subgoalsShown && definition.subgoals && definition.subgoals.map((goal, i) => createDisplayGoals(goal, i, [...treePosition, i]))}
    </box>
      {(typeof definition.status === "number") &&
        <box>
          <slider max={100} step={1} className="status-slider" value={definition.status} />
          <label className="status-label" label={` ${definition.status === 100 ? "" : definition.status < 10 ? "  " : " "}${definition.status}%`} />
        </box>
      }
  </box>
  )
};

const items = Variable.derive([goal_list, changed, displayMode], (goal_list, changed, displayMode) => {
  return displayMode ? goal_list.map((goal, i) => createDisplayGoals(goal, i, [i])) : goal_list.map((goal, i) => createGoals(goal, i, [i]))
})
 
function readUpdate() {
  execAsync(['bash', '-c', `curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/gists/${gistID}`]).then(out => {
    
    const data = JSON.parse(out)["files"]["goals.json"]["content"]

    const goals = JSON.parse(data)

    goal_list.set(goals)
  }).catch(print)
}

function writeUpdate() {
  print("update")

  function removeDisplayProperties(goal: GoalDefinition): GoalDefinition {
    return {
      label: goal.label,
      subgoals:
        goal.subgoals?.map(subgoal =>
          removeDisplayProperties(subgoal)
        ),
      status: goal.status,
      subgoalsShown: goal.subgoalsShown
    };
  }

  const out = JSON.stringify(goal_list.get().map(removeDisplayProperties)).replace(/{/g, '\\n{').replace(/]/g, '\\n]').replace(/"/g, "\\\"")

  print(`curl -L \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/gists/${gistID} \
    -d '{"description":"Updated Gist","files":{"goals.json":{"content":"${out}"}}}'
  `)

  execAsync(['bash', '-c', `curl -L \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/gists/${gistID} \
    -d '{"description":"Updated Gist","files":{"goals.json":{"content":"${out}"}}}'
  `]).catch(print);
}

const Goals = (
  <box
    className="goals"
    vertical
  >
    <scrollable
      vexpand
      hexpand
    >
      <box
        vertical
      >
        {bind(items)}
      </box>
    </scrollable>
    <box>
      {displayToggle}
      {refresh}
      {Entry}
    </box>
  </box>
)

export default Goals