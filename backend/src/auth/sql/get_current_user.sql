SELECT
    id,
    username,
    email,
    user_role
FROM
    app_user
WHERE
    id = $1;

