import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:relic/relic.dart';

import 'zakup_store.dart';

import 'package:domain/domain.dart';

typedef ProcitajSesiju = Future<({String id, String uloga})?> Function(
  Request request,
);

Handler napraviZakupHandler({
  required ZakupStore store,
  required ProcitajSesiju procitajSesiju,
}) {
  return (request) async {
    final korisnik = await procitajSesiju(request);
    if (korisnik == null) {
      return _greska(401, 'potrebna_prijava');
    }
    if (korisnik.uloga != 'zakupac') {
      return _greska(403, 'zabranjena_akcija');
    }

    final UnosZakupa unos;
    try {
      final json = jsonDecode(await request.readAsString());
      if (json is! Map<String, Object?> ||
          json['predmetId'] is! String ||
          json['datumOd'] is! String ||
          json['datumDo'] is! String) {
        return _greska(400, 'neispravan_zahtev');
      }

      final zahtev = NoviZakupZahtev.fromJson(json);
      if (zahtev.predmetId.trim().isEmpty) {
        return _greska(400, 'neispravan_zahtev');
      }
      unos = noviZakupIzApi(zahtev);
    } on FormatException {
      return _greska(400, 'neispravan_zahtev');
    }

    final rezultat = await store.napraviZakup(
      unos: unos,
      zakupacId: korisnik.id,
      danas: DateTime.now(),
    );

    if (rezultat == null) {
      return _greska(404, 'predmet_nije_pronadjen');
    }

    final id = rezultat.vrednostIliNull;
    if (id != null) {
      return _json(201, NoviZakupOdgovor(id: id.toString()).toJson());
    }

    final odgovor = greskaNovogZakupaZaApi(rezultat.greskaIliNull!);
    return _json(odgovor.httpStatus, odgovor.greska.toJson());
  };
}

Handler preuzmiZakupeHandler({
  required ZakupStore store,
  required ProcitajSesiju procitajSesiju,
}) {
  return (request) async {
    final korisnik = await procitajSesiju(request);
    if (korisnik == null) {
      return _greska(401, 'potrebna_prijava');
    }

    if (korisnik.uloga != 'zakupac' && korisnik.uloga != 'osoblje') {
      return _greska(403, 'zabranjena_akcija');
    }

    final parametri = request.url.queryParameters;
    final limitTekst = parametri['limit'];
    final pomerajTekst = parametri['pomeraj'];

    final limit = limitTekst == null ? null : int.tryParse(limitTekst);
    final pomeraj = int.tryParse(pomerajTekst ?? '0');

    if ((limitTekst != null && (limit == null || limit < 1 || limit > 100)) ||
        (pomerajTekst != null && limit == null) ||
        pomeraj == null ||
        pomeraj < 0 ||
        pomeraj > 1000000) {
      return _greska(400, 'neispravna_stranica');
    }

    final zakupi = await store.preuzmiZakupe(
      zakupacId: korisnik.uloga == 'zakupac' ? korisnik.id : null,
      limit: limit == null ? null : limit + 1,
      pomeraj: pomeraj,
    );

    final stranica = limit == null ? zakupi : zakupi.take(limit);
    final odgovor = ListaZakupaOdgovor(
      zakupi: [for (final zakup in stranica) zakupZaApi(zakup)],
      sledeciPomeraj: limit != null && zakupi.length > limit
          ? pomeraj + limit
          : null,
    );

    return _json(200, odgovor.toJson());
  };
}

Handler akcijaZakupaHandler({
  required ZakupStore store,
  required ProcitajSesiju procitajSesiju,
}) {
  return (request) async {
    final korisnik = await procitajSesiju(request);
    if (korisnik == null) {
      return _greska(401, 'potrebna_prijava');
    }

    final uloga = switch (korisnik.uloga) {
      'zakupac' => Uloga.zakupac,
      'osoblje' => Uloga.osoblje,
      _ => null,
    };
    if (uloga == null) {
      return _greska(403, 'zabranjena_akcija');
    }

    final AkcijaZakupa akcija;
    final String? razlog;
    try {
      final json = jsonDecode(await request.readAsString());
      if (json is! Map<String, Object?> ||
          json['akcija'] is! String ||
          (json['razlog'] != null && json['razlog'] is! String)) {
        return _greska(400, 'neispravan_zahtev');
      }

      final zahtev = AkcijaZakupaZahtev.fromJson(json);
      akcija = akcijaZakupaIzApi(zahtev);
      razlog = zahtev.razlog?.trim();
      if (akcija == AkcijaZakupa.odbij && (razlog == null || razlog.isEmpty)) {
        return _greska(400, 'potreban_razlog_odbijanja');
      }
    } on FormatException {
      return _greska(400, 'neispravan_zahtev');
    }

    final Rezultat<Zakup> rezultat;
    try {
      rezultat = await store.izvrsiAkciju(
        zakupId: request.pathParameters.raw[#id]!,
        korisnikId: korisnik.id,
        uloga: uloga,
        akcija: akcija,
        sada: DateTime.now(),
        razlog: razlog,
      );
    } on ProblemAkcijeZakupa catch (problem) {
      return switch (problem) {
        ProblemAkcijeZakupa.nijePronadjen => _greska(
          404,
          'zakup_nije_pronadjen',
        ),
        ProblemAkcijeZakupa.zabranjeno => _greska(403, 'zabranjena_akcija'),
        ProblemAkcijeZakupa.placanjeOdbijeno => _greska(
          422,
          'placanje_odbijeno',
        ),
      };
    }

    final zakup = rezultat.vrednostIliNull;
    if (zakup != null) {
      return _json(200, zakupZaApi(zakup).toJson());
    }

    final odgovor = greskaAkcijeZakupaZaApi(rezultat.greskaIliNull!);
    return _json(odgovor.httpStatus, odgovor.greska.toJson());
  };
}

Response _greska(int status, String kod) {
  return _json(status, ApiGreska(kod: kod).toJson());
}

Response _json(int status, Map<String, Object?> podaci) {
  return Response(
    status,
    body: Body.fromString(jsonEncode(podaci), mimeType: MimeType.json),
  );
}
