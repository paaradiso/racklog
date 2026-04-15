import components.{ButtonDanger, ButtonOutline, ButtonPrimary, ButtonSecondary}
import fx
import glaze/oat/dialog
import glaze/oat/sidebar
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
import racklog/user.{type AppUserRole, type UserDto, AdminRole, UserRole}
import rsvp

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

pub type AddUserForm {
  AddUserForm(
    username: String,
    email: String,
    password: String,
    role: AppUserRole,
    error: String,
  )
}

pub type EditUserForm {
  EditUserForm(
    id: Int,
    username: String,
    email: String,
    password: String,
    role: AppUserRole,
    error: String,
  )
}

fn default_add_user_form() -> AddUserForm {
  AddUserForm(username: "", email: "", password: "", role: UserRole, error: "")
}

fn default_edit_user_form() -> EditUserForm {
  EditUserForm(
    id: 0,
    username: "",
    email: "",
    password: "",
    role: UserRole,
    error: "",
  )
}

fn dialog_to_id(dialog: Dialog) -> String {
  case dialog {
    AddUserDialog -> "add_user"
    EditUserDialog -> "edit_user"
    ConfirmDialog(_, _) -> "confirm"
  }
}

pub type Model {
  Model(
    active_tab: Tab,
    users: List(UserDto),
    add_user_form: AddUserForm,
    edit_user_form: EditUserForm,
    confirm_dialog: Option(Dialog),
  )
}

pub type Msg {
  ClickedTab(Tab)
  FetchedUsers(Result(List(UserDto), rsvp.Error))
  OpenedAddUserDialog
  OpenedEditUserDialog(UserDto)
  OpenedConfirmDialog(message: String, on_confirm: Msg)
  ClosedConfirmDialog
  ConfirmedDialog
  DeleteUserRequestSent(Int)
  DeletedUser(Result(Int, rsvp.Error))
  UpdatedAddUserForm(AddUserForm)
  SubmittedAddUser
  AddedUser(Result(UserDto, rsvp.Error))
  UpdatedEditUserForm(EditUserForm)
  SubmittedEditUser
  EditedUser(Result(UserDto, rsvp.Error))
}

pub fn init() -> #(Model, Effect(Msg)) {
  init_with_tab(GeneralTab)
}

pub fn init_with_tab(tab: Tab) -> #(Model, Effect(Msg)) {
  let model =
    Model(
      active_tab: tab,
      users: [],
      add_user_form: default_add_user_form(),
      edit_user_form: default_edit_user_form(),
      confirm_dialog: None,
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
      Model(..model, add_user_form: default_add_user_form()),
      effect.none(),
    )
    OpenedEditUserDialog(user) -> #(
      Model(
        ..model,
        edit_user_form: EditUserForm(
          id: user.id,
          username: user.username,
          email: user.email,
          password: "",
          role: user.role,
          error: "",
        ),
      ),
      effect.none(),
    )
    OpenedConfirmDialog(message: message, on_confirm: on_confirm_msg) -> #(
      Model(
        ..model,
        confirm_dialog: Some(ConfirmDialog(message, on_confirm_msg)),
      ),
      effect.none(),
    )
    ClosedConfirmDialog -> #(
      Model(..model, confirm_dialog: None),
      close_dialog("confirm"),
    )
    ConfirmedDialog -> {
      case model.confirm_dialog {
        Some(ConfirmDialog(_, on_confirm_msg)) ->
          update(Model(..model, confirm_dialog: None), on_confirm_msg)
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

      #(model, effect.batch([fx, close_dialog("confirm")]))
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
    UpdatedAddUserForm(form) -> {
      #(Model(..model, add_user_form: form), effect.none())
    }
    SubmittedAddUser -> {
      let fx =
        rsvp.post(
          "/api/users",
          json.object([
            #("username", json.string(model.add_user_form.username)),
            #("email", json.string(model.add_user_form.email)),
            #("password", json.string(model.add_user_form.password)),
            #(
              "user_role",
              json.string(user.role_to_string(model.add_user_form.role)),
            ),
          ]),
          rsvp.expect_json(user.decoder(), AddedUser),
        )

      #(model, fx)
    }
    AddedUser(Ok(user)) -> #(
      Model(
        ..model,
        users: [user, ..model.users],
        add_user_form: default_add_user_form(),
      ),
      effect.batch([
        close_dialog(dialog_to_id(AddUserDialog)),

        fx.toast(
          title: "Success",
          description: "Added user" <> user.username <> ".",
          variant: toast.Success,
        ),
      ]),
    )
    AddedUser(Error(_)) -> {
      let form =
        AddUserForm(..model.add_user_form, error: "Failed to add user.")
      #(
        Model(..model, add_user_form: form),
        fx.toast(
          title: "Error",
          description: "Failed to add user.",
          variant: toast.Danger,
        ),
      )
    }
    UpdatedEditUserForm(form) -> {
      #(Model(..model, edit_user_form: form), effect.none())
    }
    SubmittedEditUser -> {
      let payload_fields = [
        #("email", json.string(model.edit_user_form.email)),
        #(
          "user_role",
          json.string(user.role_to_string(model.edit_user_form.role)),
        ),
      ]
      let payload_fields = case model.edit_user_form.password {
        "" -> payload_fields
        pw -> [#("password", json.string(pw)), ..payload_fields]
      }
      let payload_fields = case model.edit_user_form.username {
        "" -> payload_fields
        username -> [#("username", json.string(username)), ..payload_fields]
      }
      let fx =
        rsvp.patch(
          "/api/users/" <> int.to_string(model.edit_user_form.id),
          json.object(payload_fields),
          rsvp.expect_json(user.decoder(), EditedUser),
        )

      #(model, fx)
    }
    EditedUser(Ok(user)) -> {
      let users =
        list.map(model.users, fn(u) {
          case u.id == user.id {
            True -> user
            False -> u
          }
        })
      #(
        Model(..model, users: users, edit_user_form: default_edit_user_form()),
        effect.batch([
          close_dialog(dialog_to_id(EditUserDialog)),
          fx.toast(
            title: "Success",
            description: "Edited user " <> user.username <> ".",
            variant: toast.Success,
          ),
        ]),
      )
    }
    EditedUser(Error(_)) -> {
      let form =
        EditUserForm(..model.edit_user_form, error: "Failed to edit user.")
      #(
        Model(..model, edit_user_form: form),
        fx.toast(
          title: "Error",
          description: "Failed to edit user.",
          variant: toast.Danger,
        ),
      )
    }
  }
}

