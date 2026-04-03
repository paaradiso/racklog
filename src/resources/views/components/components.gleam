import gleam/string
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
      "flex items-center justify-center py-2.5 px-4 font-medium rounded-lg cursor-pointer transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
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
