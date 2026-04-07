import components.{ButtonOutline, ButtonPrimary, ButtonSecondary}
import glaze/oat/dialog
import glaze/oat/sidebar
import gleam/dynamic/decode
import gleam/http/response
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
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
}

fn dialog_to_id(dialog: Dialog) -> String {
  case dialog {
    AddUserDialog -> "add_user"
  }
}

pub type Model {
  Model(active_tab: Tab, users: List(User), dialog: Option(Dialog))
}

pub type Msg {
  ClickedTab(Tab)
  ClickedAddUserButton
  FetchedUsers(Result(List(User), rsvp.Error))
}

pub fn init() -> #(Model, Effect(Msg)) {
  #(Model(active_tab: GeneralTab, users: [], dialog: None), effect.none())
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
    ClickedAddUserButton -> {
      #(model, modem.push("/admin/add_user", None, None))
    }
    FetchedUsers(Ok(users)) -> #(Model(..model, users:), effect.none())
    FetchedUsers(Error(_)) -> #(model, effect.none())
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
          ]
            |> list.flatten,
          children: [element.text("Add User")],
        ),
        dialog.dialog(
          [
            dialog.id(dialog_to_id(AddUserDialog)),
            attribute.class("rounded-lg"),
          ],
          [
            dialog.header([], [dialog.title([], [html.text("Add User")])]),
            html.div([attribute.class("flex flex-col gap-2")], [
              components.form_input(
                label: "Email Address",
                id: "email",
                name: "email",
                attributes: [
                  attribute.type_("email"),
                  // attribute.value(model.email),
                // event.on_input(UpdatedEmail),
                ],
              ),
              components.form_input(
                label: "Password",
                id: "password",
                name: "password",
                attributes: [
                  attribute.type_("password"),
                  // attribute.value(model.password),
                // event.on_input(UpdatedPassword),
                ],
              ),
            ]),
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
                ],
                children: [element.text("Add User")],
              ),
            ]),
          ],
        ),
      ],
      list.map(model.users, fn(user) {
        components.card_root([], [element.text(user.email)])
      }),
    ]
      |> list.flatten,
  )
}
