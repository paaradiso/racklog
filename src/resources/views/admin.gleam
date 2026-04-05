import database/main/models/user/gen/user.{type User}
import gleam/list
import gleam/option
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import resources/views/components/components.{ButtonPrimary}

pub type Tab {
  UsersTab
  SettingsTab
}

pub type Model {
  Model(user: option.Option(User), users: List(User), active_tab: Tab)
}

pub fn view(model: Model, children: List(Element(Nil))) {
  html.div(
    [attribute.class("flex flex-col gap-2 items-center justify-center w-full")],
    [
      html.nav(
        [
          attribute.class(
            "flex gap-2 border-b border-border pb-2 w-full grow container",
          ),
        ],
        [
          tab_link("Users", "?tab=users", UsersTab, model.active_tab),
          tab_link("Settings", "?tab=settings", SettingsTab, model.active_tab),
        ],
      ),
      html.div([attribute.class("container")], [
        case model.active_tab {
          UsersTab ->
            html.div(
              [attribute.class("flex flex-col gap-2 w-full")],
              list.map(model.users, fn(user) {
                components.card_root(
                  attributes: [
                    attribute.class("w-full flex items-center justify-between"),
                  ],
                  children: [
                    html.span([], [element.text(user.email)]),
                    html.span([], [element.text("icons")]),
                  ],
                )
              }),
            )
          SettingsTab -> html.div([], [element.text("settings")])
        },
      ]),
    ],
  )
}

fn tab_link(
  label: String,
  url: String,
  this_tab: Tab,
  active_tab: Tab,
) -> Element(Nil) {
  components.link(
    href: url,
    attributes: [
      attribute.classes([#("font-semibold", this_tab == active_tab)]),
    ],
    children: [element.text(label)],
  )
}
