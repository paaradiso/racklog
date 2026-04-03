import gleam/string
import lustre/attribute.{type Attribute, attribute, class, href as href_attr}
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
  attributes attrs: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  let base_classes =
    "flex items-center justify-center py-2.5 px-4 font-medium rounded-lg cursor-pointer transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"

  let variant_styles = case variant {
    ButtonPrimary -> "bg-foreground hover:bg-foreground/90 text-background"
    ButtonSecondary ->
      "bg-secondary text-secondary-foreground hover:bg-secondary-hover"
    ButtonDanger ->
      "bg-destructive text-destructive-foreground hover:bg-destructive-background-hover"
  }

  let all_attributes = [
    class(
      "flex items-center justify-center py-2.5 px-4 font-medium rounded-lg cursor-pointer transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
    ),
    class(variant_styles),
    ..attrs
  ]

  case href {
    "" -> html.button(all_attributes, children)
    _ -> html.a([href_attr(href), ..all_attributes], children)
  }
}

pub fn link(
  href href: String,
  attributes attrs: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  html.a(
    [
      href_attr(href),
      class(
        "text-secondary-foreground underline underline-offset-2 hover:text-muted-foreground transition-colors",
      ),
      ..attrs
    ],
    children,
  )
}
