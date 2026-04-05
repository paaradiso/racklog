import gleam/erlang/process
import mist
import router
import sqlight
import web.{Context}
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  use db_connection <- sqlight.with_connection("main.db")

  let context = Context(db: db_connection)

  let handler = router.handle_request(_, context)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
