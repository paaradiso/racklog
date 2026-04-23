import gleam/option.{type Option}
import pog
import racklog/user.{type UserDto}

pub type Context {
  Context(db: pog.Connection, session_id: Option(String), user: Option(UserDto))
}
