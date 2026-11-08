import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'sesija_store.dart';

String? bearerToken(Request request) {
  final authorization = request.headers.authorization;
  return authorization is BearerAuthorizationHeader
      ? authorization.token
      : null;
}

Handler prijavaHandler(SesijaStore store) {
  return (request) async {
    final PrijavaZahtev zahtev;
    try {
      final json = jsonDecode(await request.readAsString());
      if (json is! Map<String, Object?> ||
          json['email'] is! String ||
          json['lozinka'] is! String ||
          json['aplikacija'] is! String) {
        return _greska(400, 'neispravan_zahtev');
      }
      zahtev = PrijavaZahtev.fromJson(json);
    } on FormatException {
      return _greska(400, 'neispravan_zahtev');
    }

    final trazenaUloga = switch (zahtev.aplikacija) {
      'mobile' => 'zakupac',
      'backoffice' => 'osoblje',
      _ => null,
    };

    final email = zahtev.email.trim().toLowerCase();
    final duzinaLozinke = utf8.encode(zahtev.lozinka).length;
    if (trazenaUloga == null ||
        email.isEmpty ||
        duzinaLozinke == 0 ||
        duzinaLozinke > 72 ||
        zahtev.lozinka.contains('\u0000')) {
      return _greska(400, 'neispravan_zahtev');
    }

    final korisnik = await store.proveriLozinku(email, zahtev.lozinka);
    if (korisnik == null) {
      return _greska(401, 'neispravni_podaci_za_prijavu');
    }
    if (korisnik.uloga != trazenaUloga) {
      return _greska(403, 'pogresna_aplikacija');
    }

    final sesija = await store.napraviSesiju(
      korisnikId: korisnik.id,
      uloga: korisnik.uloga,
    );
    return _json(200, sesija.toJson());
  };
}

Handler odjavaHandler(SesijaStore store) {
  return (request) async {
    final token = bearerToken(request);
    if (token == null) {
      return _greska(401, 'potrebna_prijava');
    }

    await store.obrisi(token);
    return Response.noContent();
  };
}

Response _greska(int status, String kod) =>
    _json(status, ApiGreska(kod: kod).toJson());

Response _json(int status, Map<String, Object?> podaci) => Response(
  status,
  body: Body.fromString(jsonEncode(podaci), mimeType: MimeType.json),
);
