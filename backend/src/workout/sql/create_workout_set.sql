INSERT INTO workout_set (workout_exercise_id, sort_order, reps, weight, duration_seconds, rpe, is_complete)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
RETURNING
    *;

