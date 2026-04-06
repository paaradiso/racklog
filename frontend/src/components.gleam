import gleam/string

// import glimr/session/session.{type Session}
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html

pub type ButtonVariant {
  ButtonPrimary
  ButtonSecondary
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
    ButtonDanger ->
      "bg-destructive text-destructive-foreground hover:bg-destructive-background-hover"
  }

  let all_attributes = [
    attribute.class(
      "flex items-center justify-center py-2 px-4 font-medium rounded-lg cursor-pointer transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
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
  href href: String,
  attributes attributes: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  html.a(
    [
      attribute.href(href),
      attribute.class(
        "text-secondary-foreground underline underline-offset-2 hover:text-muted-foreground transition-colors",
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
  // session session: Session,
  attributes attributes: List(Attribute(msg)),
) -> Element(msg) {
  html.div([], [
    html.label(
      [
        attribute.for(id),
        attribute.class(
          "block text-sm font-medium text-secondary-foreground mb-1",
        ),
      ],
      [element.text(label)],
    ),
    html.input([
      attribute.id(id),
      attribute.name(name),
      // attribute.value(session.old(session, name)),
      attribute.class(
        "w-full px-3 py-2 border border-input-border rounded-md focus:outline-none focus:ring-2 focus:ring-ring focus:border-transparent placeholder:text-muted-foreground",
      ),
      ..attributes
    ]),
    // case session.has_error(session, name) {
  //   True ->
  //     html.small([attribute.class("mt-1 text-sm text-destructive")], [
  //       element.text(session.error(session, name)),
  //     ])
  //   False -> element.none()
  // },
  ])
}

pub fn card_root(
  attributes attributes: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  html.div(
    [
      attribute.class(
        "rounded-lg border border-border bg-card text-card-foreground shadow-sm p-6",
      ),
      ..attributes
    ],
    children,
  )
}
