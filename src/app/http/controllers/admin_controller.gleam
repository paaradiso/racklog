import app/app.{type App}
import app/http/middleware/auth_user
import compiled/loom/admin
import database/main/models/user/gen/user
import gleam/option
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/http/middleware
import glimr/response/response

/// @get "/admin"
pub fn show(ctx: Context(App)) -> Response {
  use ctx <- middleware.apply([auth_user.run], ctx)
  let assert option.Some(user) = ctx.app.user

  let users = user.list_or_fail(ctx.app.db)

  response.html(admin.render(ctx: ctx, user: user, users: users), 200)
}
