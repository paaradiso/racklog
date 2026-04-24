import components.{ButtonDanger, ButtonOutline, ButtonPrimary, ButtonSecondary}
import formal/form.{type Form}
import fx
import glaze/oat/toast
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import lucide_lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import racklog/error
import racklog/user.{type AppUserRole, type UserDto, AdminRole, UserRole}
import rsvp
import utils

pub type Tab {
  GeneralTab
  UsersTab
}

pub fn tab_name_to_tab(tab_name: String) -> Option(Tab) {
  case tab_name {
    "users" -> Some(UsersTab)
    "general" -> Some(GeneralTab)
    _ -> None
  }
}

pub type Dialog {
  AddUserDialog
  EditUserDialog
  ConfirmDialog(message: String, on_confirm: Msg)
}

pub type AddUserData {
  AddUserData(
    username: String,
    email: String,
    password: String,
    confirm_password: String,
    role: AppUserRole,
  )
}

pub type EditUserData {
  EditUserData(
    username: String,
    email: String,
    password: String,
    confirm_password: String,
    role: AppUserRole,
  )
}

fn init_add_user_form() -> Form(AddUserData) {
  form.new({
    use username <- form.field(
      user.UsernameField |> user.form_field_to_string,
      form.parse_string,
    )
    use email <- form.field(
      user.EmailField |> user.form_field_to_string,
      form.parse_string,
    )
    use password <- form.field(
      user.PasswordField |> user.form_field_to_string,
      form.parse_string
        |> form.check_string_length_more_than(user.minimum_password_length - 1),
    )
    use confirm_password <- form.field(
      user.ConfirmPasswordField |> user.form_field_to_string,
      form.parse_string |> form.check_confirms(password),
    )
    use role <- form.field(
      user.RoleField |> user.form_field_to_string,
      form.parse(fn(values) {
        let user_role_string = user.role_to_string(UserRole)
        let admin_role_string = user.role_to_string(AdminRole)
        case values {
          [str, ..] if str == user_role_string -> Ok(UserRole)
          [str, ..] if str == admin_role_string -> Ok(AdminRole)
          _ -> Error(#(UserRole, "Invalid role selected."))
        }
      }),
    )

    form.success(AddUserData(
      username:,
      email:,
      password:,
      confirm_password:,
      role:,
    ))
  })
  |> form.add_string(
    user.RoleField |> user.form_field_to_string,
    user.role_to_string(UserRole),
  )
}

fn init_edit_user_form(user: Option(UserDto)) -> Form(EditUserData) {
  form.new({
    use username <- form.field(
      user.UsernameField |> user.form_field_to_string,
      form.parse_string,
    )
    use email <- form.field(
      user.EmailField |> user.form_field_to_string,
      form.parse_string,
    )
    // TODO: fix parsing, if you input something, submit with an error, then clear, it still thinks there's a value
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
    use role <- form.field(
      user.RoleField |> user.form_field_to_string,
      form.parse(fn(values) {
        let user_role_string = user.role_to_string(UserRole)
        let admin_role_string = user.role_to_string(AdminRole)
        case values {
          [str, ..] if str == user_role_string -> Ok(UserRole)
          [str, ..] if str == admin_role_string -> Ok(AdminRole)
          _ -> Error(#(UserRole, "Invalid role selected."))
        }
      }),
    )

    form.success(EditUserData(
      username:,
      email:,
      password:,
      confirm_password:,
      role:,
    ))
  })
  |> form.add_string(
    user.RoleField |> user.form_field_to_string,
    user.role_to_string(case user {
      Some(u) -> u.role
      None -> user.UserRole
    }),
  )
  |> form.add_string(
    user.UsernameField |> user.form_field_to_string,
    case user {
      Some(u) -> u.username
      None -> ""
    },
  )
  |> form.add_string(user.EmailField |> user.form_field_to_string, case user {
    Some(u) -> u.email
    None -> ""
  })
}

pub type Model {
  Model(
    active_tab: Tab,
    users: List(UserDto),
    add_user_form: Form(AddUserData),
    edit_user_form: Form(EditUserData),
    editing_user: Option(UserDto),
    active_dialog: Option(Dialog),
  )
}

pub type Msg {
  ClickedTab(Tab)
  FetchedUsers(Result(List(UserDto), rsvp.Error))
  OpenedAddUserDialog
  OpenedEditUserDialog(UserDto)
  OpenedConfirmDialog(message: String, on_confirm: Msg)
  ClosedDialog
  ConfirmedDialog
  DeleteUserRequestSent(Int)
  DeletedUser(Result(Int, rsvp.Error))
  SubmittedAddUserForm(Result(AddUserData, Form(AddUserData)))
  SavedAddUserForm(Result(UserDto, rsvp.Error))
  SubmittedEditUserForm(Result(EditUserData, Form(EditUserData)))
  SavedEditUserForm(Result(UserDto, rsvp.Error))
}

pub fn init() -> #(Model, Effect(Msg)) {
  init_with_tab(GeneralTab)
}

pub fn init_with_tab(tab: Tab) -> #(Model, Effect(Msg)) {
  let model =
    Model(
      active_tab: tab,
      users: [],
      add_user_form: init_add_user_form(),
      edit_user_form: init_edit_user_form(None),
      editing_user: None,
      active_dialog: None,
    )

  let fx = case tab {
    UsersTab ->
      rsvp.get(
        "/api/users",
        rsvp.expect_json(user.list_decoder(), FetchedUsers),
      )
    GeneralTab -> effect.none()
  }

  #(model, fx)
}

