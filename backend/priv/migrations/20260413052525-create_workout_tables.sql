--- migration:up
CREATE TABLE workout (
    id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id int NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
    name text,
    started_at timestamp NOT NULL DEFAULT NOW(),
    ended_at timestamp,
    notes text,
    created_at timestamp NOT NULL DEFAULT NOW(),
    updated_at timestamp NOT NULL DEFAULT NOW()
);

CREATE TRIGGER workout_updated_at
    BEFORE UPDATE ON workout
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at ();

CREATE TABLE workout_exercise (
    id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    workout_id int NOT NULL REFERENCES workout (id) ON DELETE CASCADE,
    exercise_id int NOT NULL REFERENCES exercise (id) ON DELETE RESTRICT,
    equipment_id int NOT NULL REFERENCES equipment (id) ON DELETE RESTRICT,
    sort_order int NOT NULL,
    notes text,
    created_at timestamp NOT NULL DEFAULT NOW(),
    updated_at timestamp NOT NULL DEFAULT NOW()
);

CREATE TRIGGER workout_exercise_updated_at
    BEFORE UPDATE ON workout_exercise
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at ();

CREATE TABLE workout_set (
    id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    workout_exercise_id int NOT NULL REFERENCES workout_exercise (id) ON DELETE CASCADE,
    sort_order int NOT NULL,
    reps int,
    weight numeric(5, 2),
    duration_seconds int,
    rpe numeric(3, 1),
    is_complete boolean NOT NULL DEFAULT FALSE,
    created_at timestamp NOT NULL DEFAULT NOW(),
    updated_at timestamp NOT NULL DEFAULT NOW()
);

CREATE TRIGGER workout_set_updated_at
    BEFORE UPDATE ON workout_set
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at ();

--- migration:down
DROP TRIGGER workout_updated_at ON workout;

DROP TABLE workout;

DROP TRIGGER workout_set_updated_at ON workout_set;

DROP TABLE workout_set;

DROP TRIGGER workout_exercise_updated_at ON workout_exercise;

DROP TABLE workout_exercise;

--- migration:end

