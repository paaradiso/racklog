import envoy
import gleam/result

pub type Config {
  Config(database_url: String)
}

pub type ConfigError {
  MissingVariable(String)
}

pub fn load() -> Result(Config, ConfigError) {
  use database_url <- result.try(
    envoy.get("DATABASE_URL")
    |> result.replace_error(MissingVariable("DATABASE_URL")),
  )

  Ok(Config(database_url:))
}
