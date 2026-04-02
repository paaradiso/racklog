import glimr/db/schema

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#migrations

pub const table_name = "workouts"

pub fn definition() {
  schema.table(table_name, [
    schema.id(),
    schema.foreign("user_id", "users"),
    schema.foreign("exercise_id", "exercises"),
    schema.foreign("weight_type_id", "weight_types"),
    schema.int("weight"),
    schema.int("reps"),
    schema.text("notes"),
    schema.unix_timestamps(),
  ])
}
