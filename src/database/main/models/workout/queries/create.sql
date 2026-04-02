INSERT INTO workouts (user_id, exercise_id, weight_type_id, weight, reps, notes, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5, $6, unixepoch(), unixepoch())
RETURNING 
  id, 
  user_id,
  exercise_id,
  (SELECT name FROM exercises WHERE id = workouts.exercise_id) AS exercise_name,
  weight_type_id,
  (SELECT name FROM weight_types WHERE id = workouts.weight_type_id) AS weight_type_name,
  weight, 
  reps, 
  notes,
  created_at,
  updated_at
