import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart';
import 'package:api_contract/api_contract.dart';
import 'package:rent_a_luxury_server/src/zakup_handler.dart';
import 'package:rent_a_luxury_server/src/zakup_store.dart';
import 'package:rent_a_luxury_server/src/sesija_handler.dart';
import 'package:rent_a_luxury_server/src/sesija_store.dart';
import 'package:rent_a_luxury_server/src/cors.dart';
import 'package:rent_a_luxury_server/src/katalog_handler.dart';

Future<void> main() async {
  final env = Platform.environment;

  final database = await Connection.open(
    Endpoint(
      host: 'db',
      database: env['POSTGRES_DB']!,
      username: env['POSTGRES_USER']!,
      password: env['POSTGRES_PASSWORD']!,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  final app = RelicApp();
  app.use(
    '/',
    corsZaBackoffice(env['BACKOFFICE_ORIGIN'] ?? 'http://127.0.0.1:5173'),
  );

  for (final putanja in [
    putanjaPrijave,
    putanjaOdjave,
    putanjaZakupa,
    putanjaAkcijeZakupa,
  ]) {
    app.add(Method.options, putanja, (_) => Response.noContent());
  }
  app.get('/health', (request) async {
    await database.execute('SELECT 1');
    return Response.ok(body: Body.fromString('Server i baza rade.'));
  });

  final zakupStore = ZakupStore(database);
  final ttlMinuta = int.parse(env['SESSION_TTL_MINUTES'] ?? '480');
  if (ttlMinuta <= 0) {
    throw StateError('SESSION_TTL_MINUTES mora biti veći od nule.');
  }

  final sesije = SesijaStore(database, ttlMinuta: ttlMinuta);

  Future<({String id, String uloga})?> procitajSesiju(Request request) async {
    final token = bearerToken(request);
    return token == null ? null : await sesije.procitaj(token);
  }

  app.post(putanjaPrijave, prijavaHandler(sesije));
  app.post(putanjaOdjave, odjavaHandler(sesije));

  app.get(
    putanjaZakupa,
    preuzmiZakupeHandler(store: zakupStore, procitajSesiju: procitajSesiju),
  );
  app.post(
    putanjaZakupa,
    napraviZakupHandler(store: zakupStore, procitajSesiju: procitajSesiju),
  );
  app.post(
    putanjaAkcijeZakupa,
    akcijaZakupaHandler(store: zakupStore, procitajSesiju: procitajSesiju),
  );
  app.get(putanjaPredmeta, katalogHandler(database));
  app.get(putanjaZauzetihPerioda, zauzetiPeriodiHandler(database));

  await app.serve(address: InternetAddress.anyIPv4, port: 8080);
}
