import gleam/dynamic/decode
import gleam/json
import gleam/string
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}

pub type AppUserRole {
  AdminRole
  UserRole
}

pub type PreferredUnit {
  Kg
  Lb
}

pub type UserDto {
  UserDto(
    id: Int,
    username: String,
    email: String,
    role: AppUserRole,
    preferred_unit: PreferredUnit,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

pub fn role_decoder() -> decode.Decoder(AppUserRole) {
  use role_str <- decode.then(decode.string)
  case role_str {
    "admin" -> decode.success(AdminRole)
    "user" -> decode.success(UserRole)
    _ -> decode.failure(UserRole, "admin or user")
  }
}

pub fn preferred_unit_decoder() -> decode.Decoder(PreferredUnit) {
  use preferred_unit_str <- decode.then(decode.string)
  case preferred_unit_str {
    "kg" -> decode.success(Kg)
    "lb" -> decode.success(Lb)
    _ -> decode.failure(Kg, "kg or lb")
  }
}

pub fn timestamp_decoder() -> decode.Decoder(Timestamp) {
  use timestamp_string <- decode.then(decode.string)

  case timestamp.parse_rfc3339(timestamp_string) {
    Ok(time) -> decode.success(time)
    Error(_) -> {
      timestamp.system_time()
      |> decode.failure("RFC 3339 formatted timestamp")
    }
  }
}

pub fn decoder() -> decode.Decoder(UserDto) {
  use id <- decode.field("id", decode.int)
  use username <- decode.field("username", decode.string)
  use email <- decode.field("email", decode.string)
  use role <- decode.field("role", role_decoder())
  use preferred_unit <- decode.field("preferred_unit", preferred_unit_decoder())
  use created_at <- decode.field("created_at", timestamp_decoder())
  use updated_at <- decode.field("updated_at", timestamp_decoder())
  decode.success(UserDto(
    id:,
    username:,
    email:,
    role:,
    preferred_unit:,
    created_at:,
    updated_at:,
  ))
}

pub fn list_decoder() -> decode.Decoder(List(UserDto)) {
  decode.list(decoder())
}

pub fn role_to_string(role: AppUserRole) -> String {
  case role {
    AdminRole -> "admin"
    UserRole -> "user"
  }
}

pub fn preferred_unit_to_string(preferred_unit: PreferredUnit) -> String {
  case preferred_unit {
    Kg -> "kg"
    Lb -> "lb"
  }
}

pub fn to_json(user: UserDto) -> json.Json {
  json.object([
    #("id", json.int(user.id)),
    #("username", json.string(user.username)),
    #("email", json.string(user.email)),
    #("role", json.string(role_to_string(user.role))),
    #(
      "preferred_unit",
      json.string(preferred_unit_to_string(user.preferred_unit)),
    ),
    #(
      "created_at",
      json.string(timestamp.to_rfc3339(user.created_at, duration.seconds(0))),
    ),
    #(
      "updated_at",
      json.string(timestamp.to_rfc3339(user.updated_at, duration.seconds(0))),
    ),
  ])
}

pub type PasswordValidationError {
  PasswordTooShort
  PasswordTooWeak
}

pub const minimum_password_length = 8

pub fn validate_password(
  password: String,
) -> Result(Nil, PasswordValidationError) {
  case string.length(password) > minimum_password_length {
    False -> Error(PasswordTooShort)
    // TODO: use zxcvbn to check strength
    True -> Ok(Nil)
  }
}
