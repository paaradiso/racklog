import app/app.{type App}
import app/http/validators/workout_store
import app/http/validators/workout_update_store
import database/main/models/workout/gen/workout
import gleam/json
import gleam/option
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/response/response
import helpers

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#creating-controllers
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#views--responses
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#redirects

/// @get "/api/workouts"
pub fn index(ctx: Context(App)) -> Response {
  workout.list_or_fail(ctx.app.db)
  |> json.array(workout.list_workout_encoder())
  |> response.json(200)
}

/// @get "/api/workouts/:id"
pub fn show(ctx: Context(App), id: String) -> Response {
  use id <- helpers.with_parsed_id(id)

  workout.find_or_fail(ctx.app.db, id)
  |> workout.find_workout_encoder()
  |> response.json(200)
}

/// @post "/api/workouts"
pub fn store(ctx: Context(App)) -> Response {
  use validated <- workout_store.validate(ctx)

  workout.create_or_fail(
    ctx.app.db,
    validated.exercise_id,
    validated.weight_type_id,
    validated.weight,
    validated.reps,
    validated.notes,
  )
  |> workout.create_workout_encoder()
  |> response.json(200)
}

/// @patch "/api/workouts/:id"
pub fn update(ctx: Context(App), id: String) -> Response {
  use id <- helpers.with_parsed_id(id)
  use validated <- workout_update_store.validate(ctx)
  let existing = workout.find_or_fail(ctx.app.db, id)

  workout.update_or_fail(
    ctx.app.db,
    validated.exercise_id |> option.unwrap(existing.exercise_id),
    validated.weight_type_id |> option.unwrap(existing.weight_type_id),
    validated.weight |> option.unwrap(existing.weight),
    validated.reps |> option.unwrap(existing.reps),
    validated.notes |> option.unwrap(existing.notes),
    id,
  )
  |> workout.update_workout_encoder()
  |> response.json(200)
}

/// @delete "/api/workouts/:id"
pub fn destroy(ctx: Context(App), id: String) -> Response {
  use id <- helpers.with_parsed_id(id)

  case workout.delete(ctx.app.db, id) {
    Ok(workout.DeleteWorkout(_)) -> response.empty(204)
    Error(_) -> response.empty(404)
  }
}
