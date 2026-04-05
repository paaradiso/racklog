import app/app.{type App, App}
import database/main/models/user/gen/user
import gleam/int
import gleam/option
import gleam/result
import glimr/http/context.{type Context, Context}
import glimr/http/http.{type Response}
import glimr/http/kernel.{type Next}
import glimr_auth/auth

pub fn run(ctx: Context(App), next: Next(App)) -> Response {
  let user =
    auth.id(ctx.session, user.session_key)
    |> result.try(int.parse)
    |> result.try(fn(id) { user.find(ctx.app.db, id) |> result.replace_error(Nil) })
    |> option.from_result

  let ctx = Context(..ctx, app: App(..ctx.app, user: user))

  next(ctx)
}
