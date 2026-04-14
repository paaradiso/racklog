import auth/sql as auth_sql
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import web.{type Context, Context}
import wisp.{type Request, type Response}

pub fn load_session(req: Request, ctx: Context) -> Context {
  {
    use session_id <- result.try(wisp.get_cookie(req, "session_id", wisp.Signed))
    use returned <- result.try(
      auth_sql.get_session_by_id(ctx.db, session_id)
      |> result.replace_error(Nil),
    )
    returned.rows
    |> list.first
    |> result.map(fn(session) { Context(..ctx, user_id: Some(session.user_id)) })
  }
  |> result.unwrap(ctx)
}

pub fn require_auth(ctx: Context, next: fn(Int) -> Response) -> Response {
  case ctx.user_id {
    None -> wisp.response(401)
    Some(user_id) -> next(user_id)
  }
}
