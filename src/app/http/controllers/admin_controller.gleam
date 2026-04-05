import app/app.{type App}
import app/http/middleware/auth_user
import app/http/ui
import compiled/loom/admin
import database/main/models/user/gen/user
import gleam/list
import gleam/option
import gleam/string
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/http/middleware
import glimr/response/response
import glimr/vite
import lustre/element
import resources/views/admin.{Model} as admin_view
import resources/views/layout
import wisp

/// @get "/admin"
pub fn show(ctx: Context(App)) -> Response {
  use ctx <- middleware.apply([auth_user.run], ctx)
  let assert option.Some(user) = ctx.app.user

  let users = user.list_or_fail(ctx.app.db)

  response.html(admin.render(ctx: ctx, user: user, users: users), 200)
}

/// @get "/admin_lustre"
pub fn show_lustre(ctx: Context(App)) -> Response {
  use ctx <- middleware.apply([auth_user.run], ctx)

  let query_params = wisp.get_query(ctx.req)

  let active_tab = case list.key_find(query_params, "tab") {
    Ok("settings") -> admin_view.SettingsTab
    _ -> admin_view.UsersTab
  }

  let users = user.list_or_fail(ctx.app.db)

  ui.render(user: ctx.app.user, children: [
    admin_view.view(
      admin_view.Model(user: ctx.app.user, users: users, active_tab: active_tab),
      [],
    ),
  ])
}
