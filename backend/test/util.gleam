import auth/auth
import auth/sql as auth_sql
import cigogne
import cigogne/config as cigogne_config
import envie
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import pog
import web
import wisp
import wisp/simulate
import youid/uuid

fn get_database_url() -> String {
  let _ = envie.load_from("../.env")
  case envie.get("TEST_DATABASE_URL") {
    Ok(u) -> u
    Error(_) -> panic as "TEST_DATABASE_URL must be set"
  }
}

pub fn connect_to_db() -> #(pog.Connection, process.Pid) {
  let database_url = get_database_url()
  let pool_name = process.new_name("test_db")
  let assert Ok(pog_config) = pog.url_config(pool_name, database_url)
  let assert Ok(actor.Started(pid:, ..)) = pog.start(pog_config)
  #(pog.named_connection(pool_name), pid)
}

pub fn migrate_db() -> Nil {
  let database_url = get_database_url()
  let config =
    cigogne_config.Config(
      ..cigogne_config.default_config,
      database: cigogne_config.UrlDbConfig(database_url),
      migrations: cigogne_config.MigrationsConfig(
        ..cigogne_config.default_migrations_config,
        application_name: "backend",
        migration_folder: Some("migrations"),
      ),
    )

  let assert Ok(engine) = cigogne.create_engine(config)
  let _ = cigogne.apply_all(engine)
  Nil
}

pub fn create_context(db: pog.Connection) -> web.Context {
  web.Context(db:, session_id: None, user: None)
}

pub fn truncate_db(db: pog.Connection) -> Nil {
  let assert Ok(_) =
    pog.query(
      "TRUNCATE session, app_user, exercise, equipment RESTART IDENTITY CASCADE",
    )
    |> pog.execute(db)
  Nil
}

pub fn with_db(test_fn: fn(pog.Connection, web.Context) -> Nil) -> Nil {
  let #(db, pid) = connect_to_db()
  truncate_db(db)
  let ctx = create_context(db)
  test_fn(db, ctx)
  process.send_exit(pid)
}

pub fn seed_user(db: pog.Connection, username: String) -> #(Int, String) {
  let hashed_password = auth.hash_password("password")
  let assert Ok(returned) =
    auth_sql.create_user(
      db,
      username,
      username <> "@test.com",
      hashed_password,
      auth_sql.User,
    )
  let assert Ok(user) = list.first(returned.rows)
  let session_id = uuid.v7() |> uuid.to_string
  let assert Ok(_) = auth_sql.create_session(db, session_id, user.id)
  #(user.id, session_id)
}

pub fn seed_admin(db: pog.Connection) -> #(Int, String) {
  let hashed_password = auth.hash_password("password")
  let assert Ok(returned) =
    auth_sql.create_user(
      db,
      "admin",
      "admin@test.com",
      hashed_password,
      auth_sql.Admin,
    )
  let assert Ok(user) = list.first(returned.rows)
  let session_id = uuid.v7() |> uuid.to_string
  let assert Ok(_) = auth_sql.create_session(db, session_id, user.id)
  #(user.id, session_id)
}

pub fn simulate_session_cookie(
  req: Request(wisp.Connection),
  value: String,
) -> Request(wisp.Connection) {
  simulate.cookie(req, "session_id", value, wisp.Signed)
}
