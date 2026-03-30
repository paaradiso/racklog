SELECT 
  w.id, 
  w.exercise_id,
  e.name AS exercise_name,
  w.weight_type_id,
  wt.name AS weight_type_name,
  w.weight, 
  w.reps, 
  w.notes,
  w.created_at,
  w.updated_at
FROM workouts w
JOIN exercises e ON w.exercise_id = e.id
JOIN weight_types wt ON w.weight_type_id = wt.id
ORDER BY w.created_at DESC;
