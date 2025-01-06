import { readFileAsync, Variable, execAsync, bind } from "astal"
import { Gtk, Gdk, Widget, Astal } from "astal/gtk3";
import Pango from "gi://Pango?version=1.0";

const item_list = Variable<ItemDefinition[]>([])
const changed = Variable<boolean>(false)
const input = Variable("")
const priceInput = Variable("")
const Savings = Variable(0)
const savingsEdit = Variable(false)
let gistID = ""
let token = ""

interface ItemDefinition {
  label: string;
  subitems?: ItemDefinition[];
  editMode?: boolean;
  subitemsShown?: boolean;
  price?: number;
}

function changedHandler() {
  changed.set(!changed.get())
}

readFileAsync(`/home/adam/.cache/astal/secrets.json`).then((secrets) => {
  let parsed = JSON.parse(secrets)
  gistID = parsed.budget_gist_id
  token = parsed.token
  if (gistID === "") {
    print("todo directory not found in secrets.json")
    return
  } else if (token === "") {
    print("token not found in secrets.json")
    return
  }
  readUpdate()
}).catch(print)

function getTarget(treePosition: number[], handler: (target: ItemDefinition) => void) {
  let temp = item_list.get();
  const target = treePosition.slice(1).reduce((acc, curr, index) => {
    if (index >= treePosition.length - 1) {
      return acc;
    } else {
      return acc.subitems?.[curr] || acc; 
    }
  }, temp[treePosition[0]]); 

  handler(target);
  item_list.set(temp); 
  changedHandler();
}

const savings = Variable.derive([Savings, savingsEdit], () => {

  const onScroll: (_: Widget.Button, e: Astal.ScrollEvent) => void = (_: Widget.Button, e: Astal.ScrollEvent) => {
    let direction: -1 | 1 | null = null;
    if (e.direction == Gdk.ScrollDirection.SMOOTH) {
        direction = Math.sign(e.delta_y) as 1 | -1;
    } else if (e.direction == Gdk.ScrollDirection.UP) {
        direction = 1;
    } else if (e.direction == Gdk.ScrollDirection.DOWN) {
        direction = -1;
    }
    if (direction === null) return
    Savings.set(Math.max(0, Math.round(Savings.get()/50)*50 - direction*50));
    writeUpdate()
  };

  const onClick: Widget.ButtonProps["onClick"] = (_, e: Astal.ClickEvent) => {
    if (e.button === Gdk.BUTTON_PRIMARY) {
      savingsEdit.set(true)
    }
  };

  let Format = new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
  });

  return savingsEdit.get() ?
    <entry
      text={`${Savings.get()}`}
      onActivate={() => { Savings.set(isNaN(PriceEntry.get_text() as unknown as number) ? Savings.get() : Number(input.get())); savingsEdit.set(false) }}
      className="savings edit"
      widthChars={9}
      onRealize={(self) => { self.grab_focus() }}
    /> : <button
      className="savings"
      onScroll={onScroll}
      onClick={onClick}
    >
      <label label={`${Format.format(Savings.get())}`}/>
    </button>
})

const items = Variable.derive([item_list, changed], (item_list, changed) => {
  return item_list.map((item, i) => createItems(item, i, [i]))
})

function createItems(definition: ItemDefinition, i: number, treePosition: number[]) {
  
  let parent = treePosition.slice(1).reduce((acc, curr, index) => {
    if (index >= treePosition.length - 2) {
      return acc;
    } else {
      return acc.subitems?.[curr] || acc; 
    }
  }, item_list.get()[treePosition[0]]);

  const onScroll: (_: Widget.Button, e: Astal.ScrollEvent) => void = (_: Widget.Button, e: Astal.ScrollEvent) => {
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
      target.price = (typeof target.price === "number") ? Math.min(100, Math.max(0, Math.round(target.price/50)*50 - direction*50)) : undefined;
    })
    writeUpdate()
  };

  return (
    <box>

    </box>
  )
};

function readUpdate() {
  execAsync(['bash', '-c', `curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${token}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/gists/${gistID}`]).then(out => {
    
    const data = JSON.parse(out)["files"]["budget.json"]["content"]

    const items = JSON.parse(data).slice(0, -1)

    Savings.set(JSON.parse(data)[items.length].price)
    item_list.set(items)
  }).catch(print)
}

function writeUpdate() {
  print("update")

  function removeDisplayProperties(task: ItemDefinition): ItemDefinition {
    return {
      label: task.label,
      subitems:
        task.subitems?.map(subitem =>
          removeDisplayProperties(subitem)
        ),
      price: task.price
    };
  }

  const out = JSON.stringify(item_list.get().map(removeDisplayProperties).concat([{ label: 'Savings', price: Savings.get() }])).replace(/{/g, '\\n{').replace(/]/g, '\\n]').replace(/"/g, "\\\"")

  execAsync(['bash', '-c', `curl -L \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/gists/${gistID} \
    -d '{"description":"Updated Gist","files":{"budget.json":{"content":"${out}"}}}'
  `]).catch(print);
}

const refresh = <button
  className="task-refresh"
  onClicked={() => {
    readUpdate()
  }}
>
  <label label="↻" className="task-button-label" />
</button>;

const Entry = new Widget.Entry({
  text: bind(input),
  hexpand: true,
  canFocus: true,
  placeholderText: "Enter task",
  className: "entry",
  onActivate: () => {
    if (Entry.get_text() === "") {
      return
    }
    item_list.set([...item_list.get(), {label: Entry.get_text(), price: isNaN(PriceEntry.get_text() as unknown as number) ? undefined : (PriceEntry.get_text() as unknown as number)}])
    input.set("")
    priceInput.set("")
    writeUpdate()
  },
  setup: (self) => {
    self.hook(self, "notify::text", () => {
      input.set(self.get_text());
    });
  }
});

const PriceEntry = new Widget.Entry({
  text: bind(priceInput),
  hexpand: true,
  canFocus: true,
  placeholderText: "Enter task",
  className: "price-entry",
  onActivate: () => {
    if (PriceEntry.get_text() === "" || Entry.get_text() === "" || isNaN(PriceEntry.get_text() as unknown as number)) {
      return
    }
    item_list.set([...item_list.get(), {label: Entry.get_text(), price: (PriceEntry.get_text() as unknown as number)}])
    input.set("")
    priceInput.set("")
    writeUpdate()
  },
  setup: (self) => {
    self.hook(self, "notify::text", () => {
      priceInput.set(self.get_text());
    });
  }
});

const Budget = (
  <box
    className="tasks"
    vertical
  >
    <label label="Current Savings:" className="task-title" />
    {bind(savings)}
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
      {refresh}
      {Entry}
      {PriceEntry}
    </box>
  </box>
)

export default Budget