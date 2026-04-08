--- migration:up
CREATE TYPE app_user_role AS enum (
    'user',
    'admin'
);

ALTER TABLE app_user
    ADD COLUMN user_role app_user_role NOT NULL DEFAULT 'user';

--- migration:down
ALTER TABLE app_user
    DROP COLUMN user_role;

DROP TYPE app_user_role;

--- migration:end
