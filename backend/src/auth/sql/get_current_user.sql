SELECT
    id,
    username,
    email
FROM
    app_user
WHERE
    id = $1;

