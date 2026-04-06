INSERT INTO weight_type (name)
    VALUES ($1)
RETURNING
    *
