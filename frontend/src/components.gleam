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

pub fn button(
  variant variant: ButtonVariant,
  href href: String,
  attributes attributes: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  let variant_styles = case variant {
    ButtonPrimary -> "bg-foreground hover:bg-foreground/90 text-background"
    ButtonSecondary ->
      "bg-secondary text-secondary-foreground hover:bg-secondary-hover"
    ButtonOutline ->
      "bg-transparent border border-button-outline-border hover:bg-foreground/10"
    ButtonDanger ->
      "bg-destructive text-destructive-foreground hover:bg-destructive-background-hover"
  }

  let all_attributes = [
    attribute.class(
      "flex justify-center items-center py-2 px-4 font-medium rounded-lg transition-colors cursor-pointer focus:ring-2 focus:ring-offset-2 focus:outline-none focus:ring-ring",
    ),
    attribute.class(variant_styles),
    ..attributes
  ]

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
