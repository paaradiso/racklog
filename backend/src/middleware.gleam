import auth/map
import auth/sql as auth_sql
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import racklog/user.{type UserDto, AdminRole}
import web.{type Context, Context}
import wisp.{type Request, type Response}

pub fn load_session(
  req: Request,
  ctx: Context,
  next: fn(Context) -> Response,
) -> Response {
  let result = {
    use session_id <- result.try(
      wisp.get_cookie(req, "session_id", wisp.Signed)
      |> result.replace_error(Nil),
    )

    use session_row <- result.try(
      auth_sql.get_session_by_id(ctx.db, session_id)
      |> result.map(fn(r) { r.rows })
      |> result.replace_error(Nil),
    )

    use session <- result.try(
      list.first(session_row) |> result.replace_error(Nil),
    )

    use user_row <- result.try(
      auth_sql.get_user_by_id(ctx.db, session.user_id)
      |> result.map(fn(r) { r.rows })
      |> result.replace_error(Nil),
    )

    use user <- result.try(list.first(user_row) |> result.replace_error(Nil))

    let user_dto =
      map.row_to_dto(
        user.id,
        user.username,
        user.email,
        user.user_role,
        user.preferred_unit,
        user.created_at,
        user.updated_at,
      )

    Ok(next(Context(..ctx, session_id: Some(session_id), user: Some(user_dto))))
  }

  case result {
    Ok(res) -> res
    Error(Nil) -> {
      let session_id_exists = wisp.get_cookie(req, "session_id", wisp.Signed)
      case session_id_exists {
        Ok(_) -> {
          next(ctx)
          |> wisp.set_cookie(req, "session_id", "", wisp.Signed, max_age: 0)
        }
        Error(_) -> next(ctx)
      }
    }
  }
}

pub fn require_session(ctx: Context, next: fn(String) -> Response) -> Response {
  case ctx.session_id {
    Some(session_id) -> next(session_id)
    None -> wisp.response(401)
  }
}

pub fn require_authentication(
  ctx: Context,
  next: fn(UserDto) -> Response,
) -> Response {
  case ctx.user {
    Some(user) -> next(user)
    None -> wisp.response(401)
  }
}

pub fn require_admin(ctx: Context, next: fn() -> Response) -> Response {
  case ctx.user {
    Some(user) if user.role == AdminRole -> next()
    Some(_) -> wisp.response(403)
    None -> wisp.response(401)
  }
}

pub fn require_authorisation(
  ctx: Context,
  req_user_id: Int,
  next: fn(UserDto) -> Response,
) -> Response {
  use user <- require_authentication(ctx)

  case req_user_id == user.id {
    True -> next(user)
    False -> require_admin(ctx, fn() { next(user) })
  }
}

pub fn require_valid_id(id: String, next: fn(Int) -> Response) -> Response {
  case int.parse(id) {
    Ok(id) -> next(id)
    Error(_) -> wisp.bad_request("Invalid ID")
  }
}
