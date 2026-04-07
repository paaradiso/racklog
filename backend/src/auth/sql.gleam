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
) -> Result(pog.Returned(CreateUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use email <- decode.field(1, decode.string)
    use hashed_password <- decode.field(2, decode.string)
    use created_at <- decode.field(3, pog.timestamp_decoder())
    use updated_at <- decode.field(4, pog.timestamp_decoder())
    decode.success(CreateUserRow(
      id:,
      email:,
      hashed_password:,
      created_at:,
      updated_at:,
    ))
  }

  "INSERT INTO app_user (email, hashed_password)
    VALUES ($1, $2)
RETURNING
    *
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
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
  GetCurrentUserRow(id: Int, email: String)
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
    decode.success(GetCurrentUserRow(id:, email:))
  }

  "SELECT
    id,
    email
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
    decode.success(GetUserByEmailRow(
      id:,
      email:,
      hashed_password:,
      created_at:,
      updated_at:,
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
    decode.success(ListUsersRow(
      id:,
      email:,
      hashed_password:,
      created_at:,
      updated_at:,
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
  arg_3: Int,
) -> Result(pog.Returned(UpdateUserByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use email <- decode.field(1, decode.string)
    use hashed_password <- decode.field(2, decode.string)
    use created_at <- decode.field(3, pog.timestamp_decoder())
    use updated_at <- decode.field(4, pog.timestamp_decoder())
    decode.success(UpdateUserByIdRow(
      id:,
      email:,
      hashed_password:,
      created_at:,
      updated_at:,
    ))
  }

  "UPDATE
    app_user
SET
    email = COALESCE(NULLIF ($1, ''), email),
    hashed_password = COALESCE(NULLIF ($2, ''), hashed_password)
WHERE
    id = $3
RETURNING
    *;

"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.int(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}
