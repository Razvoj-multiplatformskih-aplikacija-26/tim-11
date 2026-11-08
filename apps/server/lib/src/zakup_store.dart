import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

import 'dart:convert';

import 'package:api_contract/api_contract.dart';

import 'placanje_port.dart';

enum ProblemAkcijeZakupa { nijePronadjen, zabranjeno, placanjeOdbijeno }

final class ZakupStore {
  const ZakupStore(this._baza, {this.placanje = const DemoPlacanje()});

  final PlacanjePort placanje;

  final Connection _baza;

  Future<List<Zakup>> preuzmiZakupe({
    required String? zakupacId,
    bool prikaziZakupca = false,
    int? limit,
    int pomeraj = 0,
  }) => _ucitajZakupe(
    _baza,
    zakupacId: zakupacId,
    prikaziZakupca: prikaziZakupca,
    limit: limit,
    pomeraj: pomeraj,
  );

  Future<List<Zakup>> _ucitajZakupe(
    Session sesija, {
    String? zakupacId,
    String? zakupId,
    bool prikaziZakupca = false,
    int? limit,
    int pomeraj = 0,
  }) async {
    final redovi = await sesija.execute(
      Sql.named('''
        SELECT
          z.id,
          z.datum_od::text,
          z.datum_do::text,
          z.status,
          z.podaci_statusa::text,
          z.istorija::text,
          p.id,
          p.naziv,
          p.brend,
          p.kategorija,
          p.cena_po_danu,
          p.depozit,
          p.opis,
          p.vlasnik,
          CASE WHEN CAST(@prikaziZakupca AS boolean)
               THEN split_part(k.email, '@', 1)
          END
        FROM zakupi z
        JOIN predmeti p ON p.id = z.predmet_id
        JOIN korisnici k ON k.id = z.zakupac_id
        WHERE (CAST(@zakupac AS text) IS NULL
               OR z.zakupac_id = CAST(@zakupac AS text))
          AND (CAST(@zakup AS text) IS NULL
               OR z.id = CAST(@zakup AS text))
        ORDER BY z.datum_od DESC, z.id
        LIMIT CAST(@limit AS integer)
        OFFSET CAST(@pomeraj AS integer)
      '''),
      parameters: {
        'zakupac': zakupacId,
        'zakup': zakupId,
        'prikaziZakupca': prikaziZakupca,
        'limit': limit,
        'pomeraj': pomeraj,
      },
    );

    return [
      for (final red in redovi)
        zakupIzApi(
          ZakupDto(
            id: red[0] as String,
            oznakaZakupca: red[14] as String?,
            datumOd: red[1] as String,
            datumDo: red[2] as String,
            status: StatusZakupaDto(
              status: red[3] as String,
              podaci: jsonDecode(red[4] as String) as Map<String, Object?>,
            ),
            istorija: [
              for (final korak in jsonDecode(red[5] as String) as List<Object?>)
                StatusZakupaDto.fromJson(korak as Map<String, Object?>),
            ],
            predmet: PredmetDto(
              id: red[6] as String,
              naziv: red[7] as String,
              brend: red[8] as String,
              kategorija: red[9] as String,
              cenaPoDanu: red[10] as int,
              depozit: red[11] as int,
              opis: red[12] as String,
              vlasnik: red[13] as String,
            ),
          ),
        ),
    ];
  }

  Future<Rezultat<Zakup>> izvrsiAkciju({
    required String zakupId,
    required String korisnikId,
    required Uloga uloga,
    required AkcijaZakupa akcija,
    required DateTime sada,
    String? razlog,
  }) => _baza.runTx((transakcija) async {
    final vlasnici = await transakcija.execute(
      Sql.named('''
        SELECT zakupac_id
        FROM zakupi
        WHERE id = @id
        FOR UPDATE
      '''),
      parameters: {'id': zakupId},
    );

    if (vlasnici.isEmpty) {
      throw ProblemAkcijeZakupa.nijePronadjen;
    }

    final jeSvojZakup = vlasnici.single[0] == korisnikId;
    if (!imaPravoNaAkciju(
      uloga: uloga,
      akcija: akcija,
      jeSvojZakup: jeSvojZakup,
    )) {
      throw ProblemAkcijeZakupa.zabranjeno;
    }

    final zakupi = await _ucitajZakupe(
      transakcija,
      zakupId: zakupId,
      prikaziZakupca: uloga == Uloga.osoblje,
    );
    final zakup = zakupi.single;

    final rezultat = switch (akcija) {
      AkcijaZakupa.otkazi => otkaziZakup(zakup, sada: sada),
      AkcijaZakupa.plati => platiZakup(zakup),
      AkcijaZakupa.odobri => promeniStatus(zakup, const Odobren()),
      AkcijaZakupa.odbij => promeniStatus(zakup, Odbijen(razlog: razlog!)),
      AkcijaZakupa.resiSpor =>
        zakup.status is Sporan
            ? promeniStatus(zakup, const Zavrsen())
            : Neuspeh<Zakup>(
                NedozvoljenPrelaz(od: zakup.status, ka: const Zavrsen()),
              ),
    };

    final azuriran = rezultat.vrednostIliNull;
    if (azuriran == null) return rezultat;

    if (akcija == AkcijaZakupa.plati) {
      final odobreno = await placanje.autorizuj(
        zakupId: zakup.id,
        iznosEvra: zakup.ukupnaCena + zakup.predmet.depozit,
      );
      if (!odobreno) throw ProblemAkcijeZakupa.placanjeOdbijeno;
    }

    final dto = zakupZaApi(azuriran);
    await transakcija.execute(
      Sql.named('''
        UPDATE zakupi
        SET status = @status,
            podaci_statusa = CAST(@podaci AS text)::jsonb,
            istorija = CAST(@istorija AS text)::jsonb
        WHERE id = @id
      '''),
      parameters: {
        'id': zakupId,
        'status': dto.status.status,
        'podaci': jsonEncode(dto.status.podaci),
        'istorija': jsonEncode([
          for (final korak in dto.istorija) korak.toJson(),
        ]),
      },
    );

    return rezultat;
  });

