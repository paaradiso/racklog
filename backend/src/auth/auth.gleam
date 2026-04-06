import argus
import auth/sql
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import web.{type Context}
import wisp.{type Request, type Response}
import youid/uuid

pub type User {
  User(email: String, password: String)
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

  let decoder = {
    use email <- decode.field("email", decode.string)
    use password <- decode.field("password", decode.string)
    decode.success(#(email, password))
  }

  let auth_result = {
    use #(email, password) <- result.try(
      decode.run(json, decoder)
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

pub fn me(_req: Request, ctx: Context) -> Response {
  case ctx.user_id {
    option.None -> wisp.response(401)
    option.Some(user_id) -> {
      case sql.get_current_user(ctx.db, user_id) {
        Error(_) -> wisp.internal_server_error()
        Ok(returned) -> {
          case returned.rows {
            [] -> wisp.response(401)
            [user, ..] ->
              json.object([
                #("id", json.int(user.id)),
                #("email", json.string(user.email)),
              ])
              |> json.to_string
              |> wisp.json_response(200)
          }
        }
      }
    }
  }
}
