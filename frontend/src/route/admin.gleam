import components.{ButtonDanger, ButtonOutline, ButtonPrimary, ButtonSecondary}
import glaze/oat/dialog
import glaze/oat/sidebar
import gleam/dynamic/decode
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import lucide_lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import rsvp

pub type AppUserRole {
  UserRole
  AdminRole
}

pub type User {
  User(
    id: Int,
    username: String,
    email: String,
    user_role: AppUserRole,
    created_at: String,
    updated_at: String,
  )
}

fn user_role_string_to_variant(user_role: String) -> AppUserRole {
  case user_role {
    "admin" -> AdminRole
    _ -> UserRole
  }
}

fn user_role_to_string(user_role: AppUserRole) -> String {
  case user_role {
    AdminRole -> "admin"
    UserRole -> "user"
  }
}

fn decode_role() -> decode.Decoder(AppUserRole) {
  use role_str <- decode.then(decode.string)
  case role_str {
    "admin" -> decode.success(AdminRole)
    "user" -> decode.success(UserRole)
    _ -> decode.failure(UserRole, "admin or user")
  }
}

fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.int)
  use username <- decode.field("username", decode.string)
  use email <- decode.field("email", decode.string)
  use user_role <- decode.field("user_role", decode_role())
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)
  decode.success(User(
    id:,
    username:,
    email:,
    user_role:,
    created_at:,
    updated_at:,
  ))
}

fn users_decoder() -> decode.Decoder(List(User)) {
  decode.list(user_decoder())
}

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
    user_role: AppUserRole,
    error: String,
  )
}

pub type EditUserForm {
  EditUserForm(
    id: Int,
    username: String,
    email: String,
    password: String,
    user_role: AppUserRole,
    error: String,
  )
}

fn default_add_user_form() -> AddUserForm {
  AddUserForm(
    username: "",
    email: "",
    password: "",
    user_role: UserRole,
    error: "",
  )
}

fn default_edit_user_form() -> EditUserForm {
  EditUserForm(
    id: 0,
    username: "",
    email: "",
    password: "",
    user_role: UserRole,
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
    users: List(User),
    add_user_form: AddUserForm,
    edit_user_form: EditUserForm,
    confirm_dialog: Option(Dialog),
  )
}

pub type Msg {
  ClickedTab(Tab)
  FetchedUsers(Result(List(User), rsvp.Error))
  OpenedAddUserDialog
  OpenedEditUserDialog(User)
  OpenedConfirmDialog(message: String, on_confirm: Msg)
  ClosedConfirmDialog
  ConfirmedDialog
  DeleteUserRequestSent(Int)
  DeletedUser(Result(Int, rsvp.Error))
  UpdatedAddUserUsername(String)
  UpdatedAddUserEmail(String)
  UpdatedAddUserPassword(String)
  SubmittedAddUser
  AddedUser(Result(User, rsvp.Error))
  UpdatedEditUserUsername(String)
  UpdatedEditUserEmail(String)
  UpdatedEditUserPassword(String)
  SubmittedEditUser
  EditedUser(Result(User, rsvp.Error))
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
      rsvp.get("/api/users", rsvp.expect_json(users_decoder(), FetchedUsers))
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
              rsvp.expect_json(users_decoder(), FetchedUsers),
            ),
          ])
        _ -> modem.push(path, None, None)
      }
      #(next_model, fx)
    }
    FetchedUsers(Ok(users)) -> #(Model(..model, users:), effect.none())
    FetchedUsers(Error(_)) -> #(model, effect.none())
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
          user_role: user.user_role,
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
      #(Model(..model, users: updated_users), effect.none())
    }

    DeletedUser(Error(e)) -> {
      #(model, effect.none())
    }
    UpdatedAddUserUsername(username) -> {
      let form = AddUserForm(..model.add_user_form, username:)
      #(Model(..model, add_user_form: form), effect.none())
    }
    UpdatedAddUserEmail(email) -> {
      let form = AddUserForm(..model.add_user_form, email:)
      #(Model(..model, add_user_form: form), effect.none())
    }
    UpdatedAddUserPassword(password) -> {
      let form = AddUserForm(..model.add_user_form, password:)
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
              json.string(user_role_to_string(model.add_user_form.user_role)),
            ),
          ]),
          rsvp.expect_json(user_decoder(), AddedUser),
        )

      #(model, fx)
    }
    AddedUser(Ok(user)) -> #(
      Model(
        ..model,
        users: [user, ..model.users],
        add_user_form: default_add_user_form(),
      ),
      close_dialog(dialog_to_id(AddUserDialog)),
    )
    AddedUser(Error(e)) -> {
      let form =
        AddUserForm(..model.add_user_form, error: "Failed to add user.")
      #(Model(..model, add_user_form: form), effect.none())
    }
    UpdatedEditUserUsername(username) -> {
      let form = EditUserForm(..model.edit_user_form, username:)
      #(Model(..model, edit_user_form: form), effect.none())
    }
    UpdatedEditUserEmail(email) -> {
      let form = EditUserForm(..model.edit_user_form, email:)
      #(Model(..model, edit_user_form: form), effect.none())
    }
    UpdatedEditUserPassword(password) -> {
      let form = EditUserForm(..model.edit_user_form, password:)
      #(Model(..model, edit_user_form: form), effect.none())
    }
    SubmittedEditUser -> {
      let payload_fields = [
        #("email", json.string(model.edit_user_form.email)),
        #(
          "user_role",
          json.string(user_role_to_string(model.edit_user_form.user_role)),
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
          rsvp.expect_json(user_decoder(), EditedUser),
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
        close_dialog(dialog_to_id(EditUserDialog)),
      )
    }
    EditedUser(Error(e)) -> {
      let form =
        EditUserForm(..model.edit_user_form, error: "Failed to edit user.")
      #(Model(..model, edit_user_form: form), effect.none())
    }
  }
}

