import argus
import auth/map
import auth/sql
import error
import gleam/dynamic/decode
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import middleware
import pog
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
  )
}

fn create_user_payload_decoder() -> decode.Decoder(CreateUserPayload) {
  use username <- decode.field("username", decode.string)
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  use user_role <- decode.field("user_role", user.role_decoder())
  decode.success(CreateUserPayload(username:, email:, password:, user_role:))
}

pub type UpdateUserPayload {
  UpdateUserPayload(
    username: String,
    email: String,
    password: String,
    current_password: Option(String),
    user_role: Option(AppUserRole),
    preferred_unit: Option(PreferredUnit),
  )
}

fn update_user_payload_decoder() -> decode.Decoder(UpdateUserPayload) {
  use username <- decode.optional_field("username", "", decode.string)
  use email <- decode.optional_field("email", "", decode.string)
  use password <- decode.optional_field("password", "", decode.string)
  use current_password <- decode.optional_field(
    "current_password",
    None,
    decode.optional(decode.string),
  )
  use user_role <- decode.optional_field(
    "user_role",
    None,
    decode.optional(user.role_decoder()),
  )
  use preferred_unit <- decode.optional_field(
    "preferred_unit",
    None,
    decode.optional(user.preferred_unit_decoder()),
  )

  decode.success(UpdateUserPayload(
    username:,
    email:,
    password:,
    current_password:,
    user_role:,
    preferred_unit:,
  ))
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
    use username <- decode.field("username", decode.string)
    use password <- decode.field("password", decode.string)
    decode.success(#(username, password))
  }

  let auth_result = {
    use #(username, password) <- result.try(
      decode.run(json, decoder)
      |> result.replace_error(wisp.unprocessable_content()),
    )
    use returned <- result.try(
      sql.get_user_by_username(ctx.db, username)
      |> result.replace_error(error.internal()),
    )
    use user <- result.try(
      list.first(returned.rows) |> result.replace_error(error.unauthorized()),
    )
    use valid <- result.try(
      argus.verify(user.hashed_password, password)
      |> result.replace_error(error.unauthorized()),
    )
    use _ <- result.try(case valid {
      False -> Error(error.unauthorized())
      True -> Ok(Nil)
    })
    let session_id = uuid.v7() |> uuid.to_string
    use _ <- result.try(
      sql.create_session(ctx.db, session_id, user.id)
      |> result.replace_error(error.internal()),
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

pub fn logout(req: Request, ctx: Context) -> Response {
  use session_id <- middleware.require_session(ctx)

  case sql.delete_session_by_id(ctx.db, session_id) {
    Error(_) -> error.internal()
    Ok(_) ->
      wisp.response(200)
      |> wisp.set_cookie(
        req,
        name: "session_id",
        value: "",
        security: wisp.Signed,
        max_age: 0,
      )
  }
}

pub fn create_user(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)

  let create_user_result = {
    use user_details <- result.try(
      decode.run(json, create_user_payload_decoder())
      |> result.replace_error(wisp.unprocessable_content()),
    )

    use _ <- result.try(
      case
        user_details.username |> string.length < user.minimum_username_length
      {
        True ->
          Error(error.validation(
            user.UsernameField |> user.form_field_to_string,
            // TODO: create shared UsernameValidationError type?
            "Username must be at least "
              <> user.minimum_username_length |> int.to_string
              <> " characters long.",
          ))
        False -> Ok(Nil)
      },
    )

    use _ <- result.try(
      user.validate_password(user_details.password)
      |> result.map_error(fn(error) {
        error.validation(
          user.PasswordField |> user.form_field_to_string,
          user.password_validation_error_to_string(error),
        )
      }),
    )

    let hashed_password = hash_password(user_details.password)

    use returned <- result.try(
      sql.create_user(
        ctx.db,
        user_details.username,
        user_details.email,
        hashed_password,
        map.shared_role_to_sql_role(user_details.user_role),
      )
      |> result.map_error(fn(error) {
        case error {
          pog.ConstraintViolated(constraint: "app_user_username_key", ..) ->
            error.conflict(
              user.UsernameField |> user.form_field_to_string,
              "A user with this username already exists.",
            )
          pog.ConstraintViolated(constraint: "app_user_email_key", ..) ->
            error.conflict(
              user.EmailField |> user.form_field_to_string,
              "A user with this email address already exists.",
            )
          _ -> error.internal()
        }
      }),
    )

    use user <- result.try(
      list.first(returned.rows)
      |> result.replace_error(error.not_found()),
    )

    Ok(
      map.row_to_dto(
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
    Ok(value) | Error(value) -> value
  }
}

pub fn me(_req: Request, ctx: Context) -> Response {
  use user <- middleware.require_authentication(ctx)
  user
  |> user.to_json
  |> json.to_string
  |> wisp.json_response(200)
}

pub fn list_users(_req: Request, ctx: Context) -> Response {
  use <- middleware.require_admin(ctx)

  case sql.list_users(ctx.db) {
    Ok(returned) ->
      returned.rows
      |> json.array(fn(row) {
        map.row_to_dto(
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
    Error(_) -> error.internal()
  }
}

pub fn delete_user_by_id(_req: Request, ctx: Context, id: String) -> Response {
  use id <- middleware.require_valid_id(id)
  use _ <- middleware.require_authorisation(ctx, id)

  case sql.delete_user_by_id(ctx.db, id) {
    Ok(_) -> wisp.no_content()
    Error(_) -> error.internal()
  }
}

pub fn update_user_by_id(req: Request, ctx: Context, id: String) -> Response {
  use id <- middleware.require_valid_id(id)
  use user <- middleware.require_authorisation(ctx, id)
  use json <- wisp.require_json(req)

  let update_user_result = {
    use payload <- result.try(
      decode.run(json, update_user_payload_decoder())
      |> result.replace_error(wisp.unprocessable_content()),
    )

    use _ <- result.try(
      case
        user.role == user.AdminRole,
        payload.password,
        payload.email,
        payload.current_password
      {
        True, _, _, _ -> Ok(Nil)
        False, "", "", _ -> Ok(Nil)
        False, _, _, None ->
          Error(error.validation(
            user.CurrentPasswordField |> user.form_field_to_string,
            "Current password is required.",
          ))
        _, _, _, Some(current) -> verify_current_password(ctx, id, current)
      },
    )

    use _ <- result.try(case payload.password {
      "" -> Ok(Nil)
      password ->
        user.validate_password(password)
        |> result.map_error(fn(error) {
          error.validation(
            user.PasswordField |> user.form_field_to_string,
            user.password_validation_error_to_string(error),
          )
        })
    })

    let hashed_password = case payload.password {
      "" -> ""
      password -> hash_password(password)
    }

    let role_string = case payload.user_role {
      Some(role) -> user.role_to_string(role)
      None -> ""
    }

    let preferred_unit_string = case payload.preferred_unit {
      Some(preferred_unit) -> user.preferred_unit_to_string(preferred_unit)
      None -> ""
    }

    use returned <- result.try(
      sql.update_user_by_id(
        ctx.db,
        payload.username,
        payload.email,
        hashed_password,
        role_string,
        preferred_unit_string,
        id,
      )
      |> result.map_error(fn(e) {
        case e {
          pog.ConstraintViolated(constraint: "app_user_username_key", ..) ->
            error.conflict(
              user.UsernameField |> user.form_field_to_string,
              "A user with this username already exists.",
            )
          pog.ConstraintViolated(_, "app_user_email_key", _) ->
            error.conflict(
              user.EmailField |> user.form_field_to_string,
              "A user with this email address already exists.",
            )
          _ -> error.internal()
        }
      }),
    )

    use user <- result.try(
      list.first(returned.rows)
      |> result.replace_error(error.not_found()),
    )

    Ok(
      map.row_to_dto(
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
    Ok(user) | Error(user) -> user
  }
}

fn verify_current_password(
  ctx: Context,
  id: Int,
  current_password: String,
) -> Result(Nil, response.Response(wisp.Body)) {
  use returned <- result.try(
    sql.get_user_by_id(ctx.db, id)
    |> result.replace_error(error.internal()),
  )
  use user <- result.try(
    list.first(returned.rows)
    |> result.replace_error(error.not_found()),
  )

  case argus.verify(user.hashed_password, current_password) {
    Ok(True) -> Ok(Nil)
    Ok(False) ->
      Error(error.validation(
        user.CurrentPasswordField |> user.form_field_to_string,
        "Incorrect current password.",
      ))
    Error(_) -> Error(error.internal())
  }
}
