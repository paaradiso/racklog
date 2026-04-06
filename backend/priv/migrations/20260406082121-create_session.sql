--- migration:up
CREATE TABLE session (
    id text PRIMARY KEY,
    user_id int NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
    created_at timestamp NOT NULL DEFAULT NOW(),
    expires_at timestamp NOT NULL DEFAULT NOW() + interval '30 days'
);

--- migration:down
DROP TABLE session;

--- migration:end

