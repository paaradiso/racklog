import gleam/json
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import web.{type Context}
import weight_type/sql.{type ListRow}
import wisp.{type Request, type Response}

fn list_row_to_json(row: ListRow) -> json.Json {
  json.object([
    #("id", json.int(row.id)),
    #("name", json.string(row.name)),
    #(
      "created_at",
      json.string(timestamp.to_rfc3339(row.created_at, duration.seconds(0))),
    ),
    #(
      "updated_at",
      json.string(timestamp.to_rfc3339(row.updated_at, duration.seconds(0))),
    ),
  ])
}

pub fn index(_req: Request, ctx: Context) -> Response {
  case sql.list(ctx.db) {
    Ok(returned) ->
      returned.rows
      |> json.array(list_row_to_json)
      |> json.to_string
      |> wisp.json_response(200)
    Error(err) -> {
      wisp.log_error(string.inspect(err))
      wisp.internal_server_error()
    }
  }
}

pub fn store(_req: Request) -> Response {
  wisp.json_response("{}", 201)
}

pub fn show(_req: Request, _id: String) -> Response {
  wisp.json_response("{}", 200)
}

pub fn update(_req: Request, _id: String) -> Response {
  wisp.json_response("{}", 200)
}

pub fn destroy(_req: Request, _id: String) -> Response {
  wisp.response(204)
}
