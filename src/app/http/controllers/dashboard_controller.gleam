import app/app.{type App}
import app/http/middleware/auth_user
import compiled/loom/dashboard
import gleam/option
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/http/middleware
import glimr/response/response

/// @get "/dashboard"
pub fn show(ctx: Context(App)) -> Response {
  use ctx <- middleware.apply([auth_user.run], ctx)

  let assert option.Some(user) = ctx.app.user

  response.html(dashboard.render(ctx: ctx, user: user), 200)
}
