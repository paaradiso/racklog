import app/app.{type App}
import app/http/validators/exercise_store
import database/main/models/exercise/gen/exercise
import gleam/int
import gleam/json
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/response/response
import helpers

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#creating-controllers
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#views--responses
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#redirects

/// @get "/api/exercises"
pub fn index(ctx: Context(App)) -> Response {
  exercise.list_or_fail(ctx.app.db)
  |> json.array(exercise.encoder())
  |> response.json(200)
}

/// @get "/api/exercises/:id"
pub fn show(ctx: Context(App), id: String) -> Response {
  use parsed_id <- helpers.with_parsed_id(id)

  exercise.find_or_fail(ctx.app.db, parsed_id)
  |> exercise.encoder()
  |> response.json(200)
}

/// @post "/api/exercises"
pub fn store(ctx: Context(App)) -> Response {
  use validated <- exercise_store.validate(ctx)
  exercise.create_or_fail(ctx.app.db, name: validated.name)
  |> exercise.encoder()
  |> response.json(200)
}

/// @patch "/api/exercises/:id"
pub fn update(ctx: Context(App), id: String) -> Response {
  use parsed_id <- helpers.with_parsed_id(id)
  use validated <- exercise_store.validate(ctx)

  exercise.update_or_fail(ctx.app.db, validated.name, parsed_id)
  |> exercise.encoder()
  |> response.json(200)
}

/// @delete "/api/exercises/:id"
pub fn destroy(ctx: Context(App), id: String) -> Response {
  use parsed_id <- helpers.with_parsed_id(id)

  case exercise.delete(ctx.app.db, parsed_id) {
    Ok(exercise.DeleteExercise(_)) -> response.empty(204)
    Error(_) -> response.empty(404)
  }
}
