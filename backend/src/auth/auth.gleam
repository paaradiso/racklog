import argus
import auth/sql
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/time/timestamp
import racklog/user.{type AppUserRole, type PreferredUnit}
import web.{type Context}
import wisp.{type Request, type Response}
import youid/uuid

pub type CreateUserPayload {
  CreateUserPayload(
    username: String,
    email: String,
    password: String,
    user_role: AppUserRole,
    preferred_unit: PreferredUnit,
  )
}

fn create_user_payload_decoder() -> decode.Decoder(CreateUserPayload) {
  use username <- decode.field("username", decode.string)
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  use user_role <- decode.field("user_role", user.role_decoder())
  use preferred_unit <- decode.field(
    "preferred_unit",
    user.preferred_unit_decoder(),
  )
  decode.success(CreateUserPayload(
    username:,
    email:,
    password:,
    user_role:,
    preferred_unit:,
  ))
}

pub type UpdateUserPayload {
  UpdateUserPayload(
    username: String,
    email: String,
    password: String,
    user_role: Option(AppUserRole),
    preferred_unit: Option(PreferredUnit),
  )
}

fn update_user_payload_decoder() -> decode.Decoder(UpdateUserPayload) {
  use username <- decode.optional_field("username", "", decode.string)
  use email <- decode.optional_field("email", "", decode.string)
  use password <- decode.optional_field("password", "", decode.string)
  use user_role <- decode.optional_field(
    "user_role",
    option.None,
    decode.optional(user.role_decoder()),
  )
  use preferred_unit <- decode.optional_field(
    "preferred_unit",
    option.None,
    decode.optional(user.preferred_unit_decoder()),
  )

  decode.success(UpdateUserPayload(
    username:,
    email:,
    password:,
    user_role:,
    preferred_unit:,
  ))
}

fn user_credentials_decoder() -> decode.Decoder(#(String, String)) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(#(email, password))
}

fn shared_role_to_sql_role(role: user.AppUserRole) -> sql.AppUserRole {
  case role {
    user.AdminRole -> sql.Admin
    user.UserRole -> sql.User
  }
}

fn sql_role_to_shared_role(role: sql.AppUserRole) -> user.AppUserRole {
  case role {
    sql.Admin -> user.AdminRole
    sql.User -> user.UserRole
  }
}

fn sql_preferred_unit_to_shared_preferred_unit(
  preferred_unit: sql.PreferredUnit,
) -> user.PreferredUnit {
  case preferred_unit {
    sql.Kg -> user.Kg
    sql.Lb -> user.Lb
  }
}

fn row_to_dto(
  id: Int,
  username: String,
  email: String,
  role: sql.AppUserRole,
  preferred_unit: sql.PreferredUnit,
  created_at: timestamp.Timestamp,
  updated_at: timestamp.Timestamp,
) -> user.UserDto {
  user.UserDto(
    id:,
    username:,
    email:,
    role: sql_role_to_shared_role(role),
    preferred_unit: sql_preferred_unit_to_shared_preferred_unit(preferred_unit),
    created_at:,
    updated_at:,
  )
}

pub fn hash_password(password password: String) -> String {
  // https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#argon2id
  let assert Ok(hashes) =
    argus.hasher()
    |> argus.algorithm(argus.Argon2id)
    |> argus.time_cost(2)
    |> argus.memory_cost(19_456)
    |> argus.parallelism(1)
    |> argus.hash(password, argus.gen_salt())

  hashes.encoded_hash
}

pub fn login(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  let auth_result = {
    use #(email, password) <- result.try(
      decode.run(json, user_credentials_decoder())
      |> result.map_error(fn(_) { wisp.unprocessable_content() }),
    )
    use returned <- result.try(
      sql.get_user_by_email(ctx.db, email)
      |> result.map_error(fn(_) { wisp.internal_server_error() }),
    )
    use user <- result.try(
      list.first(returned.rows) |> result.map_error(fn(_) { wisp.not_found() }),
    )
    use valid <- result.try(
      argus.verify(user.hashed_password, password)
      |> result.map_error(fn(_) { wisp.response(401) }),
    )
    use _ <- result.try(case valid {
      False -> Error(wisp.response(401))
      True -> Ok(Nil)
    })
    let session_id = uuid.v7() |> uuid.to_string
    use _ <- result.try(
      sql.create_session(ctx.db, session_id, user.id)
      |> result.map_error(fn(_) { wisp.internal_server_error() }),
    )
    Ok(session_id)
  }

  case auth_result {
    Error(response) -> response
    Ok(session_id) ->
      wisp.response(200)
      |> wisp.set_cookie(
        req,
        name: "session_id",
        value: session_id,
        security: wisp.Signed,
        max_age: 60 * 60 * 24 * 30,
      )
  }
}

