--- migration:up
CREATE TYPE preferred_unit AS enum (
    'kg',
    'lb'
);

ALTER TABLE app_user
    ADD COLUMN preferred_unit preferred_unit NOT NULL DEFAULT 'kg';

--- migration:down
ALTER TABLE app_user
    DROP COLUMN preferred_unit;

DROP TYPE preferred_unit;

--- migration:end

