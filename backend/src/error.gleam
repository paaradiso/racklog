import gleam/json
import racklog/error.{
  type AppError, ConflictError, InternalServerError, NotFoundError,
  UnauthorizedError, ValidationError,
}
import wisp

pub fn to_response(error: AppError) -> wisp.Response {
  let status = case error {
    ValidationError(..) -> 422
    ConflictError(..) -> 409
    NotFoundError -> 404
    UnauthorizedError -> 401
    InternalServerError -> 500
  }
  wisp.response(status)
  |> wisp.json_body(error |> error.to_json |> json.to_string)
}

pub fn validation(field: String, message: String) -> wisp.Response {
  ValidationError(field, message) |> to_response
}

pub fn conflict(field: String, message: String) -> wisp.Response {
  ConflictError(field, message) |> to_response
}

pub fn internal() -> wisp.Response {
  InternalServerError |> to_response
}

pub fn not_found() -> wisp.Response {
  NotFoundError |> to_response
}

pub fn unauthorized() -> wisp.Response {
  UnauthorizedError |> to_response
}
