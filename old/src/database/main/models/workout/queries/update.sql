UPDATE workouts
SET 
  updated_at = unixepoch(), 
  user_id = $1,
  exercise_id = $2, 
  weight_type_id = $3, 
  weight = $4, 
  reps = $5, 
  notes = $6
WHERE id = $7
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
