import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}
import racklog/util

pub type WorkoutDto {
  WorkoutDto(
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

pub fn decoder() -> decode.Decoder(WorkoutDto) {
  use id <- decode.field("id", decode.int)
  use user_id <- decode.field("user_id", decode.int)
  use name <- decode.field("name", decode.string |> decode.optional)
  use started_at <- decode.field("started_at", util.timestamp_decoder())
  use ended_at <- decode.field(
    "ended_at",
    util.timestamp_decoder() |> decode.optional,
  )
  use notes <- decode.field("notes", decode.string |> decode.optional)
  use created_at <- decode.field("created_at", util.timestamp_decoder())
  use updated_at <- decode.field("updated_at", util.timestamp_decoder())
  decode.success(WorkoutDto(
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

pub fn list_decoder() -> decode.Decoder(List(WorkoutDto)) {
  decode.list(decoder())
}

pub fn to_json(workout: WorkoutDto) -> json.Json {
  json.object([
    #("id", json.int(workout.id)),
    #("user_id", json.int(workout.user_id)),
    #("name", json.nullable(workout.name, json.string)),
    #(
      "started_at",
      workout.started_at
        |> timestamp.to_rfc3339(duration.seconds(0))
        |> json.string,
    ),
    #(
      "ended_at",
      json.nullable(workout.ended_at, fn(timestamp) {
        timestamp
        |> timestamp.to_rfc3339(duration.seconds(0))
        |> json.string
      }),
    ),
    #("notes", json.nullable(workout.notes, json.string)),
    #(
      "created_at",
      workout.created_at
        |> timestamp.to_rfc3339(duration.seconds(0))
        |> json.string,
    ),
    #(
      "updated_at",
      workout.updated_at
        |> timestamp.to_rfc3339(duration.seconds(0))
        |> json.string,
    ),
  ])
}