pub fn update(model model: Model, msg msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ClickedTab(target_tab) -> {
      let path = case target_tab {
        GeneralTab -> "/admin/general"
        UsersTab -> "/admin/users"
      }
      let next_model = Model(..model, active_tab: target_tab)
      let fx = case target_tab {
        UsersTab ->
          effect.batch([
            modem.push(path, None, None),
            rsvp.get(
              "/api/users",
              rsvp.expect_json(user.list_decoder(), FetchedUsers),
            ),
          ])
        _ -> modem.push(path, None, None)
      }
      #(next_model, fx)
    }
    FetchedUsers(Ok(users)) -> #(Model(..model, users:), effect.none())
    FetchedUsers(Error(_)) -> #(
      model,
      fx.toast(
        title: "Error",
        description: "Failed to fetch users.",
        variant: toast.Danger,
      ),
    )
    OpenedAddUserDialog -> #(
      Model(
        ..model,
        add_user_form: init_add_user_form(),
        active_dialog: Some(AddUserDialog),
      ),
      effect.none(),
    )
    OpenedEditUserDialog(user) -> #(
      Model(
        ..model,
        edit_user_form: init_edit_user_form(Some(user)),
        editing_user: Some(user),
        active_dialog: Some(EditUserDialog),
      ),
      effect.none(),
    )
    OpenedConfirmDialog(message: message, on_confirm: on_confirm_msg) -> #(
      Model(
        ..model,
        active_dialog: Some(ConfirmDialog(message, on_confirm_msg)),
      ),
      effect.none(),
    )
    ClosedDialog -> #(Model(..model, active_dialog: None), effect.none())
    ConfirmedDialog -> {
      case model.active_dialog {
        Some(ConfirmDialog(_, on_confirm_msg)) ->
          update(Model(..model, active_dialog: None), on_confirm_msg)
        _ -> #(model, effect.none())
      }
    }
    DeleteUserRequestSent(user_id) -> {
      let fx =
        rsvp.delete(
          "/api/users/" <> int.to_string(user_id),
          json.null(),
          rsvp.expect_ok_response(fn(result) {
            case result {
              Ok(_) -> DeletedUser(Ok(user_id))
              Error(e) -> DeletedUser(Error(e))
            }
          }),
        )

      #(model, fx)
    }
    DeletedUser(Ok(user_id)) -> {
      let updated_users = list.filter(model.users, fn(u) { u.id != user_id })
      #(
        Model(..model, users: updated_users),
        fx.toast(
          title: "Success",
          description: "Deleted user " <> int.to_string(user_id) <> ".",
          variant: toast.Success,
        ),
      )
    }
    DeletedUser(Error(_)) -> {
      #(
        model,
        fx.toast(
          title: "Error",
          description: "Failed to delete user.",
          variant: toast.Danger,
        ),
      )
    }
    SubmittedAddUserForm(Error(add_user_form)) -> #(
      Model(..model, add_user_form:),
      effect.none(),
    )
    SubmittedAddUserForm(Ok(data)) -> {
      let add_user_form =
        init_add_user_form()
        |> form.add_string(
          user.RoleField |> user.form_field_to_string,
          data.role |> user.role_to_string,
        )
      let fx =
        rsvp.post(
          "/api/users",
          json.object([
            #("username", json.string(data.username)),
            #("email", json.string(data.email)),
            #("password", json.string(data.password)),
            #("user_role", json.string(user.role_to_string(data.role))),
          ]),
          rsvp.expect_json(user.decoder(), SavedAddUserForm),
        )

      #(Model(..model, add_user_form:), fx)
    }
    SavedAddUserForm(Ok(user)) -> #(
      Model(
        ..model,
        users: [user, ..model.users],
        add_user_form: init_add_user_form(),
        active_dialog: None,
      ),
      fx.toast(
        title: "Success",
        description: "Added user " <> user.username <> ".",
        variant: toast.Success,
      ),
    )
    SavedAddUserForm(Error(rsvp.HttpError(response))) -> {
      case json.parse(response.body, error.decoder()) {
        Ok(error.ValidationError(field:, message:))
        | Ok(error.ConflictError(field:, message:)) -> {
          let add_user_form =
            utils.add_form_custom_error(model.add_user_form, field, message)
          #(Model(..model, add_user_form:), effect.none())
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
            description: "Failed to add user.",
            variant: toast.Danger,
          ),
        )
      }
    }
    SavedAddUserForm(Error(_)) -> #(
      model,
      fx.toast(
        title: "Error",
        description: "Failed to add user.",
        variant: toast.Danger,
      ),
    )
    SubmittedEditUserForm(Error(edit_user_form)) -> #(
      Model(..model, edit_user_form:),
      effect.none(),
    )
    SubmittedEditUserForm(Ok(data)) -> {
      case model.editing_user {
        Some(user) -> {
          let edit_user_form =
            init_edit_user_form(Some(user))
            |> form.add_string(
              user.RoleField |> user.form_field_to_string,
              data.role |> user.role_to_string,
            )
          let fx =
            rsvp.patch(
              "/api/users/" <> int.to_string(user.id),
              json.object([
                #("username", json.string(data.username)),
                #("email", json.string(data.email)),
                #("password", json.string(data.password)),
                #("user_role", json.string(user.role_to_string(data.role))),
              ]),
              rsvp.expect_json(user.decoder(), SavedEditUserForm),
            )
          #(Model(..model, edit_user_form:), fx)
        }
        None -> #(model, effect.none())
      }
    }
    SavedEditUserForm(Ok(user)) -> {
      let users =
        list.map(model.users, fn(u) {
          case u.id == user.id {
            True -> user
            False -> u
          }
        })
      #(
        Model(
          ..model,
          users:,
          edit_user_form: init_edit_user_form(None),
          editing_user: None,
          active_dialog: None,
        ),
        fx.toast(
          title: "Success",
          description: "Edited user " <> user.username <> ".",
          variant: toast.Success,
        ),
      )
    }
    SavedEditUserForm(Error(rsvp.HttpError(response))) -> {
      case json.parse(response.body, error.decoder()) {
        Ok(error.ValidationError(field:, message:))
        | Ok(error.ConflictError(field:, message:)) -> {
          let edit_user_form =
            utils.add_form_custom_error(model.edit_user_form, field, message)
          #(Model(..model, edit_user_form:), effect.none())
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
            description: "Failed to edit user.",
            variant: toast.Danger,
          ),
        )
      }
    }
    SavedEditUserForm(Error(_)) -> #(
      model,
      fx.toast(
        title: "Error",
        description: "Failed to edit user.",
        variant: toast.Danger,
      ),
    )
  }
}

