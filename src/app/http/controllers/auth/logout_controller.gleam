import app/app.{type App}
import app/http/middleware/auth_user
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/http/middleware
import glimr/response/redirect
import glimr/session/session
import glimr_auth/auth

/// @post "/logout"
pub fn destroy(ctx: Context(App)) -> Response {
  use ctx <- middleware.apply([auth_user.run], ctx)

  auth.logout(ctx.session)

  session.flash(ctx.session, "message", "You have been logged out.")

  redirect.to(auth_user.guest_redirect)
}
