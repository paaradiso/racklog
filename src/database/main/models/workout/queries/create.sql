INSERT INTO workouts (exercise_id, weight_type_id, weight, reps, notes, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, unixepoch(), unixepoch())
RETURNING *
