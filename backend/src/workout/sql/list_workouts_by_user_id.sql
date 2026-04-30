SELECT
    *
FROM
    workout
WHERE
    user_id = $1
ORDER BY
    started_at DESC;

