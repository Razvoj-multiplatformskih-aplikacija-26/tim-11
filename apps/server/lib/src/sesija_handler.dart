import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'sesija_store.dart';

const nazivKolacica = 'rent_a_luxury_session';

String? bearerToken(Request request) =>
    switch (request.headers.authorization) {
      BearerAuthorizationHeader(:final token) => token,
      _ => request.headers.cookie?.getCookie(nazivKolacica)?.value,
    };

SetCookieHeader _kolacic(
  String token, {
  required int sekunde,
  required bool secure,
}) => SetCookieHeader(
  name: nazivKolacica,
  value: token,
  path: Uri.parse('/'),
  maxAge: sekunde,
  httpOnly: true,
  secure: secure,
  sameSite: SameSite.lax,
);

Handler prijavaHandler(
  SesijaStore store, {
  required bool secureCookie,
}) {
  return (request) async {
    final PrijavaZahtev zahtev;

    try {
      final json = jsonDecode(await request.readAsString());

      if (json is! Map<String, Object?> ||
          json['email'] is! String ||
          json['lozinka'] is! String ||
          json['aplikacija'] is! String ||
          (json['cookie'] != null && json['cookie'] is! bool)) {
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
    final brojBajtova = utf8.encode(zahtev.lozinka).length;

    if (trazenaUloga == null ||
        email.isEmpty ||
        brojBajtova == 0 ||
        brojBajtova > 72 ||
        zahtev.lozinka.contains('\u0000')) {
      return _greska(400, 'neispravan_zahtev');
    }

    final korisnik = await store.proveriLozinku(
      email,
      zahtev.lozinka,
    );

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

    if (!zahtev.cookie) {
      return _json(200, sesija.toJson());
    }

    final javniPodaci = PrijavaOdgovor(
      uloga: sesija.uloga,
      isticeU: sesija.isticeU,
    );

    final odgovor = _json(200, javniPodaci.toJson());

    return odgovor.copyWith(
      headers: odgovor.headers.transform((headers) {
        headers.setCookie = _kolacic(
          sesija.token!,
          sekunde: DateTime.parse(sesija.isticeU)
              .difference(DateTime.now().toUtc())
              .inSeconds,
          secure: secureCookie,
        );
      }),
    );
  };
}

Handler trenutnaSesijaHandler(SesijaStore store) {
  return (request) async {
    final token = bearerToken(request);

    if (token == null) {
      return _greska(401, 'potrebna_prijava');
    }

    final sesija = await store.trenutna(token);

    if (sesija == null) {
      return _greska(401, 'potrebna_prijava');
    }

    return _json(200, sesija.toJson());
  };
}

Handler odjavaHandler(
  SesijaStore store, {
  required bool secureCookie,
}) {
  return (request) async {
    final token = bearerToken(request);

    if (token != null) {
      await store.obrisi(token);
    }

    return Response.noContent(
      headers: Headers.build((headers) {
        headers.setCookie = _kolacic(
          '',
          sekunde: 0,
          secure: secureCookie,
        );
      }),
    );
  };
}

Response _greska(int status, String kod) =>
    _json(status, ApiGreska(kod: kod).toJson());

Response _json(int status, Map<String, Object?> podaci) => Response(
  status,
  headers: Headers.build(
    (headers) => headers['Cache-Control'] = ['no-store'],
  ),
  body: Body.fromString(
    jsonEncode(podaci),
    mimeType: MimeType.json,
  ),
);