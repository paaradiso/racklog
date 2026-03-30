UPDATE workouts
SET 
  updated_at = unixepoch(), 
  exercise_id = $1, 
  weight_type_id = $2, 
  weight = $3, 
  reps = $4, 
  notes = $5
WHERE id = $6
RETURNING 
  id, 
  exercise_id,
  (SELECT name FROM exercises WHERE id = workouts.exercise_id) AS exercise_name,
  weight_type_id,
  (SELECT name FROM weight_types WHERE id = workouts.weight_type_id) AS weight_type_name,
  weight, 
  reps, 
  notes,
  created_at,
  updated_at
