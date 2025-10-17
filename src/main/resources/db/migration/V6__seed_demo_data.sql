-- V6__seed_demo_data.sql
-- Seed: 2 athlete + ~8 workout
-- Idempotens: csak akkor szúr be, ha még nincs bent ugyanaz.
-- OSZLOPNEVEK: a workout táblában az alábbi neveket használom:
--   created_at (TIMESTAMP), duration_minutes (INT), rpe (SMALLINT),
--   workout_type (VARCHAR), distance_km (NUMERIC), notes (TEXT)

------------------------------------------------------------
-- 1) Athletes: beszúrás csak ha még nincs ilyen email
------------------------------------------------------------
INSERT INTO athlete (full_name, email)
VALUES ('Kovács Alice', 'alice.demo@perf.local')
ON CONFLICT ON CONSTRAINT uq_athlete_email DO NOTHING;

INSERT INTO athlete (full_name, email)
VALUES ('Nagy Bálint', 'balint.demo@perf.local')
ON CONFLICT ON CONSTRAINT uq_athlete_email DO NOTHING;

------------------------------------------------------------
-- 1) Athletes: beszúrás csak ha az email nem létezik
------------------------------------------------------------
DO $$
DECLARE
  v_alice_id bigint;
  v_balint_id bigint;
  v_sport_col text;
BEGIN
  ----------------------------------------------------------------
  -- sport/workout_type oszlopnév eldöntése
  ----------------------------------------------------------------
  IF EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='workout_session' AND column_name='sport'
  ) THEN
    v_sport_col := 'sport';
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='workout_session' AND column_name='workout_type'
  ) THEN
    v_sport_col := 'workout_type';
  ELSE
    RAISE EXCEPTION 'Neither "sport" nor "workout_type" column exists on public.workout_session';
  END IF;

  --athlete_id:
  SELECT id INTO v_alice_id FROM athlete WHERE email = 'alice.demo@perf.local' ORDER BY id LIMIT 1;
  SELECT id INTO v_balint_id FROM athlete WHERE email = 'balint.demo@perf.local' ORDER BY id LIMIT 1;


  ----------------------------------------------------------------
  -- helper: NOT EXISTS-es beszúrás dinamikus sport oszlopra
  -- params: (athlete_id, date, sport_value, minutes, rpe, notes)
  -- minta-hívás lent ismételve
  ----------------------------------------------------------------
  -- =============== Alice: 5 workout ===============
  EXECUTE format($q$
    INSERT INTO public.workout_session(athlete_id, session_date, %I, duration_minutes, rpe, notes)
    SELECT $1,$2,$3,$4,$5,$6
    WHERE NOT EXISTS (
      SELECT 1 FROM public.workout_session WHERE athlete_id=$1 AND session_date=$2 AND %I=$3)$q$, v_sport_col, v_sport_col)
    USING v_alice_id, DATE '2025-09-28', 'RUN', 45, 6, 'Állóképesség - Margitsziget';

  EXECUTE format($q$
    INSERT INTO public.workout_session(athlete_id, session_date, %I, duration_minutes, rpe, notes)
    SELECT $1,$2,$3,$4,$5,$6
    WHERE NOT EXISTS (
      SELECT 1 FROM public.workout_session WHERE athlete_id=$1 AND session_date=$2 AND %I=$3)$q$, v_sport_col, v_sport_col)
  USING v_alice_id, DATE '2025-09-30', 'GYM', 30, 5, 'Teljes testes erősítő köredzés';

  EXECUTE format($q$
    INSERT INTO public.workout_session(athlete_id, session_date, %I, duration_minutes, rpe, notes)
    SELECT $1,$2,$3,$4,$5,$6
    WHERE NOT EXISTS (
      SELECT 1 FROM public.workout_session WHERE athlete_id=$1 AND session_date=$2 AND %I=$3)$q$, v_sport_col, v_sport_col)
  USING v_alice_id, DATE '2025-10-02', 'BIKE', 60, 7, 'Bringázás- könnyű emelkedők';

  EXECUTE format($q$
    INSERT INTO public.workout_session(athlete_id, session_date, %I, duration_minutes, rpe, notes)
    SELECT $1,$2,$3,$4,$5,$6
    WHERE NOT EXISTS (
      SELECT 1 FROM public.workout_session WHERE athlete_id=$1 AND session_date=$2 AND %I=$3)$q$, v_sport_col, v_sport_col)
    USING v_alice_id, DATE '2025-10-04', 'RUN', 50, 8, 'Tempófutás - 2x10 perc @ erősebb tempó';

  EXECUTE format($q$
    INSERT INTO public.workout_session(athlete_id, session_date, %I, duration_minutes, rpe, notes)
    SELECT $1,$2,$3,$4,$5,$6
    WHERE NOT EXISTS (
      SELECT 1 FROM public.workout_session WHERE athlete_id=$1 AND session_date=$2 AND %I=$3)$q$, v_sport_col, v_sport_col)
    USING v_alice_id, DATE '2025-10-05', 'YOGA', 25, 3, 'Laza mobilitás/jóga, regeneráló';

  -- =============== Bálint: 3 workout ===============

  EXECUTE format($q$
    INSERT INTO public.workout_session(athlete_id, session_date, %I, duration_minutes, rpe, notes)
    SELECT $1,$2,$3,$4,$5,$6
    WHERE NOT EXISTS (
      SELECT 1 FROM public.workout_session WHERE athlete_id=$1 AND session_date=$2 AND %I=$3)$q$, v_sport_col, v_sport_col)
    USING v_balint_id, DATE '2025-09-29', 'SWIM', 40, 5, 'Úszás - technika + könnyű intervallok';

  EXECUTE format($q$
    INSERT INTO public.workout_session(athlete_id, session_date, %I, duration_minutes, rpe, notes)
    SELECT $1,$2,$3,$4,$5,$6
    WHERE NOT EXISTS (
      SELECT 1 FROM public.workout_session WHERE athlete_id=$1 AND session_date=$2 AND %I=$3)$q$, v_sport_col, v_sport_col)
    USING v_balint_id, DATE '2025-10-01', 'RUN', 55, 7, 'Dombos futás - pulzus kontroll';

  EXECUTE format($q$
    INSERT INTO public.workout_session(athlete_id, session_date, %I, duration_minutes, rpe, notes)
    SELECT $1,$2,$3,$4,$5,$6
    WHERE NOT EXISTS (
      SELECT 1 FROM public.workout_session WHERE athlete_id=$1 AND session_date=$2 AND %I=$3)$q$, v_sport_col, v_sport_col)
    USING v_balint_id, DATE '2025-10-03', 'GYM', 35, 6, 'Felsőtest fókusz + core';

  END$$;
