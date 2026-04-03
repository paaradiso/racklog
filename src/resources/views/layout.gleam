import database/main/models/user/gen/user.{type User}
import gleam/option
import lustre/attribute.{action, class, content, href, method, name, rel, type_}
import lustre/element.{type Element, fragment, text, unsafe_raw_html}
import lustre/element/html.{
  a, body, div, footer, form, head, header, html, link, main, meta, nav, title,
}
import resources/views/components/components.{ButtonPrimary}

pub type Model {
  Model(user: option.Option(User))
}

pub fn view(model: Model, children: List(Element(Nil))) -> Element(Nil) {
  html([], [
    head([], [
      meta([attribute.attribute("charset", "utf-8")]),
      meta([name("viewport"), content("width=device-width, initial-scale=1")]),
      link([
        rel("icon"),
        type_("image/svg+xml"),
        href("/static/images/favicon.svg"),
      ]),
      title([], "racklog"),
      text("VITE_TAGS"),
    ]),

    body([class("antialiased")], [
      render_header(model),
      main([class("justify-center items-center w-full flex-1")], children),
    ]),
  ])
}

fn render_header(model: Model) -> Element(Nil) {
  header(
    [
      class(
        "bg-card border-border z-10 flex h-16 w-full items-center justify-center border-b shadow-md backdrop-blur-sm mb-4",
      ),
    ],
    [
      div([class("container flex items-center justify-between")], [
        nav(
          [
            attribute.attribute("aria-label", "Primary"),
            class("flex items-center gap-4"),
          ],
          [
            a([href("/"), class("text-foreground text-2xl font-bold mr-4")], [
              text("racklog"),
            ]),

            components.link(href: "/input", attributes: [], children: [
              text("Input"),
            ]),
            components.link(href: "/workouts", attributes: [], children: [
              text("Workouts"),
            ]),
            components.link(href: "/exercises", attributes: [], children: [
              text("Exercises"),
            ]),
          ],
        ),

        nav(
          [
            attribute.attribute("aria-label", "Account"),
            class("items-center gap-4 flex"),
          ],
          [
            case model.user {
              option.Some(_) ->
                form([action("/logout"), method("POST")], [
                  components.button(
                    variant: ButtonPrimary,
                    href: "",
                    attributes: [type_("submit")],
                    children: [
                      text("Log out"),
                    ],
                  ),
                ])

              option.None ->
                fragment([
                  components.link(href: "/login", attributes: [], children: [
                    text("Log In"),
                  ]),
                  components.button(
                    variant: ButtonPrimary,
                    href: "/register",
                    attributes: [],
                    children: [
                      text("Register"),
                    ],
                  ),
                ])
            },
          ],
        ),
      ]),
    ],
  )
}
