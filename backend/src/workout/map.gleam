import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import racklog/workout

pub fn row_to_dto(
  id: Int,
  user_id: Int,
  name: Option(String),
  started_at: Timestamp,
  ended_at: Option(Timestamp),
  notes: Option(String),
  created_at: Timestamp,
  updated_at: Timestamp,
) -> workout.WorkoutDto {
  workout.WorkoutDto(
    id:,
    user_id:,
    name:,
    started_at:,
    ended_at:,
    notes:,
    created_at:,
    updated_at:,
  )
}
