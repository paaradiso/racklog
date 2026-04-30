INSERT INTO workout (user_id)
    VALUES ($1)
RETURNING
    id;

