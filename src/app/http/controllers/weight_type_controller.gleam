import app/app.{type App}
import compiled/loom/weight_type as weight_type_view
import compiled/loom/weight_type_index
import database/main/models/weight_type/gen/weight_type
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/response/response
import helpers

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#creating-controllers
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#views--responses
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#redirects

/// @get "/weight_types"
pub fn index(ctx: Context(App)) -> Response {
  let weight_types = weight_type.list_or_fail(ctx.app.db)
  response.html(weight_type_index.render(weight_types), 200)
}

/// @get "/weight_types/:id"
pub fn show(ctx: Context(App), id: String) -> Response {
  use id <- helpers.with_parsed_id(id)

  let weight_type = weight_type.find_or_fail(ctx.app.db, id)
  response.html(weight_type_view.render(weight_type), 200)
}
