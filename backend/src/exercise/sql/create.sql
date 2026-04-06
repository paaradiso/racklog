INSERT INTO exercise (name)
    VALUES ($1)
RETURNING
    *
