DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'athlete'
      AND column_name = 'name'
  ) THEN
    ALTER TABLE public.athlete ADD COLUMN name varchar(120);
    UPDATE public.athlete SET name = 'Unnamed' WHERE name IS NULL;
    ALTER TABLE public.athlete ALTER COLUMN name SET NOT NULL;
  END IF;
END $$;
