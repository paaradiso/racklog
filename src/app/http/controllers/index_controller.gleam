import app/app.{type App}
import compiled/loom/index
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/response/response

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#creating-controllers
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#views--responses
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#redirects

/// @get "/"
pub fn index(_ctx: Context(App)) -> Response {
  response.html(index.render(), 200)
}
