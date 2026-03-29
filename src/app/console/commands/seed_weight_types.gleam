import database/main/models/weight_type/gen/weight_type
import gleam/list
import glimr/console/command.{type Args, type Command}
import glimr/console/console
import glimr/db/db
import glimr_sqlite/sqlite

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#console-commands

/// The console command description.
const description = "Seed the database with common weight types"

/// Define the console command and its properties.
///
pub fn command() -> Command {
  command.new()
  |> command.description(description)
  |> command.handler(run)
}

/// Execute the console command.
///
fn run(_args: Args) -> Nil {
  let pool = sqlite.start("main")

  let weight_types = [
    "Barbell",
    "Dumbbell",
    "Cable",
    "Plate Loaded Machine",
    "Bodyweight",
  ]

  list.each(weight_types, fn(name) {
    case weight_type.create(pool, name) {
      Ok(_) -> console.line_success("Created: " <> name)
      Error(_) -> console.line_warning("Error creating: " <> name)
    }
  })

  db.stop_pool(pool)
}

/// Console command's entry point
///
pub fn main() {
  command.run(command())
}
