BEGIN;

CREATE TABLE IF NOT EXISTS korisnici (
    id text PRIMARY KEY,
    email text NOT NULL UNIQUE,
    lozinka_hes text NOT NULL,
    uloga text NOT NULL CHECK (uloga IN ('zakupac', 'osoblje'))
);

CREATE TABLE IF NOT EXISTS predmeti (
    id text PRIMARY KEY,
    naziv text NOT NULL,
    brend text NOT NULL,
    kategorija text NOT NULL,
    cena_po_danu integer NOT NULL CHECK (cena_po_danu >= 0),
    depozit integer NOT NULL CHECK (depozit >= 0),
    opis text NOT NULL,
    vlasnik text NOT NULL
);

CREATE TABLE IF NOT EXISTS zakupi (
    id text PRIMARY KEY,
    predmet_id text NOT NULL REFERENCES predmeti(id),
    zakupac_id text NOT NULL REFERENCES korisnici(id),
    datum_od date NOT NULL,
    datum_do date NOT NULL,
    status text NOT NULL CHECK (
        status IN (
            'zahtev', 'odobren', 'placen', 'preuzet', 'vracen',
            'zavrsen', 'odbijen', 'otkazan', 'sporan'
        )
    ),
    podaci_statusa jsonb NOT NULL DEFAULT '{}'::jsonb,
    istorija jsonb NOT NULL,
    CHECK (datum_do >= datum_od)
);

CREATE INDEX IF NOT EXISTS zakupi_predmet_idx ON zakupi (predmet_id);
CREATE INDEX IF NOT EXISTS zakupi_zakupac_idx ON zakupi (zakupac_id);

COMMIT;