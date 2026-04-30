//// This module contains the code to run the sql queries defined in
//// `./src/workout/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog

/// A row you get from running the `create_empty_workout` query
/// defined in `./src/workout/sql/create_empty_workout.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateEmptyWorkoutRow {
  CreateEmptyWorkoutRow(id: Int)
}

/// Runs the `create_empty_workout` query
/// defined in `./src/workout/sql/create_empty_workout.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_empty_workout(
  db: pog.Connection,
  arg_1: Int,
) -> Result(pog.Returned(CreateEmptyWorkoutRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    decode.success(CreateEmptyWorkoutRow(id:))
  }

  "INSERT INTO workout (user_id)
    VALUES ($1)
RETURNING
    id;

"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_workout_exercise` query
/// defined in `./src/workout/sql/create_workout_exercise.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateWorkoutExerciseRow {
  CreateWorkoutExerciseRow(
    id: Int,
    workout_id: Int,
    exercise_id: Int,
    equipment_id: Int,
    sort_order: Int,
    notes: Option(String),
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `create_workout_exercise` query
/// defined in `./src/workout/sql/create_workout_exercise.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_workout_exercise(
  db: pog.Connection,
  arg_1: Int,
  arg_2: Int,
  arg_3: Int,
  arg_4: Int,
  arg_5: String,
) -> Result(pog.Returned(CreateWorkoutExerciseRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use workout_id <- decode.field(1, decode.int)
    use exercise_id <- decode.field(2, decode.int)
    use equipment_id <- decode.field(3, decode.int)
    use sort_order <- decode.field(4, decode.int)
    use notes <- decode.field(5, decode.optional(decode.string))
    use created_at <- decode.field(6, pog.timestamp_decoder())
    use updated_at <- decode.field(7, pog.timestamp_decoder())
    decode.success(CreateWorkoutExerciseRow(
      id:,
      workout_id:,
      exercise_id:,
      equipment_id:,
      sort_order:,
      notes:,
      created_at:,
      updated_at:,
    ))
  }

  "INSERT INTO workout_exercise (workout_id, exercise_id, equipment_id, sort_order, notes)
    VALUES ($1, $2, $3, $4, $5)
RETURNING
    *;

"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.parameter(pog.int(arg_3))
  |> pog.parameter(pog.int(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_workout_set` query
/// defined in `./src/workout/sql/create_workout_set.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateWorkoutSetRow {
  CreateWorkoutSetRow(
    id: Int,
    workout_exercise_id: Int,
    sort_order: Int,
    reps: Option(Int),
    weight: Option(Float),
    duration_seconds: Option(Int),
    rpe: Option(Float),
    is_complete: Bool,
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `create_workout_set` query
/// defined in `./src/workout/sql/create_workout_set.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_workout_set(
  db: pog.Connection,
  arg_1: Int,
  arg_2: Int,
  arg_3: Int,
  arg_4: Float,
  arg_5: Int,
  arg_6: Float,
  arg_7: Bool,
) -> Result(pog.Returned(CreateWorkoutSetRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use workout_exercise_id <- decode.field(1, decode.int)
    use sort_order <- decode.field(2, decode.int)
    use reps <- decode.field(3, decode.optional(decode.int))
    use weight <- decode.field(4, decode.optional(pog.numeric_decoder()))
    use duration_seconds <- decode.field(5, decode.optional(decode.int))
    use rpe <- decode.field(6, decode.optional(pog.numeric_decoder()))
    use is_complete <- decode.field(7, decode.bool)
    use created_at <- decode.field(8, pog.timestamp_decoder())
    use updated_at <- decode.field(9, pog.timestamp_decoder())
    decode.success(CreateWorkoutSetRow(
      id:,
      workout_exercise_id:,
      sort_order:,
      reps:,
      weight:,
      duration_seconds:,
      rpe:,
      is_complete:,
      created_at:,
      updated_at:,
    ))
  }

  "INSERT INTO workout_set (workout_exercise_id, sort_order, reps, weight, duration_seconds, rpe, is_complete)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
RETURNING
    *;

"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.parameter(pog.int(arg_3))
  |> pog.parameter(pog.float(arg_4))
  |> pog.parameter(pog.int(arg_5))
  |> pog.parameter(pog.float(arg_6))
  |> pog.parameter(pog.bool(arg_7))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_active_workout_for_user_id` query
/// defined in `./src/workout/sql/get_active_workout_for_user_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetActiveWorkoutForUserIdRow {
  GetActiveWorkoutForUserIdRow(
    id: Int,
    user_id: Int,
    name: Option(String),
    started_at: Timestamp,
    ended_at: Option(Timestamp),
    notes: Option(String),
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `get_active_workout_for_user_id` query
/// defined in `./src/workout/sql/get_active_workout_for_user_id.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_active_workout_for_user_id(
  db: pog.Connection,
  arg_1: Int,
) -> Result(pog.Returned(GetActiveWorkoutForUserIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use user_id <- decode.field(1, decode.int)
    use name <- decode.field(2, decode.optional(decode.string))
    use started_at <- decode.field(3, pog.timestamp_decoder())
    use ended_at <- decode.field(4, decode.optional(pog.timestamp_decoder()))
    use notes <- decode.field(5, decode.optional(decode.string))
    use created_at <- decode.field(6, pog.timestamp_decoder())
    use updated_at <- decode.field(7, pog.timestamp_decoder())
    decode.success(GetActiveWorkoutForUserIdRow(
      id:,
      user_id:,
      name:,
      started_at:,
      ended_at:,
      notes:,
      created_at:,
      updated_at:,
    ))
  }

  "SELECT
    *
FROM
    workout
WHERE
    user_id = $1
    AND ended_at IS NULL
LIMIT 1;

"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_workouts_by_user_id` query
/// defined in `./src/workout/sql/list_workouts_by_user_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListWorkoutsByUserIdRow {
  ListWorkoutsByUserIdRow(
    id: Int,
    user_id: Int,
    name: Option(String),
    started_at: Timestamp,
    ended_at: Option(Timestamp),
    notes: Option(String),
    created_at: Timestamp,
    updated_at: Timestamp,
  )
}

/// Runs the `list_workouts_by_user_id` query
/// defined in `./src/workout/sql/list_workouts_by_user_id.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_workouts_by_user_id(
  db: pog.Connection,
  arg_1: Int,
) -> Result(pog.Returned(ListWorkoutsByUserIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use user_id <- decode.field(1, decode.int)
    use name <- decode.field(2, decode.optional(decode.string))
    use started_at <- decode.field(3, pog.timestamp_decoder())
    use ended_at <- decode.field(4, decode.optional(pog.timestamp_decoder()))
    use notes <- decode.field(5, decode.optional(decode.string))
    use created_at <- decode.field(6, pog.timestamp_decoder())
    use updated_at <- decode.field(7, pog.timestamp_decoder())
    decode.success(ListWorkoutsByUserIdRow(
      id:,
      user_id:,
      name:,
      started_at:,
      ended_at:,
      notes:,
      created_at:,
      updated_at:,
    ))
  }

  "SELECT
    *
FROM
    workout
WHERE
    user_id = $1
ORDER BY
    started_at DESC;

"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}
