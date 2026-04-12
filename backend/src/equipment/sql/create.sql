INSERT INTO equipment (name)
    VALUES ($1)
RETURNING
    *
