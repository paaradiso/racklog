SELECT
    *
FROM
    workout
WHERE
    user_id = $1
    AND ended_at IS NULL
LIMIT 1;

