--- migration:up
CREATE TABLE exercise (
    id serial PRIMARY KEY,
    name text NOT NULL UNIQUE,
    created_at timestamp NOT NULL DEFAULT NOW(),
    updated_at timestamp NOT NULL DEFAULT NOW()
);

CREATE TRIGGER exercise_updated_at
    BEFORE UPDATE ON exercise
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at ();

--- migration:down
DROP TRIGGER exercise_updated_at ON exercise;

DROP TABLE exercise;

--- migration:end
