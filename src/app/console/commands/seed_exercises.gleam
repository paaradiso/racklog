import database/main/models/exercise/gen/exercise
import gleam/list
import glimr/console/command.{type Args, type Command}
import glimr/console/console
import glimr/db/db
import glimr_sqlite/sqlite

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#console-commands

/// The console command description.
const description = "Seed the database with exercises"

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

  let exercises = [
    "Ab Wheel Rollout",
    "Arnold Press",
    "Barbell Bench Press",
    "Barbell Hip Thrust",
    "Barbell Squat",
    "Bayesian Curl",
    "Bicep Curl",
    "Bulgarian Split Squat",
    "Cable Crossover",
    "Cable Crunch",
    "Cable Curl",
    "Chin-up",
    "Close-Grip Bench Press",
    "Concentration Curl",
    "Crunch",
    "Deadlift",
    "Decline Bench Press",
    "Dips",
    "Dumbbell Bench Press",
    "Dumbbell Pullover",
    "Dumbbell Shrug",
    "Face Pull",
    "Front Raise",
    "Glute Kickback",
    "Good Morning",
    "Hack Squat",
    "Hammer Curl",
    "Hanging Leg Raise",
    "High to Low Chest Press",
    "Incline Chest Press",
    "Lat Pulldown",
    "Lat Raise",
    "Lateral Raise",
    "Leg Press",
    "Overhead Press",
    "Pec Deck Fly",
    "Plank",
    "Preacher Curl",
    "Pull-up",
    "Push-up",
    "Romanian Deadlift",
    "Row",
    "Russian Twist",
    "Seated Cable Row",
    "Seated Calf Raise",
    "Seated Chest Fly",
    "Seated Leg Curl",
    "Seated Leg Extension",
    "Seated Rear Delt Fly",
    "Single-Arm Dumbbell Row",
    "Skull Crusher",
    "Standing Calf Raise",
    "Straight Arm Pulldown",
    "T-Bar Row",
    "Triceps Kickback",
    "Triceps Overhead Extension",
    "Triceps Pushdown",
    "Upright Row",
    "Walking Lunges",
  ]

  list.each(exercises, fn(name) {
    case exercise.create(pool, name) {
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
