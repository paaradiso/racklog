import app/app.{type App}
import app/http/validators/weight_type_store
import database/main/models/weight_type/gen/weight_type
import gleam/int
import gleam/json
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/response/response
import helpers

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#creating-controllers
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#views--responses
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#redirects

/// @get "/api/weight_types"
pub fn index(ctx: Context(App)) -> Response {
  weight_type.list_or_fail(ctx.app.db)
  |> json.array(weight_type.encoder())
  |> response.json(200)
}

/// @get "/api/weight_types/:id"
pub fn show(ctx: Context(App), id: String) -> Response {
  use parsed_id <- helpers.with_parsed_id(id)

  weight_type.find_or_fail(ctx.app.db, parsed_id)
  |> weight_type.encoder()
  |> response.json(200)
}

/// @post "/api/weight_types"
pub fn store(ctx: Context(App)) -> Response {
  use validated <- weight_type_store.validate(ctx)
  weight_type.create_or_fail(ctx.app.db, name: validated.name)
  |> weight_type.encoder()
  |> response.json(200)
}

/// @patch "/api/weight_types/:id"
pub fn update(ctx: Context(App), id: String) -> Response {
  use parsed_id <- helpers.with_parsed_id(id)
  use validated <- weight_type_store.validate(ctx)

  weight_type.update_or_fail(ctx.app.db, validated.name, parsed_id)
  |> weight_type.encoder()
  |> response.json(200)
}

/// @delete "/api/weight_types/:id"
pub fn destroy(ctx: Context(App), id: String) -> Response {
  use parsed_id <- helpers.with_parsed_id(id)

  case weight_type.delete(ctx.app.db, parsed_id) {
    Ok(weight_type.DeleteWeightType(_)) -> response.empty(204)
    Error(_) -> response.empty(404)
  }
}