pub fn create_user(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  let create_user_result = {
    use user_details <- result.try(
      decode.run(json, create_user_payload_decoder())
      |> result.map_error(fn(_) { wisp.unprocessable_content() }),
    )

    let hashed_password = hash_password(user_details.password)

    use returned <- result.try(
      sql.create_user(
        ctx.db,
        user_details.username,
        user_details.email,
        hashed_password,
        shared_role_to_sql_role(user_details.user_role),
      )
      |> result.map_error(fn(_) { wisp.internal_server_error() }),
    )

    use user <- result.try(
      list.first(returned.rows) |> result.map_error(fn(_) { wisp.not_found() }),
    )

    Ok(
      row_to_dto(
        user.id,
        user.username,
        user.email,
        user.user_role,
        user.preferred_unit,
        user.created_at,
        user.updated_at,
      )
      |> user.to_json
      |> json.to_string
      |> wisp.json_response(200),
    )
  }
  case create_user_result {
    Ok(user) -> user
    Error(error) -> error
  }
}

pub fn me(_req: Request, ctx: Context) -> Response {
  case ctx.user_id {
    option.None -> Error(wisp.response(401))
    option.Some(user_id) -> {
      use returned <- result.try(
        sql.get_current_user(ctx.db, user_id)
        |> result.map_error(fn(_) { wisp.internal_server_error() }),
      )
      use user <- result.try(
        returned.rows
        |> list.first
        |> result.map_error(fn(_) { wisp.response(401) }),
      )
      Ok(
        row_to_dto(
          user.id,
          user.username,
          user.email,
          user.user_role,
          user.preferred_unit,
          user.created_at,
          user.updated_at,
        )
        |> user.to_json
        |> json.to_string
        |> wisp.json_response(200),
      )
    }
  }
  |> result.unwrap(wisp.response(401))
}

pub fn list_users(_req: Request, ctx: Context) -> Response {
  case sql.list_users(ctx.db) {
    Ok(returned) ->
      returned.rows
      |> json.array(fn(row) {
        row_to_dto(
          row.id,
          row.username,
          row.email,
          row.user_role,
          row.preferred_unit,
          row.created_at,
          row.updated_at,
        )
        |> user.to_json
      })
      |> json.to_string
      |> wisp.json_response(200)
    Error(_) -> {
      wisp.internal_server_error()
    }
  }
}

pub fn delete_user_by_id(_req: Request, ctx: Context, id: String) -> Response {
  case int.parse(id) {
    Error(_) -> wisp.bad_request("Invalid Id")
    Ok(parsed_id) -> {
      case sql.delete_user_by_id(ctx.db, parsed_id) {
        Ok(_) -> wisp.no_content()
        Error(_) -> wisp.internal_server_error()
      }
    }
  }
}

pub fn update_user_by_id(req: Request, ctx: Context, id: String) -> Response {
  use json <- wisp.require_json(req)

  let update_user_result = {
    use id <- result.try(
      int.parse(id)
      |> result.map_error(fn(_) { wisp.bad_request("Invalid Id") }),
    )

    use payload <- result.try(
      decode.run(json, update_user_payload_decoder())
      |> result.map_error(fn(_) { wisp.unprocessable_content() }),
    )

    let hashed_password = case payload.password {
      "" -> ""
      password -> hash_password(password)
    }

    let role_string = case payload.user_role {
      option.Some(role) -> user.role_to_string(role)
      option.None -> ""
    }

    use returned <- result.try(
      sql.update_user_by_id(
        ctx.db,
        payload.username,
        payload.email,
        hashed_password,
        role_string,
        id,
      )
      |> result.map_error(fn(_) { wisp.internal_server_error() }),
    )

    use user <- result.try(
      list.first(returned.rows) |> result.map_error(fn(_) { wisp.not_found() }),
    )

    Ok(
      row_to_dto(
        user.id,
        user.username,
        user.email,
        user.user_role,
        user.preferred_unit,
        user.created_at,
        user.updated_at,
      )
      |> user.to_json
      |> json.to_string
      |> wisp.json_response(200),
    )
  }
  case update_user_result {
    Ok(user) -> user
    Error(error) -> error
  }
}
