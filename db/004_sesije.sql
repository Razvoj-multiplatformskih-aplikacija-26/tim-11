BEGIN;

CREATE TABLE IF NOT EXISTS sesije (
    token_hes text PRIMARY KEY,
    korisnik_id text NOT NULL REFERENCES korisnici(id) ON DELETE CASCADE,
    istice_u timestamptz NOT NULL
);

COMMIT;