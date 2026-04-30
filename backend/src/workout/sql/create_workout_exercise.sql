INSERT INTO workout_exercise (workout_id, exercise_id, equipment_id, sort_order, notes)
    VALUES ($1, $2, $3, $4, $5)
RETURNING
    *;

