import gleam/list
import lucide_lustre
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html

pub type ButtonVariant {
  ButtonPrimary
  ButtonSecondary
  ButtonOutline
  ButtonDanger
}

pub fn button_classes(variant: ButtonVariant) -> List(Attribute(_)) {
  let variant_styles = case variant {
    ButtonPrimary -> "bg-foreground hover:bg-foreground/90 text-background"
    ButtonSecondary ->
      "bg-secondary text-secondary-foreground hover:bg-secondary-hover"
    ButtonOutline ->
      "bg-transparent border border-button-outline-border hover:bg-foreground/10"
    ButtonDanger ->
      "bg-destructive text-destructive-foreground hover:bg-destructive-background-hover"
  }

  [
    attribute.class(
      "flex gap-2 justify-center items-center py-1.5 px-3 font-medium rounded-lg transition-colors cursor-pointer focus:ring-2 focus:ring-offset-2 focus:outline-none disabled:pointer-events-none focus:ring-ring",
    ),
    attribute.class(variant_styles),
  ]
}

pub fn button(
  variant variant: ButtonVariant,
  href href: String,
  attributes attributes: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  let all_attributes = [attributes, button_classes(variant)] |> list.flatten

  case href {
    "" -> html.button(all_attributes, children)
    _ -> html.a([attribute.href(href), ..all_attributes], children)
  }
}

pub fn link(
  attributes attributes: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  html.a(
    [
      attribute.class(
        "underline transition-colors text-secondary-foreground underline-offset-2 hover:text-muted-foreground",
      ),
      ..attributes
    ],
    children,
  )
}

pub fn form_input(
  label label: String,
  id id: String,
  name name: String,
  attributes attributes: List(Attribute(msg)),
) -> Element(msg) {
  html.div([], [
    html.label(
      [
        attribute.for(id),
        attribute.class(
          "block mb-1 text-sm font-medium text-secondary-foreground",
        ),
      ],
      [element.text(label)],
    ),
    html.input([
      attribute.id(id),
      attribute.name(name),
      attribute.class(
        "py-2 px-3 w-full rounded-md border focus:border-transparent focus:ring-2 focus:outline-none border-input-border placeholder:text-muted-foreground focus:ring-ring",
      ),
      ..attributes
    ]),
  ])
}

pub fn card_root(
  attributes attributes: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  html.div(
    [
      attribute.class(
        "p-6 rounded-lg border shadow-sm border-border bg-card text-card-foreground",
      ),
      ..attributes
    ],
    children,
  )
}

pub fn error_message_box(message message: String) -> Element(msg) {
  html.div(
    [
      attribute.class(
        "flex gap-2 items-center p-2 text-sm rounded border bg-destructive-background-subtle border-destructive-border text-destructive",
      ),
    ],
    [
      lucide_lustre.triangle_alert([attribute.class("size-4")]),
      element.text(message),
    ],
  )
}

pub fn dropdown(
  trigger trigger: List(Element(msg)),
  items items: List(Element(msg)),
) -> Element(msg) {
  html.div([attribute.class("relative group")], [
    button(
      variant: ButtonOutline,
      href: "",
      attributes: [
        attribute.attribute(
          "onmousedown",
          "if(document.activeElement === this) { event.preventDefault(); this.blur(); }",
        ),
      ],
      children: trigger,
    ),
    html.div(
      [
        attribute.class(
          "flex hidden absolute right-0 top-full z-50 flex-col mt-1 rounded-md border shadow-md min-w-48 bg-card border-border group-focus-within:flex",
        ),
      ],
      items,
    ),
  ])
}

pub fn dropdown_item(
  attributes attributes: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  html.button(
    [
      attribute.type_("button"),
      // TODO: fix classes when i remove glaze_oat
      // override glaze_oat default button styling
      attribute.class(
        "p-0 m-0 w-full font-normal text-left bg-transparent border-none shadow-none appearance-none cursor-pointer focus:outline-none",
      ),
      attribute.attribute("onclick", "document.activeElement.blur()"),
      ..attributes
    ],
    [
      html.div(
        [
          attribute.class(
            "flex gap-2 items-center py-2 px-4 w-full text-sm hover:bg-secondary/50",
          ),
        ],
        children,
      ),
    ],
  )
}
