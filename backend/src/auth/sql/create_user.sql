INSERT INTO app_user (email, hashed_password)
    VALUES ($1, $2)
RETURNING
    *