pub fn view(model: Model) -> List(Element(Msg)) {
  [
    sidebar.sidebar_always(
      html.div,
      [attribute.class("flex flex-row w-full h-full")],
      [
        sidebar.aside([attribute.class("w-64 bg-card")], [
          sidebar.nav([attribute.class("flex flex-col p-0 text-md")], [
            view_sidebar_button(model.active_tab, GeneralTab, "General"),
            view_sidebar_button(model.active_tab, UsersTab, "Users"),
          ]),
        ]),

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
        ..dialog.open_for(dialog_to_id(AddUserDialog))
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
                  ..dialog.open_for(dialog_to_id(EditUserDialog))
                ],
                children: [
                  lucide_lustre.pencil([attribute.class("size-4")]),
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
                  ..dialog.open_for("confirm")
                ],
                children: [
                  lucide_lustre.trash_2([attribute.class("size-4")]),
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
  dialog.dialog(
    [
      dialog.id(dialog_to_id(AddUserDialog)),
      attribute.class("rounded-lg"),
    ],
    [
      dialog.header([], [dialog.title([], [html.text("Add User")])]),
      html.form(
        [
          attribute.id("add_user_form"),
          attribute.class(""),
          event.on_submit(fn(_) { SubmittedAddUser })
            |> event.prevent_default,
        ],
        [
          html.div([attribute.class("flex flex-col gap-2")], [
            case model.add_user_form.error {
              "" -> element.none()
              msg -> components.error_message_box(msg)
            },
            components.form_input(
              label: "Username",
              id: "username",
              name: "username",
              attributes: [
                attribute.value(model.add_user_form.username),
                event.on_input(fn(v) {
                  UpdatedAddUserForm(
                    AddUserForm(..model.add_user_form, username: v),
                  )
                }),
              ],
            ),
            components.form_input(
              label: "Email Address",
              id: "email",
              name: "email",
              attributes: [
                attribute.type_("email"),
                attribute.value(model.add_user_form.email),
                event.on_input(fn(v) {
                  UpdatedAddUserForm(
                    AddUserForm(..model.add_user_form, email: v),
                  )
                }),
              ],
            ),
            components.form_input(
              label: "Password",
              id: "password",
              name: "password",
              attributes: [
                attribute.type_("password"),
                attribute.value(model.add_user_form.password),
                event.on_input(fn(v) {
                  UpdatedAddUserForm(
                    AddUserForm(..model.add_user_form, password: v),
                  )
                }),
              ],
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
                  attribute.id("add_user_select"),
                  attribute.class(
                    "py-2 px-3 w-full rounded-md border focus:border-transparent focus:ring-2 focus:outline-none border-input-border placeholder:text-muted-foreground focus:ring-ring",
                  ),
                  event.on_change(fn(value) {
                    case value {
                      "Admin" ->
                        UpdatedAddUserForm(
                          AddUserForm(..model.add_user_form, role: AdminRole),
                        )
                      _ ->
                        UpdatedAddUserForm(
                          AddUserForm(..model.add_user_form, role: UserRole),
                        )
                    }
                  }),
                ],
                [
                  html.option([], "User"),
                  html.option([], "Admin"),
                ],
              ),
            ]),
          ]),
        ],
      ),
      dialog.footer([], [
        components.button(
          variant: ButtonSecondary,
          href: "",
          attributes: dialog.close_for(dialog_to_id(AddUserDialog)),
          children: [html.text("Cancel")],
        ),
        components.button(
          variant: ButtonPrimary,
          href: "",
          attributes: [
            attribute.type_("submit"),
            attribute.attribute("form", "add_user_form"),
          ],
          children: [element.text("Submit")],
        ),
      ]),
    ],
  )
}

