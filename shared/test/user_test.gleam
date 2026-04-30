import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/string
import gleam/time/timestamp
import gleeunit/should
import racklog/user
import racklog/util

pub fn role_decoder_admin_test() {
  decode.run(dynamic.string("admin"), user.role_decoder())
  |> should.equal(Ok(user.AdminRole))
}

pub fn role_decoder_user_test() {
  decode.run(dynamic.string("user"), user.role_decoder())
  |> should.equal(Ok(user.UserRole))
}

pub fn role_decoder_invalid_test() {
  decode.run(dynamic.string("invalid"), user.role_decoder())
  |> should.be_error
}

pub fn role_decoder_non_string_test() {
  decode.run(dynamic.int(123), user.role_decoder())
  |> should.be_error()
}

pub fn role_to_string_admin_test() {
  user.role_to_string(user.AdminRole)
  |> should.equal("admin")
}

pub fn role_to_string_user_test() {
  user.role_to_string(user.UserRole)
  |> should.equal("user")
}

pub fn preferred_unit_decoder_kg_test() {
  decode.run(dynamic.string("kg"), user.preferred_unit_decoder())
  |> should.equal(Ok(user.Kg))
}

pub fn preferred_unit_decoder_lb_test() {
  decode.run(dynamic.string("lb"), user.preferred_unit_decoder())
  |> should.equal(Ok(user.Lb))
}

pub fn preferred_unit_decoder_invalid_test() {
  decode.run(dynamic.string("invalid"), user.preferred_unit_decoder())
  |> should.be_error
}

pub fn preferred_unit_decoder_non_string_test() {
  decode.run(dynamic.int(123), user.preferred_unit_decoder())
  |> should.be_error()
}

pub fn preferred_unit_to_string_kg_test() {
  user.preferred_unit_to_string(user.Kg)
  |> should.equal("kg")
}

pub fn preferred_unit_to_string_lb_test() {
  user.preferred_unit_to_string(user.Lb)
  |> should.equal("lb")
}

pub fn password_validation_error_to_string_too_short_test() {
  user.password_validation_error_to_string(user.PasswordTooShort)
  |> should.equal(
    "Password must be at least "
    <> int.to_string(user.minimum_password_length)
    <> " characters.",
  )
}

pub fn password_validation_error_to_string_too_weak_test() {
  user.password_validation_error_to_string(user.PasswordTooWeak)
  |> should.equal("Password is too weak.")
}

pub fn validate_password_below_minimum_length_test() {
  string.repeat("a", user.minimum_password_length - 1)
  |> user.validate_password
  |> should.equal(Error(user.PasswordTooShort))
}

pub fn validate_password_is_minimum_length_test() {
  string.repeat("a", user.minimum_password_length)
  |> user.validate_password
  |> should.be_ok
}

pub fn validate_password_above_minimum_length_test() {
  string.repeat("a", user.minimum_password_length + 1)
  |> user.validate_password
  |> should.be_ok
}

pub fn form_field_to_string_username_test() {
  user.form_field_to_string(user.UsernameField)
  |> should.equal("username")
}

pub fn form_field_to_string_email_test() {
  user.form_field_to_string(user.EmailField)
  |> should.equal("email")
}

pub fn form_field_to_string_password_test() {
  user.form_field_to_string(user.PasswordField)
  |> should.equal("password")
}

pub fn form_field_to_string_confirm_password_test() {
  user.form_field_to_string(user.ConfirmPasswordField)
  |> should.equal("confirm_password")
}

pub fn form_field_to_string_current_password_test() {
  user.form_field_to_string(user.CurrentPasswordField)
  |> should.equal("current_password")
}

pub fn form_field_to_string_role_test() {
  user.form_field_to_string(user.RoleField)
  |> should.equal("role")
}

pub fn form_field_to_string_preferred_unit_test() {
  user.form_field_to_string(user.PreferredUnitField)
  |> should.equal("preferred_unit")
}

