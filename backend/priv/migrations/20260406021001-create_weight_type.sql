--- migration:up
CREATE TABLE weight_type (
    id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE,
    created_at timestamp NOT NULL DEFAULT NOW(),
    updated_at timestamp NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION set_updated_at ()
    RETURNS TRIGGER
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER weight_type_updated_at
    BEFORE UPDATE ON weight_type
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at ();

--- migration:down
DROP FUNCTION IF EXISTS set_updated_at ();

DROP TABLE weight_type;

--- migration:end
