import app/app.{type App}
import app/http/middleware/guest_user
import app/http/validators/store_login
import compiled/loom/auth/login
import database/main/models/user/gen/user
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/http/kernel.{type Middleware}
import glimr/response/redirect
import glimr/response/response
import glimr/session/session

/// Apply the guest middleware to the entire controller
pub fn middleware() -> List(Middleware(App)) {
  [guest_user.run]
}

/// @get "/login"
pub fn show(ctx: Context(App)) -> Response {
  response.html(login.render(ctx: ctx), 200)
}

/// @post "/login"
pub fn store(ctx: Context(App)) -> Response {
  use validated <- store_login.validate(ctx)

  let authenticated = {
    user.authenticate(
      session: ctx.session,
      pool: ctx.app.db,
      email: validated.email,
      password: validated.password,
    )
  }

  case authenticated {
    Ok(user) -> {
      let message = "Welcome back, " <> user.email

      session.flash(ctx.session, "message", message)

      redirect.to(guest_user.auth_redirect)
    }
    Error(_) -> {
      let message = "Invalid email or password"

      session.flash(ctx.session, "error", message)

      redirect.back(ctx)
    }
  }
}
