--- migration:up
ALTER TABLE app_user
    ADD COLUMN username text NOT NULL UNIQUE;

--- migration:down
ALTER TABLE app_user
    DROP COLUMN username;

--- migration:end