pub fn view(model: Model) -> List(Element(Msg)) {
  [
    html.aside(
      [
        attribute.class(
          "flex z-10 w-64 h-full border shadow bg-card border-border",
        ),
      ],
      [
        html.nav([attribute.class("flex flex-col p-0 w-full text-md")], [
          view_sidebar_button(model.active_tab, GeneralTab, "General"),
          view_sidebar_button(model.active_tab, UsersTab, "Users"),
        ]),
      ],
    ),

    html.main(
      [
        attribute.class("flex-1 p-4 bg-background text-foreground"),
      ],
      [
        case model.active_tab {
          GeneralTab -> view_general_tab(model)
          UsersTab -> view_users_tab(model)
        },
      ],
    ),
  ]
}

fn view_sidebar_button(
  active_tab: Tab,
  target_tab: Tab,
  label: String,
) -> Element(Msg) {
  html.div(
    [
      event.on_click(ClickedTab(target_tab)),
      attribute.classes([
        #(
          "cursor-pointer hover:text-foreground/70 w-full h-14 flex items-center pl-4",
          True,
        ),
        #(
          "font-semibold bg-secondary pointer-events-none",
          active_tab == target_tab,
        ),
      ]),
    ],
    [element.text(label)],
  )
}

fn view_general_tab(_model: Model) -> Element(Msg) {
  element.text("general")
}

