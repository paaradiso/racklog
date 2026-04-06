--- migration:up
-- user is a reserved keyword
CREATE TABLE app_user (
    id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email text NOT NULL UNIQUE,
    hashed_password text NOT NULL,
    created_at timestamp NOT NULL DEFAULT NOW(),
    updated_at timestamp NOT NULL DEFAULT NOW()
);

CREATE TRIGGER app_user_updated_at
    BEFORE UPDATE ON app_user
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at ();

--- migration:down
DROP TRIGGER app_user_updated_at ON app_user;

DROP TABLE app_user;

--- migration:end
