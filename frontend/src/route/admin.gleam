import components.{ButtonPrimary}
import glaze/oat/sidebar
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

pub type Tab {
  GeneralTab
  UsersTab
}

pub type Model {
  Model(active_tab: Tab)
}

pub type Msg {
  ClickedTab(Tab)
}

pub fn init() -> #(Model, Effect(Msg)) {
  #(Model(active_tab: GeneralTab), effect.none())
}

pub fn update(model model: Model, msg msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ClickedTab(tab) -> #(Model(active_tab: tab), effect.none())
  }
}

pub fn view(model: Model) -> List(Element(Msg)) {
  [
    sidebar.sidebar_always(
      html.div,
      [attribute.class("flex-1 flex flex-row overflow-hidden")],
      [
        sidebar.aside([attribute.class("w-64 overflow-y-auto")], [
          sidebar.nav([attribute.class("flex flex-col text-md p-0")], [
            view_tab(model.active_tab, GeneralTab, "General"),
            view_tab(model.active_tab, UsersTab, "Users"),
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

fn view_tab(active_tab: Tab, target_tab: Tab, label: String) -> Element(Msg) {
  html.div(
    [
      event.on_click(ClickedTab(target_tab)),
      attribute.classes([
        #(
          "cursor-pointer hover:text-foreground/70 w-full h-14 flex items-center p-2",
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
  element.text("users")
}
