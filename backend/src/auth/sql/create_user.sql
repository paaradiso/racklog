INSERT INTO app_user (username, email, hashed_password)
    VALUES ($1, $2, $3)
RETURNING
    *
