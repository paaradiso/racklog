import config
import db
import gleam/erlang/process
import gleam/option
import mist
import router
import web
import wisp
import wisp/wisp_mist

pub fn main() {
  let cfg = config.load()
  wisp.configure_logger()

  let db = db.connect()
  let context = web.Context(db:, user_id: option.None, session_id: option.None)

  let handler = router.handle_request(_, context)
  let assert Ok(_) =
    wisp_mist.handler(handler, cfg.secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
