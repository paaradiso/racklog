import envie
import envie/decode
import envie/schema

pub type Config {
  Config(database_url: String, secret_key_base: String)
}

pub fn load() -> Config {
  let _ = envie.load_from("../.env")

  let schema =
    schema.build2(
      schema.field("DATABASE_URL", decode.string()),
      schema.field("SECRET_KEY_BASE", decode.string()),
      Config,
    )

  case schema.load(schema) {
    Ok(config) -> config
    Error(error) -> {
      panic as envie.format_error(error)
    }
  }
}
