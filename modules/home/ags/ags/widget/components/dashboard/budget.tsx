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
  subItems?: ItemDefinition[];
  editMode?: boolean;
  subItemsShown?: boolean;
  price?: number;
  percent?: number
}

function changedHandler() {
  changed.set(!changed.get())
}

readFileAsync(`/home/adam/.cache/astal/secrets.json`).then((secrets) => {
  let parsed = JSON.parse(secrets)
  gistID = parsed.budget_gist_id
  token = parsed.token
  if (gistID === "") {
    print("budget id not found in secrets.json")
    return
  } else if (token === "") {
    print("token not found in secrets.json")
    return
  }
  readUpdate()
}).catch(print)

function calculateTotalPrice(item: ItemDefinition): number {
  let totalPrice = item.price || 0;
  if (item.subItems) {
    const subItemsTotal = item.subItems.reduce((acc, subItem) => acc + calculateTotalPrice(subItem), 0);
    item.price = subItemsTotal; // update the price of the current item
    totalPrice = subItemsTotal;
  }
  return totalPrice;
}

function calculateNonLeavePercentages(item: ItemDefinition): number {
  if (item.subItems) {
    item.subItems.reduce((acc, subItem) => acc + calculateNonLeavePercentages(subItem), 0);
    const totalLeaves = item.subItems.length;
    const totalPaid = item.subItems.reduce((acc, subItem) => acc + (subItem.percent === 100 ? 1 : 0 || 0), 0);
    item.percent = Math.round((totalPaid / totalLeaves) * 100);
  }
  return 0
}

function findLeaves(treePosition: number[], item: ItemDefinition): number[][] {
  if (item.subItems) {
    return item.subItems.map((subitem, i) => findLeaves([...treePosition, i], subitem)).flat();
  } else {
    return [treePosition];
  }
}

function calculatePercentages(Savings: number, temp: ItemDefinition[]): void {
  let leaves = []
  for (let i = 0; i < temp.length; i++) {
    leaves.push(findLeaves([i], temp[i]))
  }
  leaves = leaves.flat()

  let savings = Savings;

  for (let i = 0; i < leaves.length; i++) {

    const target = leaves[i].reduce((acc, curr, index) => {
      if (index === 0) {
        return acc; 
      } else {
        return acc.subItems?.[curr] || acc; 
      }
    }, temp[leaves[i][0]]);

    target.percent = (savings === 0 || !target.price) ? 0 : ((savings > target.price) ? 100 : Math.round((savings / target.price) * 100));
    savings -= !target.price ? 0 : (savings < target.price ? savings : target.price)
  }
}

const listener = Variable.derive([item_list, Savings], (itemList, Savings) => {
  const temp = itemList
  for (let i = 0; i < temp.length; i++) {
    calculateTotalPrice(temp[i]);
  }
  for (let i = 0; i < temp.length; i++) {
    calculateTotalPrice(temp[i]);
  }
  calculatePercentages(Savings, temp)
  for (let i = 0; i < temp.length; i++) {
    calculateNonLeavePercentages(temp[i]);
  }
  writeUpdate()
  print(JSON.stringify(temp))
  changedHandler();
});

const Format = new Intl.NumberFormat('en-US', {
  style: 'currency',
  currency: 'USD',
});

function getTarget(treePosition: number[], handler: (target: ItemDefinition) => void) {
  let temp = item_list.get();
  const target = treePosition.slice(1).reduce((acc, curr, index) => {
    if (index === treePosition.length - 1) {
      return acc;
    } else {
      return acc.subItems?.[curr] || acc; 
    }
  }, temp[treePosition[0]]); 

  handler(target);
  item_list.set(temp); 
  changedHandler();
}

