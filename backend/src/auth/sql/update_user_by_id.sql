UPDATE
    app_user
SET
    username = COALESCE(NULLIF ($1, ''), username),
    email = COALESCE(NULLIF ($2, ''), email),
    hashed_password = COALESCE(NULLIF ($3, ''), hashed_password),
    user_role = COALESCE(NULLIF ($4::text, '')::app_user_role, user_role),
    preferred_unit = COALESCE(NULLIF ($5::text, '')::preferred_unit, preferred_unit)
WHERE
    id = $5
RETURNING
    *;