fn view_users_tab(model: Model) -> Element(Msg) {
  html.div([attribute.class("flex flex-col gap-2")], [
    view_add_user_dialog(model),
    view_edit_user_dialog(model),
    view_confirm_dialog(model),
    components.button(
      variant: ButtonOutline,
      href: "",
      attributes: [
        attribute.class("mb-2 w-min text-nowrap"),
        event.on_click(OpenedAddUserDialog),
      ],
      children: [element.text("Add User")],
    ),
    ..list.map(model.users, fn(user) {
      components.card_root([attribute.class("w-full")], [
        html.div(
          [
            attribute.class("grid grid-cols-12 gap-4 items-center"),
          ],
          [
            html.div([attribute.class("flex flex-col col-span-2")], [
              html.span([attribute.class("font-medium truncate")], [
                element.text(user.username),
              ]),
              html.span(
                [attribute.class("text-sm text-muted-foreground truncate")],
                [
                  element.text(user.email),
                ],
              ),
            ]),

            html.div([attribute.class("col-span-2")], [
              view_role_badge(user.role),
            ]),

            html.div([attribute.class("flex flex-col col-span-2")], [
              html.span(
                [
                  attribute.class(
                    "text-xs tracking-wider uppercase text-muted-foreground",
                  ),
                ],
                [element.text("Joined")],
              ),
              html.span([attribute.class("text-sm")], [
                element.text(format_timestamp(user.created_at)),
              ]),
            ]),

            html.div([attribute.class("flex flex-col col-span-2")], [
              html.span(
                [
                  attribute.class(
                    "text-xs tracking-wider uppercase text-muted-foreground",
                  ),
                ],
                [element.text("Updated")],
              ),
              html.span([attribute.class("text-sm")], [
                element.text(format_timestamp(user.updated_at)),
              ]),
            ]),

            html.div([attribute.class("flex flex-col col-span-2")], [
              html.span(
                [
                  attribute.class(
                    "text-xs tracking-wider uppercase text-muted-foreground",
                  ),
                ],
                [element.text("Preferred Unit")],
              ),
              html.span([attribute.class("text-sm")], [
                element.text(user.preferred_unit_to_string(user.preferred_unit)),
              ]),
            ]),

            html.div([attribute.class("flex col-span-2 gap-2 justify-end")], [
              components.button(
                variant: ButtonOutline,
                href: "",
                attributes: [
                  attribute.class("flex justify-center items-center"),
                  event.on_click(OpenedEditUserDialog(user)),
                ],
                children: [
                  lucide_lustre.pencil([attribute.class("size-4 shrink-0")]),
                  element.text("Edit"),
                ],
              ),
              components.button(
                variant: ButtonOutline,
                href: "",
                attributes: [
                  attribute.class(
                    "flex justify-center items-center text-destructive hover:text-destructive hover:bg-destructive/10",
                  ),
                  event.on_click(OpenedConfirmDialog(
                    message: "This user will be permanently deleted.",
                    on_confirm: DeleteUserRequestSent(user.id),
                  )),
                ],
                children: [
                  lucide_lustre.trash_2([attribute.class("size-4 shrink-0")]),
                  element.text("Delete"),
                ],
              ),
            ]),
          ],
        ),
      ])
    })
  ])
}

fn view_add_user_dialog(model: Model) -> Element(Msg) {
  let is_open = model.active_dialog == Some(AddUserDialog)
  let id = "add_user_dialog"
  let form_id = "add_user_form"

  components.dialog_root(
    is_open:,
    on_close: ClosedDialog,
    id:,
    attributes: [],
    children: [
      components.dialog_header(id, [], [html.text("Add User")]),
      components.dialog_body([], [
        html.form(
          [
            attribute.id(form_id),
            attribute.class(""),
            event.on_submit(fn(values) {
              model.add_user_form
              |> form.add_values(values)
              |> form.run
              |> SubmittedAddUserForm
            })
              |> event.prevent_default,
          ],
          [
            html.div([attribute.class("flex flex-col gap-2")], [
              components.form_root_error_message_box(model.add_user_form),
              components.form_input(
                form: model.add_user_form,
                is: "text",
                name: user.UsernameField |> user.form_field_to_string,
                label: "Username",
                attributes: [],
              ),
              components.form_input(
                form: model.add_user_form,
                is: "email",
                name: user.EmailField |> user.form_field_to_string,
                label: "Email Address",
                attributes: [],
              ),
              components.form_input(
                form: model.add_user_form,
                is: "password",
                name: user.PasswordField |> user.form_field_to_string,
                label: "Password",
                attributes: [],
              ),
              components.form_input(
                form: model.add_user_form,
                is: "password",
                name: user.ConfirmPasswordField |> user.form_field_to_string,
                label: "Confirm Password",
                attributes: [],
              ),
              html.div([], [
                html.label(
                  [
                    attribute.for("add_user_select"),
                    attribute.class(
                      "block mb-1 text-sm font-medium text-secondary-foreground",
                    ),
                  ],
                  [element.text("Role")],
                ),
                html.select(
                  [
                    attribute.name(user.RoleField |> user.form_field_to_string),
                    attribute.id("add_user_select"),
                    attribute.class(
                      "py-2 px-3 w-full rounded-md border focus:border-transparent focus:ring-2 focus:outline-none border-input-border placeholder:text-muted-foreground focus:ring-ring",
                    ),
                  ],
                  [
                    html.option(
                      [attribute.value(UserRole |> user.role_to_string)],
                      "User",
                    ),
                    html.option(
                      [attribute.value(AdminRole |> user.role_to_string)],
                      "Admin",
                    ),
                  ],
                ),
                ..list.map(
                  form.field_error_messages(model.add_user_form, "role"),
                  fn(msg) {
                    html.p([attribute.class("text-sm text-destructive")], [
                      html.text(msg),
                    ])
                  },
                )
              ]),
            ]),
          ],
        ),
      ]),
      components.dialog_footer([], [
        components.button(
          variant: ButtonSecondary,
          href: "",
          attributes: [event.on_click(ClosedDialog)],
          children: [html.text("Cancel")],
        ),
        components.button(
          variant: ButtonPrimary,
          href: "",
          attributes: [
            attribute.type_("submit"),
            attribute.form(form_id),
          ],
          children: [element.text("Submit")],
        ),
      ]),
    ],
  )
}

fn view_edit_user_dialog(model: Model) -> Element(Msg) {
  let is_open = model.active_dialog == Some(EditUserDialog)
  let id = "edit_user_dialog"
  let form_id = "edit_user_form"

  components.dialog_root(
    is_open:,
    on_close: ClosedDialog,
    id:,
    attributes: [],
    children: [
      components.dialog_header(id, [], [html.text("Edit User")]),
      components.dialog_body([], [
        html.form(
          [
            attribute.id(form_id),
            event.on_submit(fn(values) {
              model.edit_user_form
              |> form.add_values(values)
              |> form.run
              |> SubmittedEditUserForm
            })
              |> event.prevent_default,
          ],
          [
            html.div([attribute.class("flex flex-col gap-2")], [
              components.form_root_error_message_box(model.edit_user_form),
              components.form_input(
                form: model.edit_user_form,
                is: "text",
                name: user.UsernameField |> user.form_field_to_string,
                label: "Username",
                attributes: [
                  attribute.value(form.field_value(
                    model.edit_user_form,
                    user.UsernameField |> user.form_field_to_string,
                  )),
                ],
              ),
              components.form_input(
                form: model.edit_user_form,
                is: "email",
                name: user.EmailField |> user.form_field_to_string,
                label: "Email Address",
                attributes: [
                  attribute.value(form.field_value(
                    model.edit_user_form,
                    user.EmailField |> user.form_field_to_string,
                  )),
                ],
              ),
              components.form_input(
                form: model.edit_user_form,
                is: "password",
                name: user.PasswordField |> user.form_field_to_string,
                label: "Password",
                attributes: [],
              ),
              components.form_input(
                form: model.edit_user_form,
                is: "password",
                name: user.ConfirmPasswordField |> user.form_field_to_string,
                label: "Confirm Password",
                attributes: [],
              ),
              html.div([], [
                html.label(
                  [
                    attribute.for("edit_user_select"),
                    attribute.class(
                      "block mb-1 text-sm font-medium text-secondary-foreground",
                    ),
                  ],
                  [element.text("Role")],
                ),
                html.select(
                  [
                    attribute.name(user.RoleField |> user.form_field_to_string),
                    attribute.id("edit_user_select"),
                    attribute.class(
                      "py-2 px-3 w-full rounded-md border focus:border-transparent focus:ring-2 focus:outline-none border-input-border placeholder:text-muted-foreground focus:ring-ring",
                    ),
                  ],
                  [
                    html.option(
                      [
                        attribute.value(UserRole |> user.role_to_string),
                        attribute.selected(
                          form.field_value(
                            model.edit_user_form,
                            user.RoleField |> user.form_field_to_string,
                          )
                          == user.UserRole |> user.role_to_string,
                        ),
                      ],
                      "User",
                    ),
                    html.option(
                      [
                        attribute.value(AdminRole |> user.role_to_string),
                        attribute.selected(
                          form.field_value(
                            model.edit_user_form,
                            user.RoleField |> user.form_field_to_string,
                          )
                          == user.AdminRole |> user.role_to_string,
                        ),
                      ],
                      "Admin",
                    ),
                  ],
                ),
                ..list.map(
                  form.field_error_messages(
                    model.edit_user_form,
                    user.RoleField |> user.form_field_to_string,
                  ),
                  fn(msg) {
                    html.p([attribute.class("text-sm text-destructive")], [
                      html.text(msg),
                    ])
                  },
                )
              ]),
            ]),
          ],
        ),
      ]),
      components.dialog_footer([], [
        components.button(
          variant: ButtonSecondary,
          href: "",
          attributes: [
            event.on_click(ClosedDialog),
          ],
          children: [html.text("Cancel")],
        ),
        components.button(
          variant: ButtonPrimary,
          href: "",
          attributes: [
            attribute.type_("submit"),
            attribute.attribute("form", form_id),
          ],
          children: [element.text("Submit")],
        ),
      ]),
    ],
  )
}

fn view_confirm_dialog(model: Model) -> Element(Msg) {
  let #(is_open, display_message) = case model.active_dialog {
    Some(ConfirmDialog(message: msg, ..)) -> #(True, msg)
    _ -> #(False, "")
  }

  let id = "confirm_dialog"

  components.dialog_root(
    is_open:,
    on_close: ClosedDialog,
    id:,
    attributes: [attribute.class("rounded-lg")],
    children: [
      components.dialog_header(id, [], [html.text("Are you sure?")]),
      components.dialog_body([], [
        html.div([attribute.class("flex flex-col gap-2")], [
          html.p([], [html.text(display_message)]),
        ]),
      ]),
      components.dialog_footer([], [
        components.button(
          variant: ButtonSecondary,
          href: "",
          attributes: [
            attribute.type_("button"),
            event.on_click(ClosedDialog),
          ],
          children: [html.text("Cancel")],
        ),
        components.button(
          variant: ButtonDanger,
          href: "",
          attributes: [
            attribute.type_("button"),
            event.on_click(ConfirmedDialog),
          ],
          children: [html.text("Confirm")],
        ),
      ]),
    ],
  )
}

fn view_role_badge(role: AppUserRole) -> Element(Msg) {
  let #(label, class) = case role {
    user.AdminRole -> #(
      "Admin",
      "bg-primary-background-subtle text-primary-foreground border-primary/30",
    )
    user.UserRole -> #(
      "User",
      "bg-secondary text-secondary-foreground border-border",
    )
  }

  html.span(
    [
      attribute.classes([
        #("py-0.5 px-2.5 w-max text-xs font-semibold rounded-full border", True),
        #(class, True),
      ]),
    ],
    [element.text(label)],
  )
}

fn format_timestamp(ts: timestamp.Timestamp) -> String {
  timestamp.to_rfc3339(ts, duration.seconds(0))
  |> string.replace(each: "T", with: " ")
  |> string.replace(each: "Z", with: "")
  |> string.drop_end(7)
}
