import auth/sql as auth_sql
import gleam/option.{None, Some}
import gleam/string
import web.{type Context, Context}
import wisp.{type Request, type Response}

pub fn load_session(req: Request, ctx: Context) -> Context {
  case wisp.get_cookie(req, "session_id", wisp.Signed) {
    Error(e) -> {
      wisp.log_debug("no session cookie: " <> string.inspect(e))
      ctx
    }
    Ok(session_id) -> {
      wisp.log_debug("session_id: " <> session_id)
      case auth_sql.get_session_by_id(ctx.db, session_id) {
        Error(e) -> {
          wisp.log_debug("db error: " <> string.inspect(e))
          ctx
        }
        Ok(returned) -> {
          case returned.rows {
            [] -> {
              wisp.log_debug("no session found for id: " <> session_id)
              ctx
            }
            [session, ..] -> {
              wisp.log_debug(
                "session found, user_id: " <> string.inspect(session.user_id),
              )
              Context(..ctx, user_id: Some(session.user_id))
            }
          }
        }
      }
    }
  }
}

pub fn require_auth(ctx: Context, next: fn(Int) -> Response) -> Response {
  case ctx.user_id {
    None -> wisp.response(401)
    Some(user_id) -> next(user_id)
  }
}
