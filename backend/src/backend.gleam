import db
import gleam/erlang/process
import gleam/option
import mist
import router
import web
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let db = db.connect()
  let context = web.Context(db:, user_id: option.None)

  let handler = router.handle_request(_, context)
  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
