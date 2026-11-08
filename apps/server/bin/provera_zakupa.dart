import 'dart:io';

import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';
import 'package:rent_a_luxury_server/src/zakup_store.dart';

Future<Connection> otvoriBazu() {
  final env = Platform.environment;

  return Connection.open(
    Endpoint(
      host: 'db',
      database: env['POSTGRES_DB']!,
      username: env['POSTGRES_USER']!,
      password: env['POSTGRES_PASSWORD']!,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );
}

Future<void> main() async {
  final prvaVeza = await otvoriBazu();
  try {
    final drugaVeza = await otvoriBazu();
    try {
      await proveriZakup(prvaVeza, drugaVeza);
    } finally {
      await drugaVeza.close();
    }
  } finally {
    await prvaVeza.close();
  }
}

Future<void> proveriZakup(Connection prvaVeza, Connection drugaVeza) async {
  final store = ZakupStore(prvaVeza);
  final svi = await store.preuzmiZakupe(zakupacId: null);
  final prvi = await store.preuzmiZakupe(zakupacId: 'u-1');
  final drugi = await store.preuzmiZakupe(zakupacId: 'u-2');

  final prviIds = prvi.map((zakup) => zakup.id).toSet();
  final drugiIds = drugi.map((zakup) => zakup.id).toSet();

  if (prviIds.isEmpty ||
      drugiIds.isEmpty ||
      prviIds.intersection(drugiIds).isNotEmpty ||
      prviIds.union(drugiIds).length != svi.length) {
    throw StateError('Zakupi nisu ispravno odvojeni po demo zakupcima.');
  }

  stdout.writeln('PROŠLO: svaki demo zakupac dobija samo svoje zakupe.');
  final redovi = await prvaVeza.execute('''
    INSERT INTO predmeti
      (id, naziv, brend, kategorija, cena_po_danu, depozit, opis, vlasnik)
    VALUES (
      'test-' || gen_random_uuid()::text,
      'Probni predmet', 'Demo', 'torba', 45, 800, 'Integraciona provera', 'Demo'
    )
    RETURNING id
  ''');
  final predmetId = redovi.single[0] as String;
  final parametri = {'id': predmetId};

  try {
    final prviStore = ZakupStore(prvaVeza);
    final drugiStore = ZakupStore(drugaVeza);
    final danas = samoDatum(DateTime.now());
    final datumOd = danas.add(const Duration(days: 7));

    final predugZakup = await prviStore.napraviZakup(
      unos: (
        predmetId: PredmetId(predmetId),
        datumOd: datumOd,
        datumDo: datumOd.add(const Duration(days: PeriodZakupa.maxDana)),
      ),
      zakupacId: 'u-1',
      danas: danas,
    );
    final greskaTrajanja = predugZakup?.greskaIliNull;
    if (greskaTrajanja is! NedozvoljenoTrajanje) {
      throw StateError('Očekivana je greška NedozvoljenoTrajanje.');
    }
    final odgovorTrajanja = greskaNovogZakupaZaApi(greskaTrajanja);
    if (odgovorTrajanja.httpStatus != 422 ||
        odgovorTrajanja.greska.kod != 'nedozvoljeno_trajanje' ||
        odgovorTrajanja.greska.podaci['maxDana'] != PeriodZakupa.maxDana) {
      throw StateError('Greška trajanja nije ispravno mapirana.');
    }

    final unos = (
      predmetId: PredmetId(predmetId),
      datumOd: datumOd,
      datumDo: datumOd,
    );

    final ishodi = await Future.wait([
      prviStore.napraviZakup(unos: unos, zakupacId: 'u-1', danas: danas),
      drugiStore.napraviZakup(unos: unos, zakupacId: 'u-2', danas: danas),
    ]);

    final brojUspeha = ishodi.whereType<Uspeh<ZakupId>>().length;
    final zauzeti = ishodi
        .map((ishod) => ishod?.greskaIliNull)
        .whereType<TerminZauzet>()
        .toList();

    if (brojUspeha != 1 || zauzeti.length != 1) {
      throw StateError('Očekivan je jedan uspeh i jedan TerminZauzet: $ishodi');
    }
    final odgovorPreklapanja = greskaNovogZakupaZaApi(zauzeti.single);
    if (odgovorPreklapanja.httpStatus != 409 ||
        odgovorPreklapanja.greska.kod != 'termin_zauzet') {
      throw StateError('Greška zauzetog termina nije ispravno mapirana.');
    }

    final upisi = await prvaVeza.execute(
      Sql.named('SELECT status FROM zakupi WHERE predmet_id = @id'),
      parameters: parametri,
    );
    if (upisi.length != 1 || upisi.single[0] != 'zahtev') {
      throw StateError(
        'U bazi treba da ostane tačno jedan zakup u statusu zahtev.',
      );
    }

    stdout.writeln('PROŠLO: predug zakup daje 422 nedozvoljeno_trajanje.');
    stdout.writeln(
      'PROŠLO: paralelni upisi daju jedan uspeh i jedan 409 termin_zauzet.',
    );
    stdout.writeln('PROŠLO: u bazi je upisan tačno jedan probni zakup.');
  } finally {
    await prvaVeza.runTx((transakcija) async {
      await transakcija.execute(
        Sql.named('DELETE FROM zakupi WHERE predmet_id = @id'),
        parameters: parametri,
      );
      await transakcija.execute(
        Sql.named('DELETE FROM predmeti WHERE id = @id'),
        parameters: parametri,
      );
    });
  }
}
