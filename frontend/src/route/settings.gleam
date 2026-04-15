import components.{ButtonPrimary}
import fx
import glaze/oat/toast
import gleam/http/response.{type Response}
import gleam/int
import gleam/json
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import racklog/user.{type PreferredUnit, type UserDto, Kg, Lb}
import rsvp

pub type Form {
  Form(
    preferred_unit: PreferredUnit,
    password: String,
    confirm_password: String,
    error: String,
  )
}

pub type Model {
  Model(user: UserDto, form: Form)
}

pub type Msg {
  UpdatedForm(Form)
  SubmittedForm
  SavedSettings(Result(UserDto, rsvp.Error))
}

fn init_form(user: UserDto) -> Form {
  Form(
    preferred_unit: user.preferred_unit,
    password: "",
    confirm_password: "",
    error: "",
  )
}

pub fn init(user: UserDto) -> #(Model, Effect(Msg)) {
  #(Model(user:, form: init_form(user)), effect.none())
}

pub fn update(model model: Model, msg msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UpdatedForm(form) -> #(Model(..model, form:), effect.none())
    SubmittedForm -> {
      let form = model.form
      let passwords_match = form.password == form.confirm_password
      let password_validation = user.validate_password(form.password)
      case form.password, form.confirm_password {
        "", "" -> {
          let fx =
            rsvp.patch(
              "/api/users/" <> int.to_string(model.user.id),
              json.object([
                #(
                  "preferred_unit",
                  json.string(user.preferred_unit_to_string(form.preferred_unit)),
                ),
              ]),
              rsvp.expect_json(user.decoder(), SavedSettings),
            )
          #(model, fx)
        }
        _, _ ->
          case passwords_match, password_validation {
            False, _ -> #(
              Model(
                ..model,
                form: Form(..form, error: "Passwords do not match."),
              ),
              effect.none(),
            )
            True, Error(user.PasswordTooShort) -> #(
              Model(
                ..model,
                form: Form(
                  ..form,
                  error: "Your password should be at least 8 characters long.",
                ),
              ),
              effect.none(),
            )

            True, Error(user.PasswordTooWeak) -> #(
              Model(
                ..model,
                form: Form(..form, error: "Your password is too weak."),
              ),
              effect.none(),
            )
            True, Ok(Nil) -> {
              let payload_fields = [
                #(
                  "preferred_unit",
                  json.string(user.preferred_unit_to_string(form.preferred_unit)),
                ),
                #("password", json.string(form.password)),
              ]
              let fx =
                rsvp.patch(
                  "/api/users/" <> int.to_string(model.user.id),
                  json.object(payload_fields),
                  rsvp.expect_json(user.decoder(), SavedSettings),
                )
              #(model, fx)
            }
          }
      }
    }
    SavedSettings(Ok(user)) -> {
      #(
        Model(user:, form: init_form(user)),
        effect.batch([
          fx.toast(
            title: "Success",
            description: "Saved settings.",
            variant: toast.Success,
          ),
        ]),
      )
    }
    SavedSettings(Error(_)) -> {
      let form = Form(..model.form, error: "Failed to save settings.")
      #(
        Model(..model, form: form),
        fx.toast(
          title: "Error",
          description: "Failed to save settings.",
          variant: toast.Danger,
        ),
      )
    }
  }
}

pub fn view(model: Model) -> List(Element(Msg)) {
  [
    html.div([attribute.class("flex justify-center items-center size-full")], [
      components.card_root([attribute.class("h-min w-100")], [
        html.form(
          [
            attribute.id("form"),
            attribute.class(""),
            event.on_submit(fn(_) { SubmittedForm })
              |> event.prevent_default,
          ],
          [
            html.div([attribute.class("flex flex-col gap-2")], [
              case model.form.error {
                "" -> element.none()
                msg -> components.error_message_box(msg)
              },
              components.form_input(
                label: "Password",
                id: "password",
                name: "password",
                attributes: [
                  attribute.type_("password"),
                  attribute.value(model.form.password),
                  event.on_input(fn(v) {
                    UpdatedForm(Form(..model.form, password: v))
                  }),
                ],
              ),
              components.form_input(
                label: "Confirm Password",
                id: "confirm_password",
                name: "confirm_password",
                attributes: [
                  attribute.type_("password"),
                  attribute.value(model.form.confirm_password),
                  event.on_input(fn(v) {
                    UpdatedForm(Form(..model.form, confirm_password: v))
                  }),
                ],
              ),
              html.div([], [
                html.label(
                  [
                    attribute.for("edit_user_select"),
                    attribute.class(
                      "block mb-1 text-sm font-medium text-secondary-foreground",
                    ),
                  ],
                  [element.text("Preferred Unit")],
                ),
                html.select(
                  [
                    attribute.id("preferred_unit_select"),
                    attribute.class(
                      "py-2 px-3 w-full rounded-md border focus:border-transparent focus:ring-2 focus:outline-none border-input-border placeholder:text-muted-foreground focus:ring-ring",
                    ),
                    event.on_change(fn(value) {
                      case value {
                        "Kg" ->
                          UpdatedForm(Form(..model.form, preferred_unit: Kg))
                        _ -> UpdatedForm(Form(..model.form, preferred_unit: Lb))
                      }
                    }),
                  ],
                  [
                    html.option(
                      [attribute.selected(model.form.preferred_unit == Kg)],
                      "Kg",
                    ),
                    html.option(
                      [attribute.selected(model.form.preferred_unit == Lb)],
                      "Lb",
                    ),
                  ],
                ),
              ]),

              components.button(
                variant: ButtonPrimary,
                href: "",
                attributes: [
                  attribute.type_("submit"),
                  attribute.attribute("form", "form"),
                ],
                children: [element.text("Submit")],
              ),
            ]),
          ],
        ),
      ]),
    ]),
  ]
}
