UPDATE exercises
SET updated_at = unixepoch(), name = $1
WHERE id = $2
RETURNING *
