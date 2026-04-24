-- 001_init.sql
-- Initial schema for ironwall. Idempotent — safe to re-run.

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    username     text        NOT NULL UNIQUE,
    display_name text        NOT NULL,
    weight_unit  text        NOT NULL DEFAULT 'lb' CHECK (weight_unit IN ('lb', 'kg')),
    created_at   timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- tags  (global, seeded below)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tags (
    id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name  text NOT NULL UNIQUE,
    color text NOT NULL
);

-- ---------------------------------------------------------------------------
-- exercises
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS exercises (
    id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    name       text        NOT NULL,
    user_id    uuid        REFERENCES users(id) ON DELETE CASCADE,
    notes      text,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Global exercise names must be unique among globals.
CREATE UNIQUE INDEX IF NOT EXISTS exercises_name_global_uniq
    ON exercises (name)
    WHERE user_id IS NULL;

-- Per-user exercise names must be unique within that user's library.
CREATE UNIQUE INDEX IF NOT EXISTS exercises_name_user_uniq
    ON exercises (name, user_id)
    WHERE user_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- exercise_tags  (many-to-many)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS exercise_tags (
    exercise_id uuid NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    tag_id      uuid NOT NULL REFERENCES tags(id)      ON DELETE CASCADE,
    PRIMARY KEY (exercise_id, tag_id)
);

-- ---------------------------------------------------------------------------
-- workouts
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS workouts (
    id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    uuid        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    started_at timestamptz NOT NULL,
    ended_at   timestamptz CHECK (ended_at >= started_at),
    notes      text,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- workout_exercises
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS workout_exercises (
    id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id     uuid        NOT NULL REFERENCES workouts(id)  ON DELETE CASCADE,
    exercise_id    uuid        NOT NULL REFERENCES exercises(id),
    position       integer     NOT NULL,
    superset_group integer,
    notes          text,
    created_at     timestamptz NOT NULL DEFAULT now(),
    UNIQUE (workout_id, position)
);

-- ---------------------------------------------------------------------------
-- sets
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sets (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_exercise_id uuid        NOT NULL REFERENCES workout_exercises(id) ON DELETE CASCADE,
    set_number          integer     NOT NULL,
    weight              numeric(8,3),
    weight_unit         text        CHECK (weight_unit IN ('lb', 'kg')),
    weight_kg           numeric(8,3) GENERATED ALWAYS AS (
                            CASE
                                WHEN weight IS NULL     THEN NULL
                                WHEN weight_unit = 'kg' THEN weight
                                WHEN weight_unit = 'lb' THEN weight / 2.20462
                            END
                        ) STORED,
    reps                integer,
    partials            integer     NOT NULL DEFAULT 0,
    rpe                 numeric(3,1) CHECK (rpe BETWEEN 1 AND 10),
    set_type            text        NOT NULL CHECK (set_type IN ('warmup', 'working', 'amrap', 'dropset', 'failure')),
    notes               text,
    logged_at           timestamptz NOT NULL DEFAULT now(),
    UNIQUE (workout_exercise_id, set_number)
);

-- Tags are seeded via seeds/tags.sql, generated from data/tags.yaml.
