//// This module contains the code to run the sql queries defined in
//// `./src/auth/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/time/timestamp.{type Timestamp}
import pog

/// A row you get from running the `create_session` query
/// defined in `./src/auth/sql/create_session.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateSessionRow {
  CreateSessionRow(
    id: String,
    user_id: Int,
    created_at: Timestamp,
    expires_at: Timestamp,
  )
}

/// Runs the `create_session` query
/// defined in `./src/auth/sql/create_session.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_session(
  db: pog.Connection,
  arg_1: String,
  arg_2: Int,
) -> Result(pog.Returned(CreateSessionRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.string)
    use user_id <- decode.field(1, decode.int)
    use created_at <- decode.field(2, pog.timestamp_decoder())
    use expires_at <- decode.field(3, pog.timestamp_decoder())
    decode.success(CreateSessionRow(id:, user_id:, created_at:, expires_at:))
  }

  "INSERT INTO session (id, user_id)
    VALUES ($1, $2)
RETURNING
    *;

"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_user` query
/// defined in `./src/auth/sql/create_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateUserRow {
  CreateUserRow(
    id: Int,
    email: String,
    hashed_password: String,
    created_at: Timestamp,
    updated_at: Timestamp,
    username: String,
    user_role: AppUserRole,
    preferred_unit: PreferredUnit,
  )
}

/// Runs the `create_user` query
/// defined in `./src/auth/sql/create_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_user(
  db: pog.Connection,
  arg_1: String,
  arg_2: String,
  arg_3: String,
  arg_4: AppUserRole,
) -> Result(pog.Returned(CreateUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use email <- decode.field(1, decode.string)
    use hashed_password <- decode.field(2, decode.string)
    use created_at <- decode.field(3, pog.timestamp_decoder())
    use updated_at <- decode.field(4, pog.timestamp_decoder())
    use username <- decode.field(5, decode.string)
    use user_role <- decode.field(6, app_user_role_decoder())
    use preferred_unit <- decode.field(7, preferred_unit_decoder())
    decode.success(CreateUserRow(
      id:,
      email:,
      hashed_password:,
      created_at:,
      updated_at:,
      username:,
      user_role:,
      preferred_unit:,
    ))
  }

  "INSERT INTO app_user (username, email, hashed_password, user_role)
    VALUES ($1, $2, $3, $4)
RETURNING
    *
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(app_user_role_encoder(arg_4))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `delete_session_by_id` query
/// defined in `./src/auth/sql/delete_session_by_id.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_session_by_id(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "DELETE FROM session
WHERE id = $1;

"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `delete_user_by_id` query
/// defined in `./src/auth/sql/delete_user_by_id.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_user_by_id(
  db: pog.Connection,
  arg_1: Int,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "DELETE FROM app_user
WHERE id = $1;

"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_current_user` query
/// defined in `./src/auth/sql/get_current_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetCurrentUserRow {
  GetCurrentUserRow(
    id: Int,
    email: String,
    hashed_password: String,
    created_at: Timestamp,
    updated_at: Timestamp,
    username: String,
    user_role: AppUserRole,
    preferred_unit: PreferredUnit,
  )
}

/// Runs the `get_current_user` query
/// defined in `./src/auth/sql/get_current_user.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_current_user(
  db: pog.Connection,
  arg_1: Int,
) -> Result(pog.Returned(GetCurrentUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use email <- decode.field(1, decode.string)
    use hashed_password <- decode.field(2, decode.string)
    use created_at <- decode.field(3, pog.timestamp_decoder())
    use updated_at <- decode.field(4, pog.timestamp_decoder())
    use username <- decode.field(5, decode.string)
    use user_role <- decode.field(6, app_user_role_decoder())
    use preferred_unit <- decode.field(7, preferred_unit_decoder())
    decode.success(GetCurrentUserRow(
      id:,
      email:,
      hashed_password:,
      created_at:,
      updated_at:,
      username:,
      user_role:,
      preferred_unit:,
    ))
  }

  "SELECT
    *
FROM
    app_user
WHERE
    id = $1;

"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_session_by_id` query
/// defined in `./src/auth/sql/get_session_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetSessionByIdRow {
  GetSessionByIdRow(
    id: String,
    user_id: Int,
    created_at: Timestamp,
    expires_at: Timestamp,
  )
}

/// Runs the `get_session_by_id` query
/// defined in `./src/auth/sql/get_session_by_id.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_session_by_id(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(GetSessionByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.string)
    use user_id <- decode.field(1, decode.int)
    use created_at <- decode.field(2, pog.timestamp_decoder())
    use expires_at <- decode.field(3, pog.timestamp_decoder())
    decode.success(GetSessionByIdRow(id:, user_id:, created_at:, expires_at:))
  }

  "SELECT
    *
FROM
    session
WHERE
    id = $1
    AND expires_at > now();

"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_user_by_email` query
/// defined in `./src/auth/sql/get_user_by_email.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetUserByEmailRow {
  GetUserByEmailRow(
    id: Int,
    email: String,
    hashed_password: String,
    created_at: Timestamp,
    updated_at: Timestamp,
    username: String,
    user_role: AppUserRole,
    preferred_unit: PreferredUnit,
  )
}

/// Runs the `get_user_by_email` query
/// defined in `./src/auth/sql/get_user_by_email.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_user_by_email(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(GetUserByEmailRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use email <- decode.field(1, decode.string)
    use hashed_password <- decode.field(2, decode.string)
    use created_at <- decode.field(3, pog.timestamp_decoder())
    use updated_at <- decode.field(4, pog.timestamp_decoder())
    use username <- decode.field(5, decode.string)
    use user_role <- decode.field(6, app_user_role_decoder())
    use preferred_unit <- decode.field(7, preferred_unit_decoder())
    decode.success(GetUserByEmailRow(
      id:,
      email:,
      hashed_password:,
      created_at:,
      updated_at:,
      username:,
      user_role:,
      preferred_unit:,
    ))
  }

  "SELECT
    *