pub fn form_field_decoder_username_test() {
  decode.run(dynamic.string("username"), user.form_field_decoder())
  |> should.equal(Ok(user.UsernameField))
}

pub fn form_field_decoder_email_test() {
  decode.run(dynamic.string("email"), user.form_field_decoder())
  |> should.equal(Ok(user.EmailField))
}

pub fn form_field_decoder_password_test() {
  decode.run(dynamic.string("password"), user.form_field_decoder())
  |> should.equal(Ok(user.PasswordField))
}

pub fn form_field_decoder_confirm_password_test() {
  decode.run(dynamic.string("confirm_password"), user.form_field_decoder())
  |> should.equal(Ok(user.ConfirmPasswordField))
}

pub fn form_field_decoder_current_password_test() {
  decode.run(dynamic.string("current_password"), user.form_field_decoder())
  |> should.equal(Ok(user.CurrentPasswordField))
}

pub fn form_field_decoder_role_test() {
  decode.run(dynamic.string("role"), user.form_field_decoder())
  |> should.equal(Ok(user.RoleField))
}

pub fn form_field_decoder_preferred_unit_test() {
  decode.run(dynamic.string("preferred_unit"), user.form_field_decoder())
  |> should.equal(Ok(user.PreferredUnitField))
}

pub fn form_field_decoder_invalid_test() {
  decode.run(dynamic.string("invalid"), user.form_field_decoder())
  |> should.be_error()
}

pub fn form_field_decoder_non_string_test() {
  decode.run(dynamic.int(123), user.form_field_decoder())
  |> should.be_error()
}

fn create_user() -> user.UserDto {
  user.UserDto(
    id: 1,
    username: "john",
    email: "john@googol.biz",
    role: user.UserRole,
    preferred_unit: user.Kg,
    created_at: timestamp.from_unix_seconds(1_776_941_287),
    updated_at: timestamp.from_unix_seconds(1_776_941_290),
  )
}

pub fn timestamp_decoder_valid_no_offset_test() {
  json.parse("\"2026-04-23T00:00:00Z\"", util.timestamp_decoder())
  |> should.be_ok()
}

pub fn timestamp_decoder_valid_with_offset_test() {
  json.parse("\"2026-04-23T00:00:00+10:00\"", util.timestamp_decoder())
  |> should.be_ok()
}

pub fn timestamp_decoder_invalid_string_test() {
  json.parse("\"notatimestamp\"", util.timestamp_decoder())
  |> should.be_error()
}

pub fn timestamp_decoder_non_string_test() {
  json.parse("123", util.timestamp_decoder())
  |> should.be_error()
}

pub fn timestamp_decoder_empty_string_test() {
  json.parse("\"\"", util.timestamp_decoder())
  |> should.be_error()
}

fn valid_user_json() {
  json.object([
    #("id", json.int(1)),
    #("username", json.string("john")),
    #("email", json.string("john@googol.biz")),
    #("role", json.string("user")),
    #("preferred_unit", json.string("kg")),
    #("created_at", json.string("2026-04-23T00:00:00Z")),
    #("updated_at", json.string("2026-04-23T00:00:00Z")),
  ])
}

pub fn decoder_valid_test() {
  valid_user_json()
  |> json.to_string
  |> json.parse(user.decoder())
  |> should.be_ok()
}

pub fn decoder_invalid_role_test() {
  json.object([
    #("id", json.int(1)),
    #("username", json.string("john")),
    #("email", json.string("john@googol.biz")),
    #("role", json.string("invalid")),
    #("preferred_unit", json.string("kg")),
    #("created_at", json.string("2026-04-23T00:00:00Z")),
    #("updated_at", json.string("2026-04-23T00:00:00Z")),
  ])
  |> json.to_string
  |> json.parse(user.decoder())
  |> should.be_error()
}

