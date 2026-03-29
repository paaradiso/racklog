import gleam/int
import glimr/http/http.{type Response}
import glimr/response/response

pub fn with_parsed_id(id: String, next: fn(Int) -> Response) -> Response {
  case int.parse(id) {
    Ok(parsed_id) -> next(parsed_id)
    Error(_) -> response.empty(400)
  }
}
