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
          element.text("Welcome back"),
        ]),
        case session.has_flash(model.session, "error") {
          True ->
            html.div(
              [
                attribute.class(
                  "p-3 bg-destructive-background-subtle border border-destructive-border text-destructive rounded",
                ),
              ],
              [element.text(session.get_flash(model.session, "error"))],
            )
          False -> element.none()
        },
        html.form(
          [
            attribute.method("post"),
            attribute.action("/login"),
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
            components.button(
              variant: ButtonPrimary,
              href: "",
              attributes: [attribute.type_("submit")],
              children: [element.text("Login")],
            ),
          ],
        ),
        html.p([attribute.class("text-center text-sm text-muted-foreground")], [
          element.text("Don't have an account?"),
          components.link(
            href: "/register",
            attributes: [attribute.class("ml-0.5")],
            children: [element.text("Register")],
          ),
        ]),
      ],
    ),
  ])
}
