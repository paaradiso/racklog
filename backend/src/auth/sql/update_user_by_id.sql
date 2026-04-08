UPDATE
    app_user
SET
    username = COALESCE(NULLIF ($1, ''), username),
    email = COALESCE(NULLIF ($2, ''), email),
    hashed_password = COALESCE(NULLIF ($3, ''), hashed_password)
WHERE
    id = $4
RETURNING
    *;

