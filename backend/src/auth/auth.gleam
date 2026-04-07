import argus
import auth/sql.{type CreateUserRow, type ListUsersRow}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/time/duration
import gleam/time/timestamp
import web.{type Context}
import wisp.{type Request, type Response}
import youid/uuid

pub type User {
  User(email: String, password: String)
}

fn list_users_row_to_json(row: ListUsersRow) -> json.Json {
  json.object([
    #("id", json.int(row.id)),
    #("email", json.string(row.email)),
    #(
      "created_at",
      json.string(timestamp.to_rfc3339(row.created_at, duration.seconds(0))),
    ),
    #(
      "updated_at",
      json.string(timestamp.to_rfc3339(row.updated_at, duration.seconds(0))),
    ),
  ])
}

fn create_user_row_to_json(row: CreateUserRow) -> json.Json {
  json.object([
    #("id", json.int(row.id)),
    #("email", json.string(row.email)),
    #(
      "created_at",
      json.string(timestamp.to_rfc3339(row.created_at, duration.seconds(0))),
    ),
    #(
      "updated_at",
      json.string(timestamp.to_rfc3339(row.updated_at, duration.seconds(0))),
    ),
  ])
}

fn user_credentials_decoder() -> decode.Decoder(#(String, String)) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  decode.success(#(email, password))
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
    use #(email, password) <- result.try(
      decode.run(json, user_credentials_decoder())
      |> result.map_error(fn(_) { wisp.unprocessable_content() }),
    )

    let hashed_password = hash_password(password)

    use returned <- result.try(
      sql.create_user(ctx.db, email, hashed_password)
      |> result.map_error(fn(_) { wisp.internal_server_error() }),
    )

    use user <- result.try(
      list.first(returned.rows) |> result.map_error(fn(_) { wisp.not_found() }),
    )

    Ok(
      create_user_row_to_json(user) |> json.to_string |> wisp.json_response(200),
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
        json.object([
          #("id", json.int(user.id)),
          #("email", json.string(user.email)),
        ])
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
      |> json.array(list_users_row_to_json)
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
