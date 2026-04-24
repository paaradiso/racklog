import error
import gleam/json
import gleeunit/should
import racklog/error as shared_error
import wisp

fn body_to_string(response: wisp.Response) -> String {
  let assert wisp.Text(string) = response.body
  string
}

pub fn to_response_validation_error_status_test() {
  shared_error.ValidationError(field: "username", message: "too short")
  |> error.to_response()
  |> fn(r) { r.status }
  |> should.equal(422)
}

pub fn to_response_conflict_error_status_test() {
  shared_error.ConflictError(field: "email", message: "already taken")
  |> error.to_response()
  |> fn(r) { r.status }
  |> should.equal(409)
}

pub fn to_response_not_found_status_test() {
  shared_error.NotFoundError
  |> error.to_response()
  |> fn(r) { r.status }
  |> should.equal(404)
}

pub fn to_response_unauthorized_status_test() {
  shared_error.UnauthorizedError
  |> error.to_response()
  |> fn(r) { r.status }
  |> should.equal(401)
}

pub fn to_response_internal_status_test() {
  shared_error.InternalServerError
  |> error.to_response()
  |> fn(r) { r.status }
  |> should.equal(500)
}

pub fn to_response_validation_error_body_test() {
  shared_error.ValidationError(field: "username", message: "too short")
  |> error.to_response()
  |> body_to_string
  |> json.parse(shared_error.decoder())
  |> should.equal(
    Ok(shared_error.ValidationError(field: "username", message: "too short")),
  )
}

pub fn to_response_conflict_error_body_test() {
  shared_error.ConflictError(field: "email", message: "already taken")
  |> error.to_response()
  |> body_to_string
  |> json.parse(shared_error.decoder())
  |> should.equal(
    Ok(shared_error.ConflictError(field: "email", message: "already taken")),
  )
}

pub fn to_response_not_found_body_test() {
  shared_error.NotFoundError
  |> error.to_response()
  |> body_to_string
  |> json.parse(shared_error.decoder())
  |> should.equal(Ok(shared_error.NotFoundError))
}

pub fn to_response_unauthorized_body_test() {
  shared_error.UnauthorizedError
  |> error.to_response()
  |> body_to_string
  |> json.parse(shared_error.decoder())
  |> should.equal(Ok(shared_error.UnauthorizedError))
}

pub fn to_response_internal_error_body_test() {
  shared_error.InternalServerError
  |> error.to_response()
  |> body_to_string
  |> json.parse(shared_error.decoder())
  |> should.equal(Ok(shared_error.InternalServerError))
}

pub fn validation_wrapper_test() {
  error.validation("password", "too weak")
  |> fn(r) { r.status }
  |> should.equal(422)
}

pub fn conflict_wrapper_test() {
  error.conflict("username", "already exists")
  |> fn(r) { r.status }
  |> should.equal(409)
}

pub fn not_found_wrapper_test() {
  error.not_found()
  |> fn(r) { r.status }
  |> should.equal(404)
}

pub fn unauthorized_wrapper_test() {
  error.unauthorized()
  |> fn(r) { r.status }
  |> should.equal(401)
}

pub fn internal_wrapper_test() {
  error.internal()
  |> fn(r) { r.status }
  |> should.equal(500)
}

pub fn validation_wrapper_matches_to_response_test() {
  let direct =
    shared_error.ValidationError(field: "email", message: "invalid")
    |> error.to_response()

  let wrapper = error.validation("email", "invalid")

  direct.status |> should.equal(wrapper.status)
  body_to_string(direct) |> should.equal(body_to_string(wrapper))
}

pub fn conflict_wrapper_matches_to_response_test() {
  let direct =
    shared_error.ConflictError(field: "email", message: "taken")
    |> error.to_response()

  let wrapper = error.conflict("email", "taken")

  direct.status |> should.equal(wrapper.status)

  direct.status |> should.equal(wrapper.status)
  body_to_string(direct) |> should.equal(body_to_string(wrapper))
}
