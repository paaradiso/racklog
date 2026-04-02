import app/app.{type App}
import compiled/loom/exercises
import database/main/models/exercise/gen/exercise
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/response/response

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#creating-controllers
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#views--responses
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#redirects

/// @get "/exercises"
pub fn index(ctx: Context(App)) -> Response {
  let exercises = exercise.list_or_fail(ctx.app.db)
  response.html(exercises.render(exercises), 200)
}
