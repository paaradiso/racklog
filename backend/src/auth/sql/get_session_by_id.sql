SELECT
    *
FROM
    session
WHERE
    id = $1
    AND expires_at > now();

