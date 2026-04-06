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

  case wisp.path_segments(req) {
    ["api", "exercises"] ->
      case req.method {
        Get -> exercise.list(req, ctx)
        _ -> wisp.method_not_allowed([Get])
      }
    ["api", "weight_types"] ->
      case req.method {
        Get -> weight_type.list(req, ctx)
        _ -> wisp.method_not_allowed([Get])
      }
    ["api", "login"] ->
      case req.method {
        Post -> auth.login(req, ctx)
        _ -> wisp.method_not_allowed([Post])
      }
    ["api", "me"] ->
      case req.method {
        Get -> auth.me(req, ctx)
        _ -> wisp.method_not_allowed([Get])
      }

    _ -> wisp.not_found()
  }
}
