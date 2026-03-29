-- TODO: Add the columns you'd like to insert in your preferred 
-- order and update the placeholders

INSERT INTO weight_types (name, created_at, updated_at)
VALUES ($1, unixepoch(), unixepoch())
RETURNING *
