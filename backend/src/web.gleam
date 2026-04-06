import gleam/option.{type Option}
import pog

pub type Context {
  Context(db: pog.Connection, user_id: Option(Int))
}
