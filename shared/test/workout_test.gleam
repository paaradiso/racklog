import gleam/json
import gleam/option
import gleam/time/timestamp
import gleeunit/should
import racklog/workout

fn create_workout() -> workout.WorkoutDto {
  workout.WorkoutDto(
    id: 1,
    user_id: 42,
    name: option.Some("Morning Run"),
    started_at: timestamp.from_unix_seconds(1_776_941_287),
    ended_at: option.Some(timestamp.from_unix_seconds(1_776_944_887)),
    notes: option.Some("Felt great today"),
    created_at: timestamp.from_unix_seconds(1_776_941_287),
    updated_at: timestamp.from_unix_seconds(1_776_941_290),
  )
}

fn create_workout_no_options() -> workout.WorkoutDto {
  workout.WorkoutDto(
    id: 2,
    user_id: 42,
    name: option.None,
    started_at: timestamp.from_unix_seconds(1_776_941_287),
    ended_at: option.None,
    notes: option.None,
    created_at: timestamp.from_unix_seconds(1_776_941_287),
    updated_at: timestamp.from_unix_seconds(1_776_941_290),
  )
}

fn valid_workout_json() {
  json.object([
    #("id", json.int(1)),
    #("user_id", json.int(42)),
    #("name", json.string("Morning Run")),
    #("started_at", json.string("2026-04-23T00:00:00Z")),
    #("ended_at", json.string("2026-04-23T01:00:00Z")),
    #("notes", json.string("Felt great today")),
    #("created_at", json.string("2026-04-23T00:00:00Z")),
    #("updated_at", json.string("2026-04-23T00:00:00Z")),
  ])
}

fn valid_workout_with_nulls_json() {
  json.object([
    #("id", json.int(2)),
    #("user_id", json.int(42)),
    #("name", json.null()),
    #("started_at", json.string("2026-04-23T00:00:00Z")),
    #("ended_at", json.null()),
    #("notes", json.null()),
    #("created_at", json.string("2026-04-23T00:00:00Z")),
    #("updated_at", json.string("2026-04-23T00:00:00Z")),
  ])
}

pub fn decoder_valid_test() {
  valid_workout_json()
  |> json.to_string
  |> json.parse(workout.decoder())
  |> should.be_ok()
}

pub fn decoder_valid_with_nulls_test() {
  valid_workout_with_nulls_json()
  |> json.to_string
  |> json.parse(workout.decoder())
  |> should.be_ok()
}

pub fn decoder_invalid_started_at_test() {
  json.object([
    #("id", json.int(1)),
    #("user_id", json.int(42)),
    #("name", json.string("Morning Run")),
    #("started_at", json.string("invalid_date")),
    #("ended_at", json.string("2026-04-23T01:00:00Z")),
    #("notes", json.string("Felt great today")),
    #("created_at", json.string("2026-04-23T00:00:00Z")),
    #("updated_at", json.string("2026-04-23T00:00:00Z")),
  ])
  |> json.to_string
  |> json.parse(workout.decoder())
  |> should.be_error()
}

pub fn decoder_invalid_ended_at_test() {
  json.object([
    #("id", json.int(1)),
    #("user_id", json.int(42)),
    #("name", json.string("Morning Run")),
    #("started_at", json.string("2026-04-23T00:00:00Z")),
    #("ended_at", json.string("invalid_date")),
    #("notes", json.string("Felt great today")),
    #("created_at", json.string("2026-04-23T00:00:00Z")),
    #("updated_at", json.string("2026-04-23T00:00:00Z")),
  ])
  |> json.to_string
  |> json.parse(workout.decoder())
  |> should.be_error()
}

pub fn decoder_id_wrong_type_test() {
  json.object([
    #("id", json.string("one")),
    #("user_id", json.int(42)),
    #("name", json.string("Morning Run")),
    #("started_at", json.string("2026-04-23T00:00:00Z")),
    #("ended_at", json.string("2026-04-23T01:00:00Z")),
    #("notes", json.string("Felt great today")),
    #("created_at", json.string("2026-04-23T00:00:00Z")),
    #("updated_at", json.string("2026-04-23T00:00:00Z")),
  ])
  |> json.to_string
  |> json.parse(workout.decoder())
  |> should.be_error()
}

pub fn decoder_missing_field_test() {
  json.object([
    #("id", json.int(1)),
    #("user_id", json.int(42)),
    #("started_at", json.string("2026-04-23T00:00:00Z")),
    #("ended_at", json.string("2026-04-23T01:00:00Z")),
    #("created_at", json.string("2026-04-23T00:00:00Z")),
    #("updated_at", json.string("2026-04-23T00:00:00Z")),
  ])
  |> json.to_string
  |> json.parse(workout.decoder())
  |> should.be_error()
}

pub fn decoder_empty_object_test() {
  json.object([])
  |> json.to_string
  |> json.parse(workout.decoder())
  |> should.be_error()
}

pub fn dto_round_trip_test() {
  let w = create_workout()
  w
  |> workout.to_json
  |> json.to_string
  |> json.parse(workout.decoder())
  |> should.equal(Ok(w))
}

pub fn dto_round_trip_with_none_options_test() {
  let w = create_workout_no_options()
  w
  |> workout.to_json
  |> json.to_string
  |> json.parse(workout.decoder())
  |> should.equal(Ok(w))
}

pub fn list_decoder_single_test() {
  let w = create_workout()
  json.preprocessed_array([workout.to_json(w)])
  |> json.to_string
  |> json.parse(workout.list_decoder())
  |> should.equal(Ok([w]))
}

pub fn list_decoder_empty_test() {
  json.preprocessed_array([])
  |> json.to_string
  |> json.parse(workout.list_decoder())
  |> should.equal(Ok([]))
}

pub fn list_decoder_multiple_test() {
  let w1 = create_workout()
  let w2 = create_workout_no_options()
  json.preprocessed_array([workout.to_json(w1), workout.to_json(w2)])
  |> json.to_string
  |> json.parse(workout.list_decoder())
  |> should.equal(Ok([w1, w2]))
}

pub fn list_decoder_invalid_item_test() {
  json.preprocessed_array([valid_workout_json(), json.object([])])
  |> json.to_string
  |> json.parse(workout.list_decoder())
  |> should.be_error()
}
