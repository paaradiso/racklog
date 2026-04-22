import components.{ButtonPrimary}
import formal/form.{type Form}
import gleam/http/response.{type Response, Response}
import gleam/json
import gleam/option.{None}
import gleam/string
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import rsvp.{HttpError, NetworkError}
import utils

pub type LoginData {
  LoginData(username: String, password: String)
}

pub type Model {
  Model(form: Form(LoginData), is_loading: Bool)
}

pub type Msg {
  SubmittedForm(Result(LoginData, Form(LoginData)))
  GotLoginResponse(Result(Response(String), rsvp.Error))
}

fn init_form() -> Form(LoginData) {
  form.new({
    use username <- form.field("username", form.parse_string)
    use password <- form.field("password", form.parse_string)
    form.success(LoginData(username:, password:))
  })
}

pub fn init() -> #(Model, Effect(Msg)) {
  #(Model(form: init_form(), is_loading: False), effect.none())
}

pub fn update(model model: Model, msg msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SubmittedForm(Error(form)) -> #(
      Model(form:, is_loading: False),
      effect.none(),
    )
    SubmittedForm(Ok(data)) -> {
      let fx =
        rsvp.post(
          "/api/login",
          json.object([
            #("username", json.string(data.username)),
            #("password", json.string(data.password)),
          ]),
          rsvp.expect_ok_response(GotLoginResponse),
        )
      #(Model(form: init_form(), is_loading: True), fx)
    }
    GotLoginResponse(Ok(_)) -> {
      #(model, modem.push("/", None, None))
    }
    GotLoginResponse(Error(HttpError(Response(status: 401, ..)))) -> {
      #(
        Model(
          form: utils.add_form_root_error(
            model.form,
            "Invalid username or password.",
          ),
          is_loading: False,
        ),
        effect.none(),
      )
    }
    GotLoginResponse(Error(NetworkError)) -> {
      #(
        Model(
          form: utils.add_form_root_error(
            model.form,
            "Network error. Please check your internet connection.",
          ),
          is_loading: False,
        ),
        effect.none(),
      )
    }
    GotLoginResponse(Error(_)) -> {
      #(
        Model(
          form: utils.add_form_root_error(model.form, "Something went wrong."),
          is_loading: False,
        ),
        effect.none(),
      )
    }
  }
}

pub fn view(model: Model) -> List(Element(Msg)) {
  [
    html.div([attribute.class("flex justify-center items-center size-full")], [
      html.div(
        [
          attribute.class(
            "flex flex-col gap-4 p-8 rounded-lg border shadow-md w-lg border-border bg-card",
          ),
        ],
        [
          html.h1([attribute.class("mb-0 text-2xl font-medium text-center")], [
            element.text("Welcome back"),
          ]),
          html.form(
            [
              attribute.class("contents"),
              event.on_submit(fn(values) {
                model.form
                |> form.add_values(values)
                |> form.run
                |> SubmittedForm
              })
                |> event.prevent_default,
            ],
            [
              case
                form.field_error_messages(model.form, utils.root_error_field)
              {
                [] -> element.none()
                messages ->
                  components.error_message_box(
                    messages |> string.join(with: ", "),
                  )
              },
              components.formal_input(
                form: model.form,
                is: "text",
                name: "username",
                label: "Username",
                attributes: [],
              ),
              components.formal_input(
                form: model.form,
                is: "password",
                name: "password",
                label: "Password",
                attributes: [],
              ),
              components.button(
                variant: ButtonPrimary,
                href: "",
                attributes: [attribute.disabled(model.is_loading)],
                children: [element.text("Log in")],
              ),
            ],
          ),
        ],
      ),
    ]),
  ]
}
