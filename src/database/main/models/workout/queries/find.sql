SELECT 
  w.id, 
  w.exercise_id,
  e.name AS exercise_name,
  w.weight_type_id,
  wt.name AS weight_type_name,
  w.weight, 
  w.reps, 
  w.notes,
  w.created_at
FROM workouts w
JOIN exercises e ON w.exercise_id = e.id
JOIN weight_types wt ON w.weight_type_id = wt.id
WHERE w.id = $1
ORDER BY w.created_at DESC;
