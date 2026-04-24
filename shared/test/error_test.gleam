import gleam/json
import gleeunit/should
import racklog/error

pub fn to_json_validation_error_test() {
  error.ValidationError(field: "username", message: "too short")
  |> error.to_json()
  |> json.to_string()
  |> should.equal(
    "{\"type\":\"validation\",\"field\":\"username\",\"message\":\"too short\"}",
  )
}

pub fn to_json_conflict_error_test() {
  error.ConflictError(field: "email", message: "already taken")
  |> error.to_json()
  |> json.to_string()
  |> should.equal(
    "{\"type\":\"conflict\",\"field\":\"email\",\"message\":\"already taken\"}",
  )
}

pub fn to_json_internal_server_error_test() {
  error.InternalServerError
  |> error.to_json()
  |> json.to_string()
  |> should.equal("{\"type\":\"internal_server_error\"}")
}

pub fn to_json_not_found_error_test() {
  error.NotFoundError
  |> error.to_json()
  |> json.to_string()
  |> should.equal("{\"type\":\"not_found\"}")
}

pub fn to_json_unauthorized_error_test() {
  error.UnauthorizedError
  |> error.to_json()
  |> json.to_string()
  |> should.equal("{\"type\":\"unauthorized\"}")
}

pub fn decoder_validation_error_test() {
  json.object([
    #("type", json.string("validation")),
    #("field", json.string("password")),
    #("message", json.string("too weak")),
  ])
  |> json.to_string
  |> json.parse(error.decoder())
  |> should.equal(
    Ok(error.ValidationError(field: "password", message: "too weak")),
  )
}

pub fn decoder_conflict_error_test() {
  json.object([
    #("type", json.string("conflict")),
    #("field", json.string("username")),
    #("message", json.string("exists")),
  ])
  |> json.to_string
  |> json.parse(error.decoder())
  |> should.equal(Ok(error.ConflictError(field: "username", message: "exists")))
}

pub fn decoder_internal_server_error_test() {
  json.object([#("type", json.string("internal_server_error"))])
  |> json.to_string
  |> json.parse(error.decoder())
  |> should.equal(Ok(error.InternalServerError))
}

pub fn decoder_not_found_test() {
  json.object([#("type", json.string("not_found"))])
  |> json.to_string
  |> json.parse(error.decoder())
  |> should.equal(Ok(error.NotFoundError))
}

pub fn decoder_unauthorized_test() {
  json.object([#("type", json.string("unauthorized"))])
  |> json.to_string
  |> json.parse(error.decoder())
  |> should.equal(Ok(error.UnauthorizedError))
}

pub fn decoder_invalid_type_test() {
  json.object([
    #("type", json.string("unknown_error_type")),
  ])
  |> json.to_string
  |> json.parse(error.decoder())
  |> should.be_error()
}

pub fn decoder_missing_type_test() {
  json.object([
    #("field", json.string("username")),
    #("message", json.string("too short")),
  ])
  |> json.to_string
  |> json.parse(error.decoder())
  |> should.be_error()
}

pub fn decoder_validation_missing_field_test() {
  json.object([
    #("type", json.string("validation")),
    #("message", json.string("too short")),
  ])
  |> json.to_string
  |> json.parse(error.decoder())
  |> should.be_error()
}

pub fn decoder_empty_object_test() {
  json.object([])
  |> json.to_string
  |> json.parse(error.decoder())
  |> should.be_error()
}

pub fn round_trip_validation_error_test() {
  let err = error.ValidationError(field: "email", message: "invalid format")

  err
  |> error.to_json
  |> json.to_string
  |> json.parse(error.decoder())
  |> should.equal(Ok(err))
}

pub fn round_trip_internal_server_error_test() {
  let err = error.InternalServerError

  err
  |> error.to_json
  |> json.to_string
  |> json.parse(error.decoder())
  |> should.equal(Ok(err))
}

pub fn to_string_unauthorized_error_test() {
  error.UnauthorizedError
  |> error.to_string
  |> should.equal("You are not authorised to do this.")
}

pub fn to_string_not_found_error_test() {
  error.NotFoundError
  |> error.to_string
  |> should.equal("The requested resource was not found.")
}

pub fn to_string_internal_server_error_test() {
  error.InternalServerError
  |> error.to_string
  |> should.equal("An unexpected error occurred.")
}

pub fn to_string_validation_error_test() {
  let message = "invalid format"
  error.ValidationError(field: "email", message:)
  |> error.to_string
  |> should.equal(message)
}

pub fn to_string_conflict_error_test() {
  let message = "invalid format"
  error.ConflictError(field: "email", message:)
  |> error.to_string
  |> should.equal(message)
}
