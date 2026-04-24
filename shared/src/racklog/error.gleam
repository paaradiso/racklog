import gleam/dynamic/decode
import gleam/json

pub type AppError {
  ValidationError(field: String, message: String)
  ConflictError(field: String, message: String)
  InternalServerError
  NotFoundError
  UnauthorizedError
}

pub fn to_json(error: AppError) -> json.Json {
  case error {
    ValidationError(field, message) ->
      json.object([
        #("type", json.string("validation")),
        #("field", json.string(field)),
        #("message", json.string(message)),
      ])

    ConflictError(field, message) ->
      json.object([
        #("type", json.string("conflict")),
        #("field", json.string(field)),
        #("message", json.string(message)),
      ])

    InternalServerError ->
      json.object([#("type", json.string("internal_server_error"))])

    NotFoundError -> json.object([#("type", json.string("not_found"))])

    UnauthorizedError -> json.object([#("type", json.string("unauthorized"))])
  }
}

pub fn decoder() -> decode.Decoder(AppError) {
  use type_ <- decode.field("type", decode.string)

  case type_ {
    "validation" -> {
      use field <- decode.field("field", decode.string)
      use message <- decode.field("message", decode.string)
      decode.success(ValidationError(field, message))
    }

    "conflict" -> {
      use field <- decode.field("field", decode.string)
      use message <- decode.field("message", decode.string)
      decode.success(ConflictError(field, message))
    }

    "internal_server_error" -> decode.success(InternalServerError)

    "not_found" -> decode.success(NotFoundError)

    "unauthorized" -> decode.success(UnauthorizedError)

    _ -> decode.failure(InternalServerError, "AppError type")
  }
}

pub fn to_string(err: AppError) -> String {
  case err {
    UnauthorizedError -> "You are not authorised to do this."
    NotFoundError -> "The requested resource was not found."
    InternalServerError -> "An unexpected error occurred."
    ValidationError(_, message) -> message
    ConflictError(_, message) -> message
  }
}
