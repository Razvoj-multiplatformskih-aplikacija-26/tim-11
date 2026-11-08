import 'dart:async';
import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:http/http.dart' as http;

final class ApiIzuzetak implements Exception {
  const ApiIzuzetak(this.greska, {this.httpStatus});

  final ApiGreska greska;
  final int? httpStatus;
}

final class RentApi {
  RentApi({
    required this.adresaServera,
    this.rok = const Duration(seconds: 8),
    http.Client? klijent,
  }) : _klijent = klijent ?? http.Client();

  final Uri adresaServera;
  final Duration rok;
  final http.Client _klijent;

  Future<PrijavaOdgovor> prijaviSe(PrijavaZahtev zahtev) async {
    final json = await _posalji('POST', putanjaPrijave, telo: zahtev.toJson());
    return _procitajOdgovor(json, PrijavaOdgovor.fromJson);
  }

  Future<void> odjaviSe({required String token}) async {
    await _posalji('POST', putanjaOdjave, token: token);
  }

  Future<ListaPredmetaOdgovor> preuzmiPredmete() async {
    final json = await _posalji('GET', putanjaPredmeta);
    return _procitajOdgovor(json, ListaPredmetaOdgovor.fromJson);
  }

  Future<ListaZakupaOdgovor> preuzmiZakupe({
    required String token,
    int? limit,
    int pomeraj = 0,
  }) async {
    final putanja = limit == null
        ? putanjaZakupa
        : Uri(
            path: putanjaZakupa,
            queryParameters: {'limit': '$limit', 'pomeraj': '$pomeraj'},
          ).toString();

    final json = await _posalji('GET', putanja, token: token);
    return _procitajOdgovor(json, ListaZakupaOdgovor.fromJson);
  }

  Future<NoviZakupOdgovor> napraviZakup(
    NoviZakupZahtev zahtev, {
    required String token,
  }) async {
    final json = await _posalji(
      'POST',
      putanjaZakupa,
      token: token,
      telo: zahtev.toJson(),
    );
    return _procitajOdgovor(json, NoviZakupOdgovor.fromJson);
  }

  Future<ZakupDto> izvrsiAkciju(
    String zakupId,
    AkcijaZakupaZahtev zahtev, {
    required String token,
  }) async {
    final json = await _posalji(
      'POST',
      akcijaZakupaPutanja(zakupId),
      token: token,
      telo: zahtev.toJson(),
    );
    return _procitajOdgovor(json, ZakupDto.fromJson);
  }

  void zatvori() => _klijent.close();

  Future<Map<String, Object?>> _posalji(
    String metod,
    String putanja, {
    String? token,
    Map<String, Object?>? telo,
  }) async {
    final zahtev = http.Request(metod, adresaServera.resolve(putanja))
      ..headers['Accept'] = 'application/json';

    if (token != null) {
      zahtev.headers['Authorization'] = 'Bearer $token';
    }
    if (telo != null) {
      zahtev.headers['Content-Type'] = 'application/json; charset=utf-8';
      zahtev.body = jsonEncode(telo);
    }

    final http.Response odgovor;
    try {
      odgovor = await _izvrsi(zahtev).timeout(rok);
    } on TimeoutException {
      throw const ApiIzuzetak(ApiGreska(kod: 'server_nedostupan'));
    } on http.ClientException {
      throw const ApiIzuzetak(ApiGreska(kod: 'server_nedostupan'));
    }

    final status = odgovor.statusCode;
    if (status < 200 || status >= 300) {
      throw ApiIzuzetak(_procitajGresku(odgovor), httpStatus: status);
    }

    if (status == 204) return const {};

    try {
      return _dekodirajObjekat(odgovor);
    } on FormatException {
      throw ApiIzuzetak(
        const ApiGreska(kod: 'neispravan_odgovor_servera'),
        httpStatus: status,
      );
    }
  }

  Future<http.Response> _izvrsi(http.Request zahtev) async {
    final tok = await _klijent.send(zahtev);
    return http.Response.fromStream(tok);
  }

  Future<ZauzetiPeriodiOdgovor> preuzmiZauzetePeriode(String predmetId) async {
    final json = await _posalji('GET', zauzetiPeriodiPutanja(predmetId));
    return _procitajOdgovor(json, ZauzetiPeriodiOdgovor.fromJson);
  }
}

Map<String, Object?> _dekodirajObjekat(http.Response odgovor) {
  final json = jsonDecode(utf8.decode(odgovor.bodyBytes));
  if (json is! Map<String, Object?>) {
    throw const FormatException('Očekivan je JSON objekat.');
  }
  return json;
}

ApiGreska _procitajGresku(http.Response odgovor) {
  try {
    return ApiGreska.fromJson(_dekodirajObjekat(odgovor));
  } on FormatException {
    return const ApiGreska(kod: 'neispravan_odgovor_servera');
  } on TypeError {
    return const ApiGreska(kod: 'neispravan_odgovor_servera');
  }
}

T _procitajOdgovor<T>(
  Map<String, Object?> json,
  T Function(Map<String, Object?>) fromJson,
) {
  try {
    return fromJson(json);
  } on FormatException {
    throw const ApiIzuzetak(ApiGreska(kod: 'neispravan_odgovor_servera'));
  } on TypeError {
    throw const ApiIzuzetak(ApiGreska(kod: 'neispravan_odgovor_servera'));
  }
}
