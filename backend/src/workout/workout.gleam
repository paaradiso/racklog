import error
import gleam/json
import middleware
import pog.{Returned}
import racklog/workout
import web.{type Context}
import wisp.{type Request, type Response}
import workout/map
import workout/sql

pub fn list(_req: Request, ctx: Context) -> Response {
  use user <- middleware.require_authentication(ctx)
  case sql.list_workouts_by_user_id(ctx.db, user.id) {
    Ok(Returned(rows: workouts, ..)) -> {
      workouts
      |> json.array(fn(workout) {
        map.row_to_dto(
          workout.id,
          workout.user_id,
          workout.name,
          workout.started_at,
          workout.ended_at,
          workout.notes,
          workout.created_at,
          workout.updated_at,
        )
        |> workout.to_json
      })
      |> json.to_string
      |> wisp.json_response(200)
    }
    Error(_) -> error.internal()
  }
}
