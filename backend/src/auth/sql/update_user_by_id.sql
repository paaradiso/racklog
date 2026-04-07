UPDATE
    app_user
SET
    email = COALESCE(NULLIF ($1, ''), email),
    hashed_password = COALESCE(NULLIF ($2, ''), hashed_password)
WHERE
    id = $3
RETURNING
    *;