function getTargetParent(treePosition: number[], handler: (parent: ItemDefinition) => any) {
  let temp = item_list.get();
  const parent = treePosition.slice(1).reduce((acc, curr, index) => {
    if (index >= treePosition.length - 2) {
      return acc;
    } else {
      return acc.subItems?.[curr] || acc; 
    }
  }, temp[treePosition[0]]); 
  
  handler(parent)
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
    Savings.set(Math.max(0, Math.round(Savings.get()/50)*50 === Savings.get() ? (Savings.get() - direction*50) : (Math.round(Savings.get()/50)*50)));
    writeUpdate()
  };

  const onClick: Widget.ButtonProps["onClick"] = (_, e: Astal.ClickEvent) => {
    if (e.button === Gdk.BUTTON_PRIMARY) {
      savingsEdit.set(true)
    }
  };

  return savingsEdit.get() ?
    <entry
      text={`${Savings.get()}`}
      onActivate={(self) => { Savings.set(isNaN(self.get_text() as unknown as number) ? Savings.get() : Number(self.get_text())); savingsEdit.set(false); writeUpdate(); }}
      className="savings edit"
      widthChars={6}
      halign={Gtk.Align.CENTER}
      
      onRealize={(self) => { self.grab_focus() }}
    /> : <button
      className="savings"
      halign={Gtk.Align.CENTER}
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
      return acc.subItems?.[curr] || acc; 
    }
  }, item_list.get()[treePosition[0]]);

  const editWidget = () => {

    const label = new Widget.Entry({
      text: definition.label,
      width_chars: 60,
      className: "item-label edit",
      onActivate: () => getTarget(treePosition, (target) => { target.editMode = false; target.label = label.get_text() ? label.get_text() : target.label; target.price = isNaN(price.get_text() as unknown as number) ? target.price : Number(price.get_text()); writeUpdate() }),
      onRealize: (self) => { self.grab_focus() },
      halign: Gtk.Align.START
    })

    const price = new Widget.Entry({
      text: String(definition.price),
      width_chars: 9,
      className: "item-price edit",
      onActivate: () => getTarget(treePosition, (target) => { target.editMode = false; target.label = label.get_text() ? label.get_text() : target.label; target.price = isNaN(price.get_text() as unknown as number) ? target.price : Number(price.get_text()); writeUpdate() }),
      hexpand: true,
      onRealize: (self) => { self.grab_focus() },
      halign: Gtk.Align.START
    })

    return <box className="item edit">
      {label}
      {price}
    </box>
  }

  return (
  <box
    hexpand
    className={`${i % 2 === 0 ? "even-scroll" : "odd-scroll"} ${definition.percent === 100 && "filled"}`}
    css={definition.percent && definition.percent < 100 ? `background: linear-gradient(90deg, rgba(98,65,4,0.7) ${definition.percent}%, rgba(0,0,0,0) ${definition.percent + 2}%);` : ""}
  >
    <box
      vertical
      vexpand={false}
    >
      <button
        vexpand
        className={`item-up ${i === 0 ? "item-up-disabled" : ""}`}
        onClick={() => {
          if (i === 0) return
          let temp = definition
          if (treePosition.length === 1) {
            let templist = item_list.get()
            templist.splice(i, 1)
            templist.splice(i - 1, 0, temp)
            item_list.set(templist)
            changedHandler()
          } else {
            getTargetParent(treePosition, (parent) => {
              parent.subItems?.splice(i, 1)
              parent.subItems?.splice(i - 1, 0, temp)
            })
          }
          writeUpdate()
        }}
      >
        <label label="⏶" className={`item-button-label ${i === 0 ? "item-up-disabled" : ""}`} />
      </button>
      <button
        vexpand
        className={`item-down ${(treePosition.length === 1 ? i === item_list.get().length - 1 : i + 1 === parent.subItems?.length) ? "item-down-disabled" : ""}`}
        onClick={() => {
          if (treePosition.length === 1 ? i === item_list.get().length - 1 : i + 1 === parent.subItems?.length) return
          let temp = definition
          if (treePosition.length === 1) {
            let templist = item_list.get()
            templist.splice(i, 1)
            templist.splice(i + 1, 0, temp)
            item_list.set(templist)
            changedHandler()
          } else {
            getTargetParent(treePosition, (parent) => {
              parent.subItems?.splice(i, 1)
              parent.subItems?.splice(i + 1, 0, temp)
            })
          }
          writeUpdate()
        }}
      >
        <label label="⏷" className="item-button-label" />
      </button>
    </box>
    <button
      className={`item-edit ${definition.subItems?.length ? "" : "edit-rounded"}`}
      onClick={() => {
        getTarget(treePosition, (target) => {
          target.editMode = !target.editMode
        })
      }}
    >
      <label label="✎" className="item-button-label" />
    </button>
    {definition.subItems?.length && <button
      className="toggle-subitems"
      onClick={() => {
        getTarget(treePosition, (target) => {
          target.subItemsShown = !target.subItemsShown
        })
      }}
    >
      <label label={definition.subItemsShown ? "▼" : "▶"} css="font-size: 1rem;"className="item-button-label" />
    </button>}
    <box vertical>
        {definition.editMode ?
          editWidget() :
        <box>
          <label hexpand label={definition.label} wrap wrapMode={Pango.WrapMode.WORD_CHAR} halign={Gtk.Align.START} className="item-label" />
          <label hexpand label={`${Format.format(definition.price || 0)}`} wrap wrapMode={Pango.WrapMode.WORD_CHAR} halign={Gtk.Align.START} className="item-price" visible={Boolean(definition.price)} />
        </box>
      }
      {definition.subItemsShown && definition.subItems && definition.subItems.map((item, i) => createItems(item, i, [...treePosition, i]))}
    </box>
    <button
      className="subitem-add"
      onClick={() => {
        getTarget(treePosition, (target) => {
          target.subItems = target.subItems || []
          target.subItems.splice(0, 0, { label: "", editMode: true })
          target.subItemsShown = true
        })
      }}
    >
      <label label="+" className="item-button-label" />
    </button>
    <button
      className="item-delete"
      onClick={() => {
        if (treePosition.length === 1) {
          let temp = item_list.get()
          temp.splice(i, 1)
          item_list.set(temp)
          changedHandler()
        } else {
          getTargetParent(treePosition, (parent) => {
            parent.subItems?.splice(i, 1)
            if (parent.subItems?.length === 0) delete parent.subItems;
          })
        }
        writeUpdate()
      }}
      >
        <label label="✕" className="item-button-label" />
      </button>
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
  function removeDisplayProperties(item: ItemDefinition): ItemDefinition {
    return {
      label: item.label,
      subItems:
        item.subItems?.map(subitem =>
          removeDisplayProperties(subitem)
        ),
      price: item.price
    };
  }

  const out = JSON.stringify(item_list.get().map(removeDisplayProperties).concat([{ label: 'Savings', price: Savings.get() }])).replace(/{/g, '\\n{').replace(/]/g, '\\n]').replace(/"/g, "\\\"")

  item_list.get().length && execAsync(['bash', '-c', `curl -L \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/gists/${gistID} \
    -d '{"description":"Updated Gist","files":{"budget.json":{"content":"${out}"}}}'
  `]).catch(print);
}

const refresh = <button
  className="item-refresh"
  onClicked={() => {
    readUpdate()
  }}
>
  <label label="↻" className="item-button-label" />
</button>;

const Entry = new Widget.Entry({
  text: bind(input),
  hexpand: true,
  canFocus: true,
  placeholderText: "Enter item name",
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
  placeholderText: "Enter item price",
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
    className="budget"
    vertical
  >
    <label label="Current Savings:" className="savings-title" />
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