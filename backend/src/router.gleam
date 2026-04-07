import auth/auth
import exercise/exercise
import gleam/http.{Get, Post}
import middleware
import web.{type Context}
import weight_type/weight_type
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  let ctx = middleware.load_session(req, ctx)

  case req.method, wisp.path_segments(req) {
    Post, ["api", "login"] -> auth.login(req, ctx)
    _, ["api", "login"] -> wisp.method_not_allowed([Post])
    _, _ -> handle_authenticated(req, ctx)
  }
}

fn handle_authenticated(req: Request, ctx: Context) -> Response {
  use _user_id <- middleware.require_auth(ctx)

  case req.method, wisp.path_segments(req) {
    Get, ["api", "exercises"] -> exercise.list(req, ctx)
    _, ["api", "exercises"] -> wisp.method_not_allowed([Get])

    Get, ["api", "weight_types"] -> weight_type.list(req, ctx)
    _, ["api", "weight_types"] -> wisp.method_not_allowed([Get])

    Get, ["api", "me"] -> auth.me(req, ctx)
    _, ["api", "me"] -> wisp.method_not_allowed([Get])

    _, _ -> wisp.not_found()
  }
}
