import auth/auth
import auth/sql as auth_sql
import db
import exercise/sql as exercise_sql
import gleam/io
import gleam/list
import weight_type/sql as weight_type_sql

pub fn main() {
  let connection = db.connect()

  io.println("Seeding weight types...")
  let weight_types = [
    "Barbell",
    "Dumbbell",
    "Cable",
    "Plate Loaded Machine",
    "Bodyweight",
  ]

  list.each(weight_types, fn(name) {
    case weight_type_sql.create(connection, name) {
      Ok(_) -> io.println("Created: " <> name)
      Error(_) -> io.println("Error creating: " <> name)
    }
  })

  io.println("Seeding exercises...")
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
    case exercise_sql.create(connection, name) {
      Ok(_) -> io.println("Created: " <> name)
      Error(_) -> io.println("Error creating: " <> name)
    }
  })

  io.println("Seeding user...")
  case
    auth_sql.create_user(
      connection,
      "admin",
      "test@example.com",
      auth.hash_password("abc123abc"),
    )
  {
    Ok(_) -> io.println("Created user")
    Error(_) -> io.println("Error creating user")
  }

  io.println("Seeding complete")
}
