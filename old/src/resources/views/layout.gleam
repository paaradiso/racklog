import database/main/models/user/gen/user.{type User}
import gleam/option
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import resources/views/components/components.{ButtonPrimary}

pub type Model {
  Model(user: option.Option(User))
}

pub fn view(model: Model, children: List(Element(Nil))) -> Element(Nil) {
  html.html([], [
    html.head([], [
      html.meta([attribute.attribute("charset", "utf-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1"),
      ]),
      html.link([
        attribute.rel("icon"),
        attribute.type_("image/svg+xml"),
        attribute.href("/static/images/favicon.svg"),
      ]),
      html.title([], "racklog"),
      element.text("VITE_TAGS"),
    ]),

    html.body([attribute.class("antialiased")], [
      render_header(model),
      html.main(
        [attribute.class("justify-center items-center w-full flex-1")],
        children,
      ),
    ]),
  ])
}

fn render_header(model: Model) -> Element(Nil) {
  html.header(
    [
      attribute.class(
        "bg-card border-border z-10 flex h-16 w-full items-center justify-center border-b shadow-md backdrop-blur-sm mb-4",
      ),
    ],
    [
      html.div(
        [attribute.class("container flex items-center justify-between")],
        [
          html.nav(
            [
              attribute.attribute("aria-label", "Primary"),
              attribute.class("flex items-center gap-4"),
            ],
            [
              html.a(
                [
                  attribute.href("/"),
                  attribute.class("text-foreground text-2xl font-bold mr-4"),
                ],
                [
                  element.text("racklog"),
                ],
              ),

              components.link(href: "/input", attributes: [], children: [
                element.text("Input"),
              ]),
              components.link(href: "/workouts", attributes: [], children: [
                element.text("Workouts"),
              ]),
              components.link(href: "/exercises", attributes: [], children: [
                element.text("Exercises"),
              ]),
            ],
          ),

          html.nav(
            [
              attribute.attribute("aria-label", "Account"),
              attribute.class("items-center gap-4 flex"),
            ],
            [
              case model.user {
                option.Some(_) ->
                  html.form(
                    [attribute.action("/logout"), attribute.method("POST")],
                    [
                      components.button(
                        variant: ButtonPrimary,
                        href: "",
                        attributes: [attribute.type_("submit")],
                        children: [
                          element.text("Log out"),
                        ],
                      ),
                    ],
                  )

                option.None ->
                  element.fragment([
                    components.link(href: "/login", attributes: [], children: [
                      element.text("Log In"),
                    ]),
                    components.button(
                      variant: ButtonPrimary,
                      href: "/register",
                      attributes: [],
                      children: [
                        element.text("Register"),
                      ],
                    ),
                  ])
              },
            ],
          ),
        ],
      ),
    ],
  )
}
