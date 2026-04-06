import config
import gleam/erlang/process
import pog

pub fn connect() -> pog.Connection {
  let assert Ok(cfg) = config.load()

  let pool_name = process.new_name("db")

  let assert Ok(pog_config) = pog.url_config(pool_name, cfg.database_url)
  let _pool = pog.start(pog_config)

  pog.named_connection(pool_name)
}