FROM
    app_user
WHERE
    email = $1;

"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_user_by_username` query
/// defined in `./src/auth/sql/get_user_by_username.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetUserByUsernameRow {
  GetUserByUsernameRow(
    id: Int,
    email: String,
    hashed_password: String,
    created_at: Timestamp,
    updated_at: Timestamp,
    username: String,
    user_role: AppUserRole,
    preferred_unit: PreferredUnit,
  )
}

/// Runs the `get_user_by_username` query
/// defined in `./src/auth/sql/get_user_by_username.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_user_by_username(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(GetUserByUsernameRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use email <- decode.field(1, decode.string)
    use hashed_password <- decode.field(2, decode.string)
    use created_at <- decode.field(3, pog.timestamp_decoder())
    use updated_at <- decode.field(4, pog.timestamp_decoder())
    use username <- decode.field(5, decode.string)
    use user_role <- decode.field(6, app_user_role_decoder())
    use preferred_unit <- decode.field(7, preferred_unit_decoder())
    decode.success(GetUserByUsernameRow(
      id:,
      email:,
      hashed_password:,
      created_at:,
      updated_at:,
      username:,
      user_role:,
      preferred_unit:,
    ))
  }

  "SELECT
    *
FROM
    app_user
WHERE
    username = $1;

"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_users` query
/// defined in `./src/auth/sql/list_users.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListUsersRow {
  ListUsersRow(
    id: Int,
    email: String,
    hashed_password: String,
    created_at: Timestamp,
    updated_at: Timestamp,
    username: String,
    user_role: AppUserRole,
    preferred_unit: PreferredUnit,
  )
}

/// Runs the `list_users` query
/// defined in `./src/auth/sql/list_users.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_users(
  db: pog.Connection,
) -> Result(pog.Returned(ListUsersRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use email <- decode.field(1, decode.string)
    use hashed_password <- decode.field(2, decode.string)
    use created_at <- decode.field(3, pog.timestamp_decoder())
    use updated_at <- decode.field(4, pog.timestamp_decoder())
    use username <- decode.field(5, decode.string)
    use user_role <- decode.field(6, app_user_role_decoder())
    use preferred_unit <- decode.field(7, preferred_unit_decoder())
    decode.success(ListUsersRow(
      id:,
      email:,
      hashed_password:,
      created_at:,
      updated_at:,
      username:,
      user_role:,
      preferred_unit:,
    ))
  }

  "SELECT 
    * 
FROM 
    app_user;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_user_by_id` query
/// defined in `./src/auth/sql/update_user_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateUserByIdRow {
  UpdateUserByIdRow(
    id: Int,
    email: String,
    hashed_password: String,
    created_at: Timestamp,
    updated_at: Timestamp,
    username: String,
    user_role: AppUserRole,
    preferred_unit: PreferredUnit,
  )
}

/// Runs the `update_user_by_id` query
/// defined in `./src/auth/sql/update_user_by_id.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_user_by_id(
  db: pog.Connection,
  arg_1: String,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: Int,
) -> Result(pog.Returned(UpdateUserByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use email <- decode.field(1, decode.string)
    use hashed_password <- decode.field(2, decode.string)
    use created_at <- decode.field(3, pog.timestamp_decoder())
    use updated_at <- decode.field(4, pog.timestamp_decoder())
    use username <- decode.field(5, decode.string)
    use user_role <- decode.field(6, app_user_role_decoder())
    use preferred_unit <- decode.field(7, preferred_unit_decoder())
    decode.success(UpdateUserByIdRow(
      id:,
      email:,
      hashed_password:,
      created_at:,
      updated_at:,
      username:,
      user_role:,
      preferred_unit:,
    ))
  }

  "UPDATE
    app_user
SET
    username = COALESCE(NULLIF ($1, ''), username),
    email = COALESCE(NULLIF ($2, ''), email),
    hashed_password = COALESCE(NULLIF ($3, ''), hashed_password),
    user_role = COALESCE(NULLIF ($4::text, '')::app_user_role, user_role),
    preferred_unit = COALESCE(NULLIF ($5::text, '')::preferred_unit, preferred_unit)
WHERE
    id = $6
RETURNING
    *;

"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.int(arg_6))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Enums -------------------------------------------------------------------

/// Corresponds to the Postgres `app_user_role` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type AppUserRole {
  Admin
  User
}

fn app_user_role_decoder() -> decode.Decoder(AppUserRole) {
  use app_user_role <- decode.then(decode.string)
  case app_user_role {
    "admin" -> decode.success(Admin)
    "user" -> decode.success(User)
    _ -> decode.failure(Admin, "AppUserRole")
  }
}

fn app_user_role_encoder(app_user_role) -> pog.Value {
  case app_user_role {
    Admin -> "admin"
    User -> "user"
  }
  |> pog.text
}/// Corresponds to the Postgres `preferred_unit` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type PreferredUnit {
  Lb
  Kg
}

fn preferred_unit_decoder() -> decode.Decoder(PreferredUnit) {
  use preferred_unit <- decode.then(decode.string)
  case preferred_unit {
    "lb" -> decode.success(Lb)
    "kg" -> decode.success(Kg)
    _ -> decode.failure(Lb, "PreferredUnit")
  }
}
