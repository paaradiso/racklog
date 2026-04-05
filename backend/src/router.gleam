import controllers/exercise_controller
import controllers/weight_type_controller
import controllers/workout_controller
import gleam/http.{Delete, Get, Patch, Post}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  case wisp.path_segments(req) {
    ["api", "exercises"] ->
      case req.method {
        Get -> exercise_controller.index(req)
        Post -> exercise_controller.store(req)
        _ -> wisp.method_not_allowed([Get, Post])
      }
    ["api", "exercises", id] ->
      case req.method {
        Get -> exercise_controller.show(req, id)
        Patch -> exercise_controller.update(req, id)
        Delete -> exercise_controller.destroy(req, id)
        _ -> wisp.method_not_allowed([Get, Patch, Delete])
      }

    ["api", "weight_types"] ->
      case req.method {
        Get -> weight_type_controller.index(req)
        Post -> weight_type_controller.store(req)
        _ -> wisp.method_not_allowed([Get, Post])
      }
    ["api", "weight_types", id] ->
      case req.method {
        Get -> weight_type_controller.show(req, id)
        Patch -> weight_type_controller.update(req, id)
        Delete -> weight_type_controller.destroy(req, id)
        _ -> wisp.method_not_allowed([Get, Patch, Delete])
      }

    ["api", "workouts"] ->
      case req.method {
        Get -> workout_controller.index(req)
        Post -> workout_controller.store(req)
        _ -> wisp.method_not_allowed([Get, Post])
      }
    ["api", "workouts", id] ->
      case req.method {
        Get -> workout_controller.show(req, id)
        Patch -> workout_controller.update(req, id)
        Delete -> workout_controller.destroy(req, id)
        _ -> wisp.method_not_allowed([Get, Patch, Delete])
      }

    _ -> wisp.not_found()
  }
}
