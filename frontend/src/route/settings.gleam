import components.{ButtonPrimary}
import fx
import glaze/oat/toast
import gleam/int
import gleam/json
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import racklog/user.{
  type PreferredUnit, type UserDto, AdminRole, Kg, Lb, UserRole,
}
import rsvp

pub type SecurityForm {
  SecurityForm(
    email: String,
    current_password: String,
    new_password: String,
    confirm_password: String,
    error: String,
  )
}

pub type PreferencesForm {
  PreferencesForm(preferred_unit: PreferredUnit, error: String)
}

pub type Model {
  Model(
    user: UserDto,
    security_form: SecurityForm,
    preferences_form: PreferencesForm,
  )
}

pub type Msg {
  UpdatedSecurityForm(SecurityForm)
  SubmittedSecurityForm
  SavedSecurityForm(Result(UserDto, rsvp.Error))

  UpdatedPreferencesForm(PreferencesForm)
  SubmittedPreferencesForm
  SavedPreferencesForm(Result(UserDto, rsvp.Error))
}

fn init_security_form(user: UserDto) -> SecurityForm {
  SecurityForm(
    email: user.email,
    current_password: "",
    new_password: "",
    confirm_password: "",
    error: "",
  )
}

fn init_preferences_form(user: UserDto) -> PreferencesForm {
  PreferencesForm(preferred_unit: user.preferred_unit, error: "")
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
    UpdatedSecurityForm(security_form) -> #(
      Model(..model, security_form:),
      effect.none(),
    )
    SubmittedSecurityForm -> {
      case validate_security_form(model.security_form, model.user) {
        Error(msg) -> #(
          Model(
            ..model,
            security_form: SecurityForm(..model.security_form, error: msg),
          ),
          effect.none(),
        )
        Ok(Nil) -> {
          let form = model.security_form
          let fx =
            rsvp.patch(
              "/api/users/" <> int.to_string(model.user.id),
              json.object([
                #("email", json.string(form.email)),
                #("current_password", json.string(form.current_password)),
                #("password", json.string(form.new_password)),
              ]),
              rsvp.expect_json(user.decoder(), SavedSecurityForm),
            )
          #(model, fx)
        }
      }
    }
    SavedSecurityForm(Ok(user)) -> {
      #(
        Model(..model, user:, security_form: init_security_form(user)),
        effect.batch([
          fx.toast(
            title: "Success",
            description: "Saved security settings.",
            variant: toast.Success,
          ),
        ]),
      )
    }
    SavedSecurityForm(Error(rsvp.HttpError(response)))
      if response.status == 400
    -> {
      let security_form =
        SecurityForm(..model.security_form, error: response.body)
      #(Model(..model, security_form:), effect.none())
    }
    SavedSecurityForm(Error(rsvp.HttpError(response)))
      if response.status == 401
    -> {
      let security_form =
        SecurityForm(..model.security_form, error: response.body)
      #(Model(..model, security_form:), effect.none())
    }
    SavedSecurityForm(Error(_)) -> {
      let security_form =
        SecurityForm(..model.security_form, error: "Failed to save settings.")
      #(
        Model(..model, security_form:),
        fx.toast(
          title: "Error",
          description: "Failed to save settings.",
          variant: toast.Danger,
        ),
      )
    }

    UpdatedPreferencesForm(preferences_form) -> #(
      Model(..model, preferences_form:),
      effect.none(),
    )
    SubmittedPreferencesForm -> {
      let fx =
        rsvp.patch(
          "/api/users/" <> int.to_string(model.user.id),
          json.object([
            #(
              "preferred_unit",
              json.string(user.preferred_unit_to_string(
                model.preferences_form.preferred_unit,
              )),
            ),
          ]),
          rsvp.expect_json(user.decoder(), SavedPreferencesForm),
        )
      #(model, fx)
    }
    SavedPreferencesForm(Ok(user)) -> {
      #(
        Model(..model, user:, preferences_form: init_preferences_form(user)),
        effect.batch([
          fx.toast(
            title: "Success",
            description: "Saved preferences.",
            variant: toast.Success,
          ),
        ]),
      )
    }
    SavedPreferencesForm(Error(_)) -> {
      let preferences_form =
        PreferencesForm(
          ..model.preferences_form,
          error: "Failed to save preferences.",
        )
      #(
        Model(..model, preferences_form:),
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
      components.card_root(
        [attribute.class("flex flex-col gap-2 h-min w-100")],
        [
          html.p([attribute.class("my-0 text-xl font-medium")], [
            element.text("Security"),
          ]),
          html.form(
            [
              attribute.id("security_form"),
              event.on_submit(fn(_) { SubmittedSecurityForm })
                |> event.prevent_default,
            ],
            [
              html.div([attribute.class("flex flex-col gap-2")], [
                case model.security_form.error {
                  "" -> element.none()
                  msg -> components.error_message_box(msg)
                },
                components.form_input(
                  label: "Email Address",
                  id: "email",
                  name: "email",
                  attributes: [
                    attribute.type_("email"),
                    attribute.value(model.security_form.email),
                    event.on_input(fn(v) {
                      UpdatedSecurityForm(
                        SecurityForm(..model.security_form, email: v),
                      )
                    }),
                  ],
                ),

                html.hr([attribute.class("mt-2 mb-0 w-full color-border")]),

                components.form_input(
                  label: "New Password",
                  id: "new_password",
                  name: "new_password",
                  attributes: [
                    attribute.type_("password"),
                    attribute.value(model.security_form.new_password),
                    event.on_input(fn(v) {
                      UpdatedSecurityForm(
                        SecurityForm(..model.security_form, new_password: v),
                      )
                    }),
                  ],
                ),
                components.form_input(
                  label: "Confirm Password",
                  id: "confirm_password",
                  name: "confirm_password",
                  attributes: [
                    attribute.type_("password"),
                    attribute.value(model.security_form.confirm_password),
                    event.on_input(fn(v) {
                      UpdatedSecurityForm(
                        SecurityForm(..model.security_form, confirm_password: v),
                      )
                    }),
                  ],
                ),

                html.hr([attribute.class("mt-2 mb-0 w-full color-border")]),

                case model.user.role {
                  AdminRole -> element.none()
                  UserRole ->
                    components.form_input(
                      label: "Current Password",
                      id: "current_password",
                      name: "current_password",
                      attributes: [
                        attribute.type_("password"),
                        attribute.value(model.security_form.current_password),
                        event.on_input(fn(v) {
                          UpdatedSecurityForm(
                            SecurityForm(
                              ..model.security_form,
                              current_password: v,
                            ),
                          )
                        }),
                      ],
                    )
                },
                components.button(
                  variant: ButtonPrimary,
                  href: "",
                  attributes: [
                    attribute.type_("submit"),
                    attribute.attribute("form", "security_form"),
                    attribute.class("px-6 w-min"),
                    attribute.disabled(
                      SecurityForm(..model.security_form, error: "")
                      == init_security_form(model.user),
                    ),
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
              event.on_submit(fn(_) { SubmittedPreferencesForm })
                |> event.prevent_default,
            ],
            [
              html.div([attribute.class("flex flex-col gap-2")], [
                case model.preferences_form.error {
                  "" -> element.none()
                  msg -> components.error_message_box(msg)
                },
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
                            UpdatedPreferencesForm(
                              PreferencesForm(
                                ..model.preferences_form,
                                preferred_unit: Kg,
                              ),
                            )
                          _ ->
                            UpdatedPreferencesForm(
                              PreferencesForm(
                                ..model.preferences_form,
                                preferred_unit: Lb,
                              ),
                            )
                        }
                      }),
                    ],
                    [
                      html.option(
                        [
                          attribute.selected(
                            model.preferences_form.preferred_unit == Kg,
                          ),
                        ],
                        "Kg",
                      ),
                      html.option(
                        [
                          attribute.selected(
                            model.preferences_form.preferred_unit == Lb,
                          ),
                        ],
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
                    attribute.attribute("form", "preferences_form"),
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

fn validate_security_form(
  form: SecurityForm,
  user: UserDto,
) -> Result(Nil, String) {
  case
    user.role,
    form.email != user.email,
    form.new_password != "" || form.confirm_password != "",
    form.current_password
  {
    _, False, False, _ -> Ok(Nil)
    UserRole, True, _, "" ->
      Error("Current password is required to change email.")
    UserRole, _, True, "" ->
      Error("Current password is required to change password.")
    _, _, True, _ if form.new_password == "" ->
      Error("New password is required.")
    _, _, True, _ if form.confirm_password == "" ->
      Error("Please confirm your new password.")
    _, _, True, _ if form.new_password != form.confirm_password ->
      Error("Passwords do not match.")
    _, _, _, _ -> Ok(Nil)
  }
}
