INSERT INTO exercises (name, created_at, updated_at)
VALUES ($1, unixepoch(), unixepoch())
RETURNING *
