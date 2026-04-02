import app/app.{type App}
import app/http/middleware/auth_user
import compiled/loom/workout_index
import database/main/models/workout/gen/workout
import gleam/option
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/http/middleware
import glimr/response/response
import helpers

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#creating-controllers
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#views--responses
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#redirects

/// @get "/workouts"
pub fn index(ctx: Context(App)) -> Response {
  use ctx <- middleware.apply([auth_user.run], ctx)

  let assert option.Some(user) = ctx.app.user

  let workouts = workout.list_for_user_or_fail(ctx.app.db, user.id)
  response.html(workout_index.render(user, workouts), 200)
}
