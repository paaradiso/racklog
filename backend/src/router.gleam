import exercise/exercise
import gleam/http.{Delete, Get, Patch, Post}
import web.{type Context}
import weight_type/weight_type
import wisp.{type Request, type Response}
import workout/workout

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  case wisp.path_segments(req) {
    ["api", "exercises"] ->
      case req.method {
        Get -> exercise.index(req)
        Post -> exercise.store(req)
        _ -> wisp.method_not_allowed([Get, Post])
      }
    ["api", "exercises", id] ->
      case req.method {
        Get -> exercise.show(req, id)
        Patch -> exercise.update(req, id)
        Delete -> exercise.destroy(req, id)
        _ -> wisp.method_not_allowed([Get, Patch, Delete])
      }

    ["api", "weight_types"] ->
      case req.method {
        Get -> weight_type.index(req)
        Post -> weight_type.store(req)
        _ -> wisp.method_not_allowed([Get, Post])
      }
    ["api", "weight_types", id] ->
      case req.method {
        Get -> weight_type.show(req, id)
        Patch -> weight_type.update(req, id)
        Delete -> weight_type.destroy(req, id)
        _ -> wisp.method_not_allowed([Get, Patch, Delete])
      }

    ["api", "workouts"] ->
      case req.method {
        Get -> workout.index(req)
        Post -> workout.store(req)
        _ -> wisp.method_not_allowed([Get, Post])
      }
    ["api", "workouts", id] ->
      case req.method {
        Get -> workout.show(req, id)
        Patch -> workout.update(req, id)
        Delete -> workout.destroy(req, id)
        _ -> wisp.method_not_allowed([Get, Patch, Delete])
      }

    _ -> wisp.not_found()
  }
}
