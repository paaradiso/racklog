import gleam/option
import glimr/session/session.{type Session}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import resources/views/components/components.{ButtonPrimary}

pub type Model {
  Model(session: Session)
}

pub fn view(model: Model) -> Element(Nil) {
  html.div([attribute.class("flex items-center justify-center min-h-screen")], [
    html.div(
      [
        attribute.class(
          "flex flex-col gap-4 w-lg p-8 border border-border bg-card rounded-lg shadow-md",
        ),
      ],
      [
        html.h1([attribute.class("text-2xl font-semibold text-center")], [
          element.text("Register now"),
        ]),
        case session.has_flash(model.session, "error") {
          True ->
            html.div(
              [
                attribute.class(
                  "p-3 bg-destructive-background-subtle border-destructive-border text-destructive rounded",
                ),
              ],
              [element.text(session.get_flash(model.session, "error"))],
            )
          False -> element.none()
        },
        html.form(
          [
            attribute.method("post"),
            attribute.action("/register"),
            attribute.class("contents"),
          ],
          [
            components.form_input(
              label: "Email Address",
              id: "email",
              name: "email",
              session: model.session,
              attributes: [attribute.type_("email")],
            ),
            components.form_input(
              label: "Password",
              id: "password",
              name: "password",
              session: model.session,
              attributes: [attribute.type_("password")],
            ),
            components.form_input(
              label: "Confirm Password",
              id: "password_confirmation",
              name: "password_confirmation",
              session: model.session,
              attributes: [attribute.type_("password")],
            ),
            components.button(
              variant: ButtonPrimary,
              href: "",
              attributes: [attribute.type_("submit")],
              children: [element.text("Register")],
            ),
          ],
        ),
        html.p([attribute.class("text-center text-sm text-muted-foreground")], [
          element.text("Already have an account?"),
          components.link(
            href: "/login",
            attributes: [attribute.class("ml-0.5")],
            children: [element.text("Login")],
          ),
        ]),
      ],
    ),
  ])
}
