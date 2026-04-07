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

pub type User {
  User(id: Int, email: String, created_at: String, updated_at: String)
}

fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.int)
  use email <- decode.field("email", decode.string)
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)
  decode.success(User(id:, email:, created_at:, updated_at:))
}

fn users_decoder() -> decode.Decoder(List(User)) {
  decode.list(user_decoder())
}

pub type Tab {
  GeneralTab
  UsersTab
}

pub type Dialog {
  AddUserDialog
  ConfirmDialog(message: String, on_confirm: Msg)
}

pub type AddUserForm {
  AddUserForm(email: String, password: String, error: String)
}

fn default_add_user_form() -> AddUserForm {
  AddUserForm(email: "", password: "", error: "")
}

fn dialog_to_id(dialog: Dialog) -> String {
  case dialog {
    AddUserDialog -> "add_user"
    ConfirmDialog(_, _) -> "confirm"
  }
}

pub type Model {
  Model(
    active_tab: Tab,
    users: List(User),
    add_user_form: AddUserForm,
    confirm_dialog: Option(Dialog),
  )
}

pub type Msg {
  ClickedTab(Tab)
  FetchedUsers(Result(List(User), rsvp.Error))
  OpenedAddUserDialog
  OpenedConfirmDialog(message: String, on_confirm: Msg)
  ClosedConfirmDialog
  ConfirmedDialog
  DeleteUserRequestSent(Int)
  DeletedUser(Result(Int, rsvp.Error))
  UpdatedAddUserEmail(String)
  UpdatedAddUserPassword(String)
  SubmittedAddUser
  AddedUser(Result(User, rsvp.Error))
}

pub fn init() -> #(Model, Effect(Msg)) {
  #(
    Model(
      active_tab: GeneralTab,
      users: [],
      add_user_form: default_add_user_form(),
      confirm_dialog: None,
    ),
    effect.none(),
  )
}

pub fn update(model model: Model, msg msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ClickedTab(GeneralTab) -> #(
      Model(..model, active_tab: GeneralTab),
      effect.none(),
    )
    ClickedTab(UsersTab) -> {
      let fetch_users_effect =
        rsvp.get("/api/users", rsvp.expect_json(users_decoder(), FetchedUsers))
      #(Model(..model, active_tab: UsersTab), fetch_users_effect)
    }
    FetchedUsers(Ok(users)) -> #(Model(..model, users:), effect.none())
    FetchedUsers(Error(_)) -> #(model, effect.none())
    OpenedAddUserDialog -> #(
      Model(..model, add_user_form: default_add_user_form()),
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
          "/api/create_user",
          json.object([
            #("email", json.string(model.add_user_form.email)),
            #("password", json.string(model.add_user_form.password)),
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
  }
}

pub fn view(model: Model) -> List(Element(Msg)) {
  [
    sidebar.sidebar_always(
      html.div,
      [attribute.class("flex-1 flex flex-row overflow-hidden")],
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
              "flex-1 overflow-y-auto p-4 bg-background text-foreground",
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
          "cursor-pointer hover:text-foreground/70  w-full h-14 flex items-center pl-4",
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
  html.div(
    [attribute.class("flex flex-col gap-2")],
    [
      [
        components.button(
          variant: ButtonOutline,
          href: "",
          attributes: [
            [attribute.class("w-min text-nowrap")],
            dialog.open_for(dialog_to_id(AddUserDialog)),
            [event.on_click(OpenedAddUserDialog)],
          ]
            |> list.flatten,
          children: [element.text("Add User")],
        ),
        view_add_user_dialog(model),
        view_confirm_dialog(model),
      ],
      list.map(model.users, fn(user) {
        components.card_root(
          [attribute.class("flex justify-between items-center")],
          [
            html.span([], [element.text(user.email)]),
            components.button(
              variant: ButtonOutline,
              href: "",
              attributes: [
                [
                  attribute.class(
                    "p-0! size-10 flex items-center justify-center",
                  ),
                  event.on_click(OpenedConfirmDialog(
                    message: "This user will be permanently deleted.",
                    on_confirm: DeleteUserRequestSent(user.id),
                  )),
                ],
                dialog.open_for("confirm"),
              ]
                |> list.flatten,
              children: [
                lucide_lustre.trash_2([attribute.class("size-4")]),
              ],
            ),
          ],
        )
      }),
    ]
      |> list.flatten,
  )
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
              label: "Email Address",
              id: "email",
              name: "email",
              attributes: [
                attribute.type_("email"),
                event.on_input(UpdatedAddUserEmail),
              ],
            ),
            components.form_input(
              label: "Password",
              id: "password",
              name: "password",
              attributes: [
                attribute.type_("password"),
                event.on_input(UpdatedAddUserPassword),
              ],
            ),
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

fn view_confirm_dialog(model: Model) -> Element(Msg) {
  let display_message = case model.confirm_dialog {
    Some(ConfirmDialog(message: msg, ..)) -> msg
    _ -> "Are you sure?"
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

fn close_dialog(id: String) -> Effect(Msg) {
  effect.from(fn(_) { js_close_dialog("#" <> id) })
}

@external(javascript, "../ffi/admin.js", "closeDialog")
fn js_close_dialog(selector: String) -> Nil