pub fn view(model: Model) -> List(Element(Msg)) {
  [
    sidebar.sidebar_always(
      html.div,
      [attribute.class("w-full h-full flex flex-row overflow-hidden")],
      [
        sidebar.aside([attribute.class("w-64 overflow-y-auto bg-card")], [
          sidebar.nav([attribute.class("flex flex-col text-md p-0")], [
            view_sidebar_button(model.active_tab, GeneralTab, "General"),
            view_sidebar_button(model.active_tab, UsersTab, "Users"),
          ]),
        ]),

        html.main(
          [
            attribute.class(
              "container flex-1 overflow-y-auto p-4 bg-background text-foreground",
            ),
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
        #("font-semibold bg-secondary", active_tab == target_tab),
      ]),
    ],
    [element.text(label)],
  )
}

fn view_general_tab(model: Model) -> Element(Msg) {
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
        attribute.class("w-min text-nowrap"),
        event.on_click(OpenedAddUserDialog),
        ..dialog.open_for(dialog_to_id(AddUserDialog))
      ],
      children: [element.text("Add User")],
    ),
    ..list.map(model.users, fn(user) {
      components.card_root(
        [attribute.class("flex justify-between items-center")],
        [
          html.div([attribute.class("flex flex-col")], [
            html.span([attribute.class("font-medium")], [
              element.text(user.username),
            ]),
            html.span([attribute.class("text-sm text-muted-foreground")], [
              element.text(user.email),
            ]),
          ]),
          html.span([attribute.class("flex gap-2")], [
            components.button(
              variant: ButtonOutline,
              href: "",
              attributes: [
                attribute.class(
                  "py-0! h-10 px-4! flex items-center justify-center",
                ),
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
                  "py-0! h-10 px-4! flex items-center justify-center",
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
      )
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
            components.form_input(
              label: "Username",
              id: "username",
              name: "username",
              attributes: [
                attribute.value(model.add_user_form.username),
                event.on_input(UpdatedAddUserUsername),
              ],
            ),
            components.form_input(
              label: "Email Address",
              id: "email",
              name: "email",
              attributes: [
                attribute.type_("email"),
                attribute.value(model.add_user_form.email),
                event.on_input(UpdatedAddUserEmail),
              ],
            ),
            components.form_input(
              label: "Password",
              id: "password",
              name: "password",
              attributes: [
                attribute.type_("password"),
                attribute.value(model.add_user_form.password),
                event.on_input(UpdatedAddUserPassword),
              ],
            ),
            html.div([], [
              html.label(
                [
                  attribute.for("add_user_select"),
                  attribute.class(
                    "block text-sm font-medium text-secondary-foreground mb-1",
                  ),
                ],
                [element.text("Role")],
              ),
              html.select(
                [
                  attribute.id("add_user_select"),
                  attribute.class(
                    "w-full px-3 py-2 border border-input-border rounded-md focus:outline-none focus:ring-2 focus:ring-ring focus:border-transparent placeholder:text-muted-foreground",
                  ),
                ],
                [html.option([], "User"), html.option([], "Admin")],
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
            components.form_input(
              label: "Username",
              id: "username",
              name: "username",
              attributes: [
                attribute.value(model.edit_user_form.username),
                event.on_input(UpdatedEditUserUsername),
              ],
            ),
            components.form_input(
              label: "Email Address",
              id: "email",
              name: "email",
              attributes: [
                attribute.type_("email"),
                attribute.value(model.edit_user_form.email),
                event.on_input(UpdatedEditUserEmail),
              ],
            ),
            components.form_input(
              label: "Password",
              id: "password",
              name: "password",
              attributes: [
                attribute.type_("password"),
                attribute.value(model.edit_user_form.password),
                event.on_input(UpdatedEditUserPassword),
              ],
            ),
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
    _ -> "Are you sure?"
  }

  dialog.dialog([dialog.id("confirm"), attribute.class("rounded-lg")], [
    dialog.header([], [dialog.title([], [html.text(display_message)])]),
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

fn close_dialog(id: String) -> Effect(Msg) {
  effect.from(fn(_) { js_close_dialog("#" <> id) })
}

@external(javascript, "../ffi.js", "closeDialog")
fn js_close_dialog(selector: String) -> Nil
