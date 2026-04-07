import components.{ButtonPrimary}
import gleam/http/response
import gleam/json
import gleam/option.{None}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import rsvp

pub type Model {
  Model(email: String, password: String, error: String)
}

pub type Msg {
  UpdatedEmail(String)
  UpdatedPassword(String)
  SubmittedForm
  GotResponse(Result(response.Response(String), rsvp.Error))
}

pub fn init() -> #(Model, Effect(Msg)) {
  #(Model(email: "", password: "", error: ""), effect.none())
}

pub fn update(model model: Model, msg msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UpdatedEmail(email) -> #(Model(..model, email:), effect.none())
    UpdatedPassword(password) -> #(Model(..model, password:), effect.none())
    SubmittedForm -> {
      let fx =
        rsvp.post(
          "/api/login",
          json.object([
            #("email", json.string(model.email)),
            #("password", json.string(model.password)),
          ]),
          rsvp.expect_any_response(GotResponse),
        )
      #(model, fx)
    }
    GotResponse(Ok(resp)) -> {
      case resp.status {
        200 -> #(model, modem.push("/admin", None, None))
        401 -> #(
          Model(..model, error: "Invalid email or password."),
          effect.none(),
        )
        _ -> #(Model(..model, error: "Something went wrong."), effect.none())
      }
    }
    GotResponse(Error(_)) -> {
      #(Model(..model, error: "Something went wrong."), effect.none())
    }
  }
}

pub fn view(model: Model) -> List(Element(Msg)) {
  [
    html.div([attribute.class("flex items-center justify-center size-full")], [
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
          case model.error {
            "" -> element.none()
            msg ->
              html.div(
                [
                  attribute.class(
                    "p-2 text-sm bg-destructive-background-subtle border border-destructive-border text-destructive rounded",
                  ),
                ],
                [element.text(msg)],
              )
          },
          html.form(
            [
              attribute.class("contents"),
              event.on_submit(fn(_) { SubmittedForm })
                |> event.prevent_default,
            ],
            [
              components.form_input(
                label: "Email Address",
                id: "email",
                name: "email",
                attributes: [
                  attribute.type_("email"),
                  attribute.value(model.email),
                  event.on_input(UpdatedEmail),
                ],
              ),
              components.form_input(
                label: "Password",
                id: "password",
                name: "password",
                attributes: [
                  attribute.type_("password"),
                  attribute.value(model.password),
                  event.on_input(UpdatedPassword),
                ],
              ),
              components.button(
                variant: ButtonPrimary,
                href: "",
                attributes: [
                  attribute.type_("submit"),
                  attribute.class("btn-primary"),
                ],
                children: [element.text("Login")],
              ),
            ],
          ),
        ],
      ),
    ]),
  ]
}
