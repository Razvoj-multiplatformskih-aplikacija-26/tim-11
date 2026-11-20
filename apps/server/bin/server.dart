import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart';
import 'package:rent_a_luxury_server/src/cors.dart';
import 'package:rent_a_luxury_server/src/jwt_sesije.dart';
import 'package:rent_a_luxury_server/src/katalog_handler.dart';
import 'package:rent_a_luxury_server/src/sesija_handler.dart';
import 'package:rent_a_luxury_server/src/sesija_store.dart';
import 'package:rent_a_luxury_server/src/zakup_handler.dart';
import 'package:rent_a_luxury_server/src/zakup_store.dart';

Future<void> main() async {
  final env = Platform.environment;

  final ttlMinuta = int.parse(
    env['SESSION_TTL_MINUTES'] ?? '480',
  );

  if (ttlMinuta <= 0) {
    throw StateError('SESSION_TTL_MINUTES mora biti veći od nule.');
  }

  final tajna = env['JWT_SECRET'];

  if (tajna == null || tajna.length < 32) {
    throw StateError('JWT_SECRET mora imati najmanje 32 znaka.');
  }

  final secureCookie = env['COOKIE_SECURE'] == 'true';

  final database = await Connection.open(
    Endpoint(
      host: 'db',
      database: env['POSTGRES_DB']!,
      username: env['POSTGRES_USER']!,
      password: env['POSTGRES_PASSWORD']!,
    ),
    settings: const ConnectionSettings(
      sslMode: SslMode.disable,
    ),
  );

  final sesije = SesijaStore(
    database,
    jwt: JwtSesije(
      tajna: tajna,
      ttl: Duration(minutes: ttlMinuta),
    ),
  );

  final zakupStore = ZakupStore(database);
  final app = RelicApp();

  app.use(
    '/',
    corsZaBackoffice(
      env['BACKOFFICE_ORIGIN'] ?? 'http://127.0.0.1:5173',
    ),
  );

  for (final putanja in [
    putanjaPrijave,
    putanjaOdjave,
    putanjaTrenutneSesije,
    putanjaZakupa,
    putanjaAkcijeZakupa,
  ]) {
    app.add(
      Method.options,
      putanja,
      (_) => Response.noContent(),
    );
  }

  Future<({String id, String uloga})?> procitajSesiju(
    Request request,
  ) async {
    final token = bearerToken(request);
    return token == null ? null : await sesije.procitaj(token);
  }

  app.get('/health', (request) async {
    await database.execute('SELECT 1');

    return Response.ok(
      body: Body.fromString('Server i baza rade.'),
    );
  });

  app.post(
    putanjaPrijave,
    prijavaHandler(sesije, secureCookie: secureCookie),
  );

  app.post(
    putanjaOdjave,
    odjavaHandler(sesije, secureCookie: secureCookie),
  );

  app.get(
    putanjaTrenutneSesije,
    trenutnaSesijaHandler(sesije),
  );

  app.get(
    putanjaZakupa,
    preuzmiZakupeHandler(
      store: zakupStore,
      procitajSesiju: procitajSesiju,
    ),
  );

  app.post(
    putanjaZakupa,
    napraviZakupHandler(
      store: zakupStore,
      procitajSesiju: procitajSesiju,
    ),
  );

  app.post(
    putanjaAkcijeZakupa,
    akcijaZakupaHandler(
      store: zakupStore,
      procitajSesiju: procitajSesiju,
    ),
  );

  app.get(
    putanjaPredmeta,
    katalogHandler(database),
  );

  app.get(
    putanjaZauzetihPerioda,
    zauzetiPeriodiHandler(database),
  );

  await app.serve(
    address: InternetAddress.anyIPv4,
    port: 8080,
  );
}