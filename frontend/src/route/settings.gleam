import components.{ButtonPrimary}
import formal/form.{type Form}
import fx
import glaze/oat/toast
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/string
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import racklog/error
import racklog/user.{
  type PreferredUnit, type UserDto, AdminRole, Kg, Lb, UserRole,
}
import rsvp
import utils

pub type SecurityData {
  SecurityData(
    email: String,
    current_password: String,
    password: String,
    confirm_password: String,
  )
}

pub type Preferences {
  Preferences(preferred_unit: PreferredUnit)
}

pub type Model {
  Model(
    user: UserDto,
    security_form: Form(SecurityData),
    preferences_form: Form(Preferences),
  )
}

pub type Msg {
  SubmittedSecurityForm(Result(SecurityData, Form(SecurityData)))
  SavedSecurityForm(Result(UserDto, rsvp.Error))
  SubmittedPreferencesForm(Result(Preferences, Form(Preferences)))
  SavedPreferencesForm(Result(UserDto, rsvp.Error))
}

fn init_security_form(user: UserDto) -> Form(SecurityData) {
  form.new({
    use email <- form.field(
      user.EmailField |> user.form_field_to_string,
      form.parse_string,
    )
    use password <- form.field(
      user.PasswordField |> user.form_field_to_string,
      form.parse_optional(
        form.parse_string
        |> form.check_string_length_more_than(user.minimum_password_length - 1),
      )
        |> form.map(option.unwrap(_, "")),
    )
    use confirm_password <- form.field(
      user.ConfirmPasswordField |> user.form_field_to_string,
      form.parse_optional(
        form.parse_string
        |> form.check_confirms(password),
      )
        |> form.map(option.unwrap(_, "")),
    )
    use current_password <- form.field(
      user.CurrentPasswordField |> user.form_field_to_string,
      form.parse_string,
    )
    form.success(SecurityData(
      email:,
      password:,
      confirm_password:,
      current_password:,
    ))
  })
  |> form.add_string(user.EmailField |> user.form_field_to_string, user.email)
}

fn init_preferences_form(user: UserDto) -> Form(Preferences) {
  form.new({
    use preferred_unit <- form.field(
      user.PreferredUnitField |> user.form_field_to_string,
      form.parse(fn(values) {
        let kg_string = user.preferred_unit_to_string(Kg)
        let lb_string = user.preferred_unit_to_string(Lb)
        case values {
          [str, ..] if str == kg_string -> Ok(Kg)
          [str, ..] if str == lb_string -> Ok(Lb)
          _ -> Error(#(Kg, "Invalid unit selected."))
        }
      }),
    )
    form.success(Preferences(preferred_unit:))
  })
  |> form.add_string(
    user.PreferredUnitField |> user.form_field_to_string,
    string.lowercase(user.preferred_unit_to_string(user.preferred_unit)),
  )
}

pub fn init(user: UserDto) -> #(Model, Effect(Msg)) {
  #(
    Model(
      user:,
      security_form: init_security_form(user),
      preferences_form: init_preferences_form(user),
    ),
    effect.none(),
  )
}

pub fn update(model model: Model, msg msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SubmittedSecurityForm(Error(security_form)) -> #(
      Model(..model, security_form:),
      effect.none(),
    )
    SubmittedSecurityForm(Ok(data)) -> {
      case validate_security_data(data, model.user) {
        Error(msg) -> #(
          Model(
            ..model,
            security_form: utils.add_form_root_error(model.security_form, msg),
          ),
          effect.none(),
        )
        Ok(Nil) -> {
          let fx =
            rsvp.patch(
              "/api/users/" <> int.to_string(model.user.id),
              json.object([
                #("email", json.string(data.email)),
                #("current_password", json.string(data.current_password)),
                #("password", json.string(data.password)),
              ]),
              rsvp.expect_json(user.decoder(), SavedSecurityForm),
            )
          #(Model(..model, security_form: init_security_form(model.user)), fx)
        }
      }
    }
    SavedSecurityForm(Ok(user)) -> #(
      Model(..model, user:, security_form: init_security_form(user)),
      fx.toast(
        title: "Success",
        description: "Saved security settings.",
        variant: toast.Success,
      ),
    )
    SavedSecurityForm(Error(rsvp.HttpError(response))) -> {
      case json.parse(response.body, error.decoder()) {
        Ok(error.ValidationError(field:, message:))
        | Ok(error.ConflictError(field:, message:)) -> {
          let security_form =
            utils.add_form_custom_error(model.security_form, field, message)
          #(Model(..model, security_form:), effect.none())
        }
        Ok(err) -> #(
          model,
          fx.toast(
            title: "Error",
            description: error.to_string(err),
            variant: toast.Danger,
          ),
        )
        Error(_) -> #(
          model,
          fx.toast(
            title: "Error",
            description: "Failed to save settings.",
            variant: toast.Danger,
          ),
        )
      }
    }
    SavedSecurityForm(Error(_)) -> #(
      model,
      fx.toast(
        title: "Error",
        description: "Failed to save settings.",
        variant: toast.Danger,
      ),
    )
    SubmittedPreferencesForm(Ok(preferences)) -> {
      let fx =
        rsvp.patch(
          "/api/users/" <> int.to_string(model.user.id),
          json.object([
            #(
              "preferred_unit",
              json.string(user.preferred_unit_to_string(
                preferences.preferred_unit,
              )),
            ),
          ]),
          rsvp.expect_json(user.decoder(), SavedPreferencesForm),
        )
      #(model, fx)
    }

    SubmittedPreferencesForm(Error(preferences_form)) -> #(
      Model(..model, preferences_form:),
      effect.none(),
    )

    SavedPreferencesForm(Ok(user)) -> #(
      Model(..model, user:, preferences_form: init_preferences_form(user)),
      fx.toast(
        title: "Success",
        description: "Saved preferences.",
        variant: toast.Success,
      ),
    )

    SavedPreferencesForm(Error(_)) -> #(
      model,
      fx.toast(
        title: "Error",
        description: "Failed to save preferences.",
        variant: toast.Danger,
      ),
    )
  }
}

