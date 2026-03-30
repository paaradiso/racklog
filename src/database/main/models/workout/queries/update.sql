UPDATE workouts
SET updated_at = unixepoch(), exercise_id = $1, weight_type_id = $2, weight = $3, reps = $4, notes = $5
WHERE id = $6
RETURNING *
