import app/app.{type App}
import database/main/models/weight_type/gen/weight_type
import gleam/json
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/response/response

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#creating-controllers
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#views--responses
// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#redirects

/// @get "/api/weight_types"
pub fn index(ctx: Context(App)) -> Response {
  weight_type.list_or_fail(ctx.app.db)
  |> json.array(weight_type.encoder())
  |> response.json(200)
}

/// @get "/api/weight_types/:weight_type"
pub fn show(ctx: Context(App), weight_type: String) -> Response {
  todo
}

/// @post "/api/weight_types"
pub fn store(ctx: Context(App)) -> Response {
  todo
}

/// @get "/api/weight_types/:weight_type/edit"
pub fn edit(ctx: Context(App), weight_type: String) -> Response {
  todo
}

/// @patch "/api/weight_types/:weight_type"
pub fn update(ctx: Context(App), weight_type: String) -> Response {
  todo
}

/// @delete "/api/weight_types/:weight_type"
pub fn destroy(ctx: Context(App), weight_type: String) -> Response {
  todo
}
