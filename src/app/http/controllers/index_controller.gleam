import app/app.{type App}
import compiled/loom/index
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

/// @get "/"
pub fn index(ctx: Context(App)) -> Response {
  let weight_types = weight_type.list_or_fail(ctx.app.db)
  let exercises = exercise.list_or_fail(ctx.app.db)
  let workouts = workout.list_or_fail(ctx.app.db)
  response.html(
    index.render(
      workouts: workouts,
      weight_types: weight_types,
      exercises: exercises,
    ),
    200,
  )
}
