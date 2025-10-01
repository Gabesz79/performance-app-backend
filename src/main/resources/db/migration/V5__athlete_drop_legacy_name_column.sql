-- Backfill full_name from legacy name (if both exist), then drop legacy column

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='athlete' AND column_name='name'
  ) THEN
    -- Ha van full_name, töltsük fel belőle, különben nevezzük át a name-et full_name-ra
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='athlete' AND column_name='full_name'
    ) THEN
      EXECUTE 'UPDATE public.athlete SET full_name = COALESCE(full_name, name)';
    ELSE
      EXECUTE 'ALTER TABLE public.athlete RENAME COLUMN name TO full_name';
    END IF;

    -- Ha még mindig létezik a legacy name oszlop, dobjuk el
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='athlete' AND column_name='name'
    ) THEN
      EXECUTE 'ALTER TABLE public.athlete DROP COLUMN name';
    END IF;
  END IF;
END $$;

-- Biztonság kedvéért legyen NOT NULL a full_name
ALTER TABLE public.athlete
  ALTER COLUMN full_name SET NOT NULL;
