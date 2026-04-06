import dot_env
import envoy
import gleam/result

pub type Config {
  Config(database_url: String, secret_key_base: String)
}

pub type ConfigError {
  MissingVariable(String)
}

pub fn load() -> Result(Config, ConfigError) {
  dot_env.new()
  |> dot_env.set_path("../.env")
  |> dot_env.load

  use database_url <- result.try(
    envoy.get("DATABASE_URL")
    |> result.replace_error(MissingVariable("DATABASE_URL")),
  )

  use secret_key_base <- result.try(
    envoy.get("BACKEND_SECRET_KEY_BASE")
    |> result.replace_error(MissingVariable("BACKEND_SECRET_KEY_BASE")),
  )

  Ok(Config(database_url:, secret_key_base:))
}
