import auth/sql.{GetUserByIdRow} as auth_sql
import gleam/int
import gleam/option.{None, Some}
import pog
import web.{type Context, Context}
import wisp.{type Request, type Response}

pub fn load_session(req: Request, ctx: Context) -> Context {
  case wisp.get_cookie(req, "session_id", wisp.Signed) {
    Ok(session_id) ->
      case auth_sql.get_session_by_id(ctx.db, session_id) {
        Ok(pog.Returned(rows: [session], ..)) ->
          Context(
            ..ctx,
            user_id: Some(session.user_id),
            session_id: Some(session_id),
          )
        Ok(pog.Returned(rows: [_, _, ..], ..)) ->
          panic as "multiple sessions returned for one session id"
        _ -> ctx
      }
    Error(_) -> ctx
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
  next: fn(Int) -> Response,
) -> Response {
  case ctx.user_id {
    Some(user_id) -> next(user_id)
    None -> wisp.response(401)
  }
}

pub fn require_admin(ctx: Context, next: fn() -> Response) -> Response {
  use user_id <- require_authentication(ctx)

  case auth_sql.get_user_by_id(ctx.db, user_id) {
    Ok(pog.Returned(rows: [GetUserByIdRow(user_role: auth_sql.Admin, ..)], ..)) ->
      next()
    Ok(pog.Returned(rows: [GetUserByIdRow(user_role: auth_sql.User, ..)], ..)) ->
      wisp.response(403)
    Ok(pog.Returned(rows: [_, _, ..], ..)) ->
      panic as "multiple users returned for one user id"
    _ -> wisp.response(401)
  }
}

pub fn require_authorisation(
  ctx: Context,
  req_user_id: Int,
  next: fn(Int) -> Response,
) -> Response {
  use user_id <- require_authentication(ctx)

  case req_user_id == user_id {
    True -> next(user_id)
    False -> require_admin(ctx, fn() { next(user_id) })
  }
}

pub fn require_valid_id(id: String, next: fn(Int) -> Response) -> Response {
  case int.parse(id) {
    Ok(id) -> next(id)
    Error(_) -> wisp.bad_request("Invalid ID")
  }
}
