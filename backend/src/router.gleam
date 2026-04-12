import auth/auth
import equipment/equipment
import exercise/exercise
import gleam/http.{Delete, Get, Patch, Post}
import middleware
import web.{type Context}
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

    Get, ["api", "equipment"] -> equipment.list(req, ctx)
    _, ["api", "equipment"] -> wisp.method_not_allowed([Get])

    Get, ["api", "me"] -> auth.me(req, ctx)
    _, ["api", "me"] -> wisp.method_not_allowed([Get])

    Get, ["api", "users"] -> auth.list_users(req, ctx)
    Post, ["api", "users"] -> auth.create_user(req, ctx)
    _, ["api", "users"] -> wisp.method_not_allowed([Get, Post])

    Delete, ["api", "users", id] -> auth.delete_user_by_id(req, ctx, id)
    Patch, ["api", "users", id] -> auth.update_user_by_id(req, ctx, id)
    _, ["api", "users", _id] -> wisp.method_not_allowed([Delete, Patch])

    _, _ -> wisp.not_found()
  }
}
