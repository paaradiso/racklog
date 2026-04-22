import formal/form.{type Form}
import gleam/dynamic/decode
import gleam/list
import gleam/string
import lucide_lustre
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import utils

pub type ButtonVariant {
  ButtonPrimary
  ButtonSecondary
  ButtonOutline
  ButtonDanger
}

fn button_classes(variant: ButtonVariant) -> List(Attribute(_)) {
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
  form form: Form(a),
  is type_: String,
  name name: String,
  label label: String,
  attributes attributes: List(Attribute(msg)),
) -> Element(msg) {
  let errors = form.field_error_messages(form, name)
  html.div([], [
    html.label(
      [
        attribute.for(name),
        attribute.class(
          "block mb-1 text-sm font-medium text-secondary-foreground",
        ),
      ],
      [element.text(label)],
    ),
    html.input([
      attribute.id(name),
      attribute.name(name),
      attribute.type_(type_),
      attribute.class(
        "py-2 px-3 w-full rounded-md border focus:border-transparent focus:ring-2 focus:outline-none border-input-border placeholder:text-muted-foreground focus:ring-ring",
      ),
      ..attributes
    ]),
    ..list.map(errors, fn(error_message) {
      html.p([attribute.class("text-sm text-destructive")], [
        html.text(error_message),
      ])
    })
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

pub fn form_root_error_message_box(form form: Form(a)) -> Element(msg) {
  case form.field_error_messages(form, utils.root_error_field) {
    [] -> element.none()
    messages -> error_message_box(message: string.join(messages, ", "))
  }
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

fn dialog_on_escape(on_close: msg) -> Attribute(msg) {
  let key_decoder =
    decode.field("key", decode.string, fn(key) {
      case key {
        "Escape" -> decode.success(on_close)
        _ -> decode.failure(on_close, "msg")
      }
    })
  event.on("keydown", key_decoder)
}

pub fn dialog_root(
  is_open is_open: Bool,
  on_close on_close: msg,
  id dialog_id: String,
  attributes attributes: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  case is_open {
    False -> element.none()
    True ->
      html.div(
        [
          dialog_on_escape(on_close),
          attribute.class(
            "flex fixed inset-0 z-50 justify-center items-center p-4 sm:p-0",
          ),
          attribute.tabindex(-1),
          attribute.autofocus(True),
        ],
        [
          html.div(
            [
              attribute.class("absolute inset-0 bg-black/40 backdrop-blur-xs"),
              attribute.aria_hidden(True),
              event.on_click(on_close),
            ],
            [],
          ),
          html.dialog(
            [
              attribute.open(True),
              attribute.id(dialog_id),
              attribute.role("dialog"),
              attribute.aria_modal(True),
              attribute.aria_labelledby(dialog_id <> "-title"),
              attribute.class(
                "flex relative z-10 flex-col w-full max-w-lg rounded-xl border shadow-lg bg-card text-card-foreground border-border",
              ),
              ..attributes
            ],
            children,
          ),
        ],
      )
  }
}

pub fn dialog_header(
  dialog_id: String,
  attributes: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  html.div(
    [
      attribute.class("flex items-center py-4 px-6 border-b border-border"),
      ..attributes
    ],
    [
      html.h2(
        [
          attribute.id(dialog_id <> "-title"),
          // m-0 to remove oat class, remove later
          attribute.class("m-0 text-xl font-medium tracking-tight"),
        ],
        children,
      ),
    ],
  )
}

pub fn dialog_body(
  attributes: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  html.div(
    [attribute.class("overflow-y-auto flex-1 py-4 px-6"), ..attributes],
    children,
  )
}

pub fn dialog_footer(
  attributes: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  html.div(
    [
      attribute.class(
        "flex gap-2 justify-end items-center py-4 px-6 border-t border-border bg-muted/30",
      ),
      ..attributes
    ],
    children,
  )
}
