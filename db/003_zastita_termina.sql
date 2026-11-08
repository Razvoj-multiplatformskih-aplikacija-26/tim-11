BEGIN;

CREATE EXTENSION IF NOT EXISTS btree_gist;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'public.zakupi'::regclass
          AND conname = 'zakupi_bez_preklapanja'
    ) THEN
        ALTER TABLE public.zakupi
        ADD CONSTRAINT zakupi_bez_preklapanja
        EXCLUDE USING gist (
            predmet_id WITH =,
            daterange(datum_od, datum_do, '[]') WITH &&
        )
        WHERE (status IN ('zahtev', 'odobren', 'placen', 'preuzet'));
    END IF;
END
$$;

COMMIT;