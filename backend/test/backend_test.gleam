import gleeunit
import util

pub fn main() -> Nil {
  util.migrate_db()
  gleeunit.main()
}
