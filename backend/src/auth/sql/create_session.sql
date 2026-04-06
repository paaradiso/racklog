INSERT INTO session (id, user_id)
    VALUES ($1, $2)
RETURNING
    *;

