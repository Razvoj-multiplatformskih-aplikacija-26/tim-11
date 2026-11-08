BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO korisnici (id, email, lozinka_hes, uloga)
SELECT id, email, crypt('RentDemo2026!', gen_salt('bf', 12)), uloga
FROM (VALUES
    ('u-1', 'zakupac1@demo.test', 'zakupac'),
    ('u-2', 'zakupac2@demo.test', 'zakupac'),
    ('u-3', 'osoblje@demo.test', 'osoblje')
) AS nalozi(id, email, uloga)
ON CONFLICT (id) DO NOTHING;

INSERT INTO predmeti
    (id, naziv, brend, kategorija, cena_po_danu, depozit, opis, vlasnik)
VALUES
    ('p-1', 'Lady Dior torba', 'Dior', 'torba', 45, 800, 'Bela jagnjeća koža.', 'Ana N.'),
    ('p-2', 'Submariner', 'Rolex', 'sat', 90, 2500, 'Čelik i plavi brojčanik.', 'Marko P.'),
    ('p-3', 'Love narukvica', 'Cartier', 'nakit', 60, 1500, 'Žuto zlato, veličina 17.', 'Ivana K.'),
    ('p-4', 'Classic Flap', 'Chanel', 'torba', 55, 1000, 'Plava prošivena koža.', 'Jelena M.'),
    ('p-5', 'Speedmaster Moonwatch', 'Omega', 'sat', 50, 1200, 'Hronograf sa crnim brojčanikom.', 'Nikola S.'),
    ('p-6', 'HardWear ogrlica', 'Tiffany & Co.', 'nakit', 35, 600, 'Srebrna ogrlica, 45 cm.', 'Ivana K.'),
    ('p-7', 'Jackie 1961', 'Gucci', 'torba', 35, 600, 'Mala torba od teget kože.', 'Ana T.'),
    ('p-8', 'Večernja haljina', 'Valentino', 'odeca', 70, 900, 'Bež svilena haljina, veličina 38.', 'Milica R.'),
    ('p-9', 'Santos naočare', 'Cartier', 'naocare', 25, 400, 'Naočare za sunce.', 'Marko P.'),
    ('p-10', 'Birkin 30', 'Hermès', 'torba', 150, 5000, 'Crna Togo koža.', 'Nikola S.')
ON CONFLICT (id) DO NOTHING;

WITH demo(id, predmet_id, zakupac_id, od, do_dana, tok, podaci) AS (
    VALUES
        ('z-1', 'p-1', 'u-1', 10, 12, 'zahtev', '{}'::jsonb),
        ('z-2', 'p-4', 'u-2', 1, 3, 'zahtev', '{}'::jsonb),
        ('z-3', 'p-2', 'u-1', 5, 7, 'zahtev,odobren', '{}'::jsonb),
        ('z-4', 'p-3', 'u-2', 3, 6, 'zahtev,odobren,placen', '{}'::jsonb),
        ('z-5', 'p-5', 'u-1', -2, 1, 'zahtev,odobren,placen,preuzet', '{}'::jsonb),
        ('z-6', 'p-6', 'u-2', -6, -1, 'zahtev,odobren,placen,preuzet,vracen', '{}'::jsonb),
        ('z-7', 'p-7', 'u-1', -30, -27, 'zahtev,odobren,placen,preuzet,vracen,zavrsen', '{}'::jsonb),
        ('z-8', 'p-1', 'u-2', -20, -18, 'zahtev,odobren,placen,preuzet,vracen,zavrsen', '{}'::jsonb),
        ('z-9', 'p-8', 'u-1', 15, 17, 'zahtev,odbijen',
            '{"razlog":"Haljina je na hemijskom čišćenju."}'::jsonb),
        ('z-10', 'p-9', 'u-2', -10, -8, 'zahtev,otkazan',
            jsonb_build_object(
                'otkazanoU', (CURRENT_DATE - 13)::text || 'T00:00:00Z',
                'besplatno', true
            )),
        ('z-11', 'p-10', 'u-1', -14, -10, 'zahtev,odobren,placen,preuzet,vracen,sporan',
            '{"opis":"Ogrebotina na kopči."}'::jsonb),
        ('z-12', 'p-2', 'u-2', 20, 25, 'zahtev,odobren,placen', '{}'::jsonb)
),
pripremljeni AS (
    SELECT *, string_to_array(tok, ',') AS statusi
    FROM demo
)
INSERT INTO zakupi
    (id, predmet_id, zakupac_id, datum_od, datum_do, status, podaci_statusa, istorija)
SELECT
    id,
    predmet_id,
    zakupac_id,
    CURRENT_DATE + od,
    CURRENT_DATE + do_dana,
    statusi[cardinality(statusi)],
    podaci,
    (
        SELECT jsonb_agg(
            jsonb_build_object(
                'status', korak,
                'podaci', CASE WHEN redni_broj = cardinality(statusi)
                    THEN podaci ELSE '{}'::jsonb END
            ) ORDER BY redni_broj
        )
        FROM unnest(statusi) WITH ORDINALITY AS istorija(korak, redni_broj)
    )
FROM pripremljeni
ON CONFLICT (id) DO NOTHING;

COMMIT;