fn view_edit_user_dialog(model: Model) -> Element(Msg) {
  dialog.dialog(
    [
      dialog.id(dialog_to_id(EditUserDialog)),
      attribute.class("rounded-lg"),
    ],
    [
      dialog.header([], [dialog.title([], [html.text("Edit User")])]),
      html.form(
        [
          attribute.id("edit_user_form"),
          attribute.class(""),
          event.on_submit(fn(_) { SubmittedEditUser })
            |> event.prevent_default,
        ],
        [
          html.div([attribute.class("flex flex-col gap-2")], [
            case model.edit_user_form.error {
              "" -> element.none()
              msg -> components.error_message_box(msg)
            },
            components.form_input(
              label: "Username",
              id: "username",
              name: "username",
              attributes: [
                attribute.value(model.edit_user_form.username),
                event.on_input(fn(v) {
                  UpdatedEditUserForm(
                    EditUserForm(..model.edit_user_form, username: v),
                  )
                }),
              ],
            ),
            components.form_input(
              label: "Email Address",
              id: "email",
              name: "email",
              attributes: [
                attribute.type_("email"),
                attribute.value(model.edit_user_form.email),
                event.on_input(fn(v) {
                  UpdatedEditUserForm(
                    EditUserForm(..model.edit_user_form, email: v),
                  )
                }),
              ],
            ),
            components.form_input(
              label: "Password",
              id: "password",
              name: "password",
              attributes: [
                attribute.type_("password"),
                attribute.value(model.edit_user_form.password),
                event.on_input(fn(v) {
                  UpdatedEditUserForm(
                    EditUserForm(..model.edit_user_form, password: v),
                  )
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
                [element.text("Role")],
              ),
              html.select(
                [
                  attribute.id("edit_user_select"),
                  attribute.class(
                    "py-2 px-3 w-full rounded-md border focus:border-transparent focus:ring-2 focus:outline-none border-input-border placeholder:text-muted-foreground focus:ring-ring",
                  ),
                  event.on_change(fn(value) {
                    case value {
                      "Admin" ->
                        UpdatedEditUserForm(
                          EditUserForm(..model.edit_user_form, role: AdminRole),
                        )
                      _ ->
                        UpdatedEditUserForm(
                          EditUserForm(..model.edit_user_form, role: UserRole),
                        )
                    }
                  }),
                ],
                [
                  html.option(
                    [attribute.selected(model.edit_user_form.role == UserRole)],
                    "User",
                  ),
                  html.option(
                    [attribute.selected(model.edit_user_form.role == AdminRole)],
                    "Admin",
                  ),
                ],
              ),
            ]),
          ]),
        ],
      ),
      dialog.footer([], [
        components.button(
          variant: ButtonSecondary,
          href: "",
          attributes: dialog.close_for(dialog_to_id(EditUserDialog)),
          children: [html.text("Cancel")],
        ),
        components.button(
          variant: ButtonPrimary,
          href: "",
          attributes: [
            attribute.type_("submit"),
            attribute.attribute("form", "edit_user_form"),
          ],
          children: [element.text("Submit")],
        ),
      ]),
    ],
  )
}

fn view_confirm_dialog(model: Model) -> Element(Msg) {
  let display_message = case model.confirm_dialog {
    Some(ConfirmDialog(message: msg, ..)) -> msg
    _ -> ""
  }

  dialog.dialog([dialog.id("confirm"), attribute.class("rounded-lg")], [
    dialog.header([], [dialog.title([], [html.text("Are you sure?")])]),
    html.div([attribute.class("flex flex-col gap-2")], [
      html.p([], [html.text(display_message)]),
    ]),
    dialog.footer([], [
      components.button(
        variant: ButtonSecondary,
        href: "",
        attributes: [
          event.on_click(ClosedConfirmDialog),
          ..dialog.close_for("confirm")
        ],
        children: [html.text("Cancel")],
      ),
      components.button(
        variant: ButtonDanger,
        href: "",
        attributes: [event.on_click(ConfirmedDialog)],
        children: [html.text("Confirm")],
      ),
    ]),
  ])
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

fn close_dialog(id: String) -> Effect(Msg) {
  effect.from(fn(_) { js_close_dialog("#" <> id) })
}

@external(javascript, "../ffi.js", "closeDialog")
fn js_close_dialog(selector: String) -> Nil