pub fn view(model: Model) -> List(Element(Msg)) {
  [
    html.div([attribute.class("flex justify-center items-center size-full")], [
      components.card_root(
        [attribute.class("flex flex-col gap-2 h-min w-100")],
        [
          html.p([attribute.class("my-0 text-xl font-medium")], [
            element.text("Security"),
          ]),
          html.form(
            [
              attribute.id("security_form"),
              event.on_submit(fn(values) {
                model.security_form
                |> form.add_values(values)
                |> form.run
                |> SubmittedSecurityForm
              })
                |> event.prevent_default,
            ],
            [
              html.div([attribute.class("flex flex-col gap-2")], [
                components.form_root_error_message_box(model.security_form),
                components.form_input(
                  form: model.security_form,
                  is: "email",
                  name: user.form_field_to_string(user.EmailField),
                  label: "Email Address",
                  attributes: [],
                ),

                html.hr([attribute.class("mt-2 mb-0 w-full color-border")]),

                components.form_input(
                  form: model.security_form,
                  is: "password",
                  name: user.form_field_to_string(user.PasswordField),
                  label: "New Password",
                  attributes: [],
                ),
                components.form_input(
                  form: model.security_form,
                  is: "password",
                  name: user.form_field_to_string(user.ConfirmPasswordField),
                  label: "Confirm Password",
                  attributes: [],
                ),

                case model.user.role {
                  AdminRole -> element.none()
                  UserRole ->
                    element.fragment([
                      html.hr([attribute.class("mt-2 mb-0 w-full color-border")]),

                      components.form_input(
                        form: model.security_form,
                        is: "password",
                        name: user.form_field_to_string(
                          user.CurrentPasswordField,
                        ),
                        label: "Current Password",
                        attributes: [],
                      ),
                    ])
                },
                components.button(
                  variant: ButtonPrimary,
                  href: "",
                  attributes: [
                    attribute.type_("submit"),
                    attribute.attribute("form", "security_form"),
                    attribute.class("px-6 w-min"),
                  ],
                  children: [element.text("Save")],
                ),
              ]),
            ],
          ),

          html.hr([attribute.class("mt-2 mb-0 w-full color-border")]),

          html.p([attribute.class("my-0 text-xl font-medium")], [
            element.text("Preferences"),
          ]),

          html.form(
            [
              attribute.id("preferences_form"),
              event.on_submit(fn(values) {
                model.preferences_form
                |> form.add_values(values)
                |> form.run
                |> SubmittedPreferencesForm
              }),
            ],
            [
              html.div([attribute.class("flex flex-col gap-2")], [
                html.div([], [
                  html.label(
                    [
                      attribute.for("preferred_unit"),
                      attribute.class(
                        "block mb-1 text-sm font-medium text-secondary-foreground",
                      ),
                    ],
                    [element.text("Preferred Unit")],
                  ),
                  html.select(
                    [
                      attribute.name("preferred_unit"),
                      attribute.id("preferred_unit"),
                      attribute.property(
                        "value",
                        json.string(form.field_value(
                          model.preferences_form,
                          "preferred_unit",
                        )),
                      ),
                      attribute.class(
                        "py-2 px-3 w-full rounded-md border focus:border-transparent focus:ring-2 focus:outline-none border-input-border placeholder:text-muted-foreground focus:ring-ring",
                      ),
                    ],
                    [
                      html.option([attribute.value("kg")], "Kg"),
                      html.option([attribute.value("lb")], "Lb"),
                    ],
                  ),
                  ..list.map(
                    form.field_error_messages(
                      model.preferences_form,
                      "preferred_unit",
                    ),
                    fn(msg) {
                      html.p([attribute.class("text-sm text-destructive")], [
                        html.text(msg),
                      ])
                    },
                  )
                ]),
                components.button(
                  variant: ButtonPrimary,
                  href: "",
                  attributes: [
                    attribute.type_("submit"),
                    attribute.form("preferences_form"),
                    attribute.class("px-6 w-min"),
                  ],
                  children: [element.text("Save")],
                ),
              ]),
            ],
          ),
        ],
      ),
    ]),
  ]
}

fn validate_security_data(
  data: SecurityData,
  user: UserDto,
) -> Result(Nil, String) {
  case
    user.role,
    data.email != user.email,
    data.password != "" || data.confirm_password != "",
    data.current_password
  {
    _, False, False, _ -> Ok(Nil)
    _, _, True, _ if data.password == "" -> Error("New password is required.")
    _, _, True, _ if data.confirm_password == "" ->
      Error("Please confirm your new password.")
    _, _, _, _ -> Ok(Nil)
  }
}