pub fn decoder_invalid_preferred_unit_test() {
  json.object([
    #("id", json.int(1)),
    #("username", json.string("john")),
    #("email", json.string("john@googol.biz")),
    #("role", json.string("user")),
    #("preferred_unit", json.string("invalid")),
    #("created_at", json.string("2026-04-23T00:00:00Z")),
    #("updated_at", json.string("2026-04-23T00:00:00Z")),
  ])
  |> json.to_string
  |> json.parse(user.decoder())
  |> should.be_error()
}

pub fn decoder_invalid_created_at_test() {
  json.object([
    #("id", json.int(1)),
    #("username", json.string("john")),
    #("email", json.string("john@googol.biz")),
    #("role", json.string("user")),
    #("preferred_unit", json.string("kg")),
    #("created_at", json.string("invalid")),
    #("updated_at", json.string("2026-04-23T00:00:00Z")),
  ])
  |> json.to_string
  |> json.parse(user.decoder())
  |> should.be_error()
}

pub fn decoder_invalid_updated_at_test() {
  json.object([
    #("id", json.int(1)),
    #("username", json.string("john")),
    #("email", json.string("john@googol.biz")),
    #("role", json.string("user")),
    #("preferred_unit", json.string("kg")),
    #("created_at", json.string("2026-04-23T00:00:00Z")),
    #("updated_at", json.string("invalid")),
  ])
  |> json.to_string
  |> json.parse(user.decoder())
  |> should.be_error()
}

pub fn decoder_id_wrong_type_test() {
  json.object([
    #("id", json.string("one")),
    #("username", json.string("john")),
    #("email", json.string("john@googol.biz")),
    #("role", json.string("user")),
    #("preferred_unit", json.string("kg")),
    #("created_at", json.string("2026-04-23T00:00:00Z")),
    #("updated_at", json.string("2026-04-23T00:00:00Z")),
  ])
  |> json.to_string
  |> json.parse(user.decoder())
  |> should.be_error()
}

pub fn decoder_missing_field_test() {
  json.object([
    #("username", json.string("john")),
    #("email", json.string("john@googol.biz")),
    #("role", json.string("user")),
    #("preferred_unit", json.string("kg")),
    #("created_at", json.string("2026-04-23T00:00:00Z")),
    #("updated_at", json.string("2026-04-23T00:00:00Z")),
  ])
  |> json.to_string
  |> json.parse(user.decoder())
  |> should.be_error()
}

pub fn decoder_empty_object_test() {
  json.object([])
  |> json.to_string
  |> json.parse(user.decoder())
  |> should.be_error()
}

pub fn dto_round_trip_test() {
  let u = create_user()
  u
  |> user.to_json
  |> json.to_string
  |> json.parse(user.decoder())
  |> should.equal(Ok(u))
}

pub fn dto_admin_role_round_trip_test() {
  let u = user.UserDto(..create_user(), role: user.AdminRole)
  u
  |> user.to_json
  |> json.to_string
  |> json.parse(user.decoder())
  |> should.equal(Ok(u))
}

pub fn dto_lb_unit_round_trip_test() {
  let u = user.UserDto(..create_user(), preferred_unit: user.Lb)
  u
  |> user.to_json
  |> json.to_string
  |> json.parse(user.decoder())
  |> should.equal(Ok(u))
}

pub fn list_decoder_single_test() {
  let u = create_user()
  json.preprocessed_array([user.to_json(u)])
  |> json.to_string
  |> json.parse(user.list_decoder())
  |> should.equal(Ok([u]))
}

pub fn list_decoder_empty_test() {
  json.preprocessed_array([])
  |> json.to_string
  |> json.parse(user.list_decoder())
  |> should.equal(Ok([]))
}

pub fn list_decoder_multiple_test() {
  let u = create_user()
  json.preprocessed_array([user.to_json(u), user.to_json(u)])
  |> json.to_string
  |> json.parse(user.list_decoder())
  |> should.equal(Ok([u, u]))
}

pub fn list_decoder_invalid_item_test() {
  json.preprocessed_array([valid_user_json(), json.object([])])
  |> json.to_string
  |> json.parse(user.list_decoder())
  |> should.be_error()
}
