import app/app.{type App}
import compiled/loom/exercises
import compiled/loom/weight_type_index
import database/main/models/exercise/gen/exercise
import database/main/models/weight_type/gen/weight_type
import database/main/models/workout/gen/workout
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/response/response
import helpers

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#creating-controllers
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#views--responses
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#redirects

/// @get "/exercises"
pub fn index(ctx: Context(App)) -> Response {
  let exercises = exercise.list_or_fail(ctx.app.db)
  response.html(exercises.render(exercises), 200)
}
