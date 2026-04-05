import sqlight

pub type Context {
  Context(db: sqlight.Connection)
}