  // null znači da traženi predmet ne postoji.
  Future<Rezultat<ZakupId>?> napraviZakup({
    required UnosZakupa unos,
    required String zakupacId,
    required DateTime danas,
  }) async {
    try {
      return await _baza.runTx(
        (transakcija) => _napraviZakup(
          transakcija,
          unos: unos,
          zakupacId: zakupacId,
          danas: danas,
        ),
      );
    } on ServerException catch (greska) {
      if (greska.code == '23P01' &&
          greska.constraintName == 'zakupi_bez_preklapanja') {
        return const Neuspeh<ZakupId>(TerminZauzet());
      }
      rethrow;
    }
  }

  Future<Rezultat<ZakupId>?> _napraviZakup(
    Session transakcija, {
    required UnosZakupa unos,
    required String zakupacId,
    required DateTime danas,
  }) async {
    final predmetId = unos.predmetId.toString();

    final predmeti = await transakcija.execute(
      Sql.named('''
        SELECT naziv, brend, kategorija, cena_po_danu, depozit, opis, vlasnik
        FROM predmeti
        WHERE id = @id
        FOR NO KEY UPDATE
      '''),
      parameters: {'id': predmetId},
    );

    if (predmeti.isEmpty) return null;

    final red = predmeti.single;
    final predmet = Predmet(
      id: unos.predmetId,
      naziv: red[0] as String,
      brend: red[1] as String,
      kategorija: Kategorija.values.byName(red[2] as String),
      cenaPoDanu: red[3] as int,
      depozit: red[4] as int,
      opis: red[5] as String,
      vlasnik: red[6] as String,
    );

    final redovi = await transakcija.execute(
      Sql.named('''
        SELECT id, datum_od::text, datum_do::text, status
        FROM zakupi
        WHERE predmet_id = @id
          AND status IN ('zahtev', 'odobren', 'placen', 'preuzet')
      '''),
      parameters: {'id': predmetId},
    );

    final postojeciZakupi = [
      for (final red in redovi)
        Zakup(
          id: ZakupId(red[0] as String),
          predmet: predmet,
          period: PeriodZakupa.izBaze(
            od: DateTime.parse(red[1] as String),
            doDatuma: DateTime.parse(red[2] as String),
          ),
          status: switch (red[3]) {
            'zahtev' => const Zahtev(),
            'odobren' => const Odobren(),
            'placen' => const Placen(),
            'preuzet' => const Preuzet(),
            _ => throw StateError('Neočekivan status zakupa.'),
          },
        ),
    ];

    final provera = proveriZahtev(
      predmet: predmet,
      od: unos.datumOd,
      doDatuma: unos.datumDo,
      danas: danas,
      postojeciZakupi: postojeciZakupi,
    );

    final period = provera.vrednostIliNull;
    if (period == null) {
      return Neuspeh<ZakupId>(provera.greskaIliNull!);
    }

    final zahtev = noviZakupZaApi((
      predmetId: unos.predmetId,
      datumOd: period.od,
      datumDo: period.doDatuma,
    ));

    final upis = await transakcija.execute(
      Sql.named('''
        INSERT INTO zakupi
          (id, predmet_id, zakupac_id, datum_od, datum_do, status, istorija)
        VALUES (
          'z-' || gen_random_uuid()::text,
          @predmet,
          @zakupac,
          CAST(@od AS text)::date,
          CAST(@doDatuma AS text)::date,
          'zahtev',
          '[{"status":"zahtev","podaci":{}}]'::jsonb
        )
        RETURNING id
      '''),
      parameters: {
        'predmet': predmetId,
        'zakupac': zakupacId,
        'od': zahtev.datumOd,
        'doDatuma': zahtev.datumDo,
      },
    );

    return Uspeh(ZakupId(upis.single[0] as String));
  }
}
