INSERT INTO app_user (username, email, hashed_password, user_role)
    VALUES ($1, $2, $3, $4)
RETURNING
    *
