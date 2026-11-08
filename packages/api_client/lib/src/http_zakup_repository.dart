import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';

import 'rent_api.dart';

final class HttpZakupRepository implements StranicniZakupRepository {
  HttpZakupRepository({
    required this.api,
    required this.procitajToken,
    this.velicinaStranice,
  });

  final int? velicinaStranice;
  int _stranica = 0;
  bool _imaSledecuStranicu = false;

  @override
  int get stranica => _stranica;

  @override
  bool get imaSledecuStranicu => _imaSledecuStranicu;

  @override
  bool izaberiStranicu(int broj) {
    if (velicinaStranice == null || broj < 0 || broj == _stranica) return false;
    if (broj > _stranica && (broj != _stranica + 1 || !_imaSledecuStranicu)) {
      return false;
    }
    _stranica = broj;
    _imaSledecuStranicu = false;
    return true;
  }

  final RentApi api;
  final String? Function() procitajToken;
  bool _simulirajSledecuGresku = false;

  @override
  Future<Rezultat<List<Zakup>>> preuzmiSveZakupe() => _izvrsi((token) async {
    final stranicaPoziva = _stranica;
    final odgovor = await api.preuzmiZakupe(
      token: token,
      limit: velicinaStranice,
      pomeraj: stranicaPoziva * (velicinaStranice ?? 0),
    );
    final zakupi = odgovor.zakupi.map(zakupIzApi).toList();
    if (stranicaPoziva == _stranica) {
      _imaSledecuStranicu = odgovor.sledeciPomeraj != null;
    }
    return zakupi;
  });

  @override
  Future<Rezultat<Zakup>> promeniStatusZakupa({
    required ZakupId id,
    required StatusZakupa noviZakup,
  }) {
    final zahtev = switch (noviZakup) {
      Odobren() => akcijaZakupaZaApi(AkcijaZakupa.odobri),
      Odbijen(:final razlog) => akcijaZakupaZaApi(
        AkcijaZakupa.odbij,
        razlog: razlog,
      ),
      Placen() => akcijaZakupaZaApi(AkcijaZakupa.plati),
      Zavrsen() => akcijaZakupaZaApi(AkcijaZakupa.resiSpor),
      _ => null,
    };

    if (zahtev == null) {
      return Future.value(
        const Neuspeh<Zakup>(ServerskaGreska('nedozvoljen_prelaz')),
      );
    }

    return _izvrsiAkciju(id, zahtev);
  }

  @override
  Future<Rezultat<Zakup>> otkaziZakup(ZakupId id) =>
      _izvrsiAkciju(id, akcijaZakupaZaApi(AkcijaZakupa.otkazi));

  @override
  void simulirajGresku() {
    _simulirajSledecuGresku = true;
  }

  Future<Rezultat<Zakup>> _izvrsiAkciju(
    ZakupId id,
    AkcijaZakupaZahtev zahtev,
  ) => _izvrsi((token) async {
    final dto = await api.izvrsiAkciju(id.value, zahtev, token: token);
    return zakupIzApi(dto);
  });

  Future<Rezultat<T>> _izvrsi<T>(Future<T> Function(String token) poziv) async {
    if (_simulirajSledecuGresku) {
      _simulirajSledecuGresku = false;
      return const Neuspeh(ServerskaGreska('server_nedostupan'));
    }

    final token = procitajToken();
    if (token == null) {
      return const Neuspeh(ServerskaGreska('potrebna_prijava'));
    }

    try {
      return Uspeh(await poziv(token));
    } on ApiIzuzetak catch (greska) {
      return Neuspeh(greskaIzApi(greska.greska));
    } on FormatException {
      return const Neuspeh(ServerskaGreska('neispravan_odgovor_servera'));
    } on ArgumentError {
      return const Neuspeh(ServerskaGreska('neispravan_odgovor_servera'));
    } on TypeError {
      return const Neuspeh(ServerskaGreska('neispravan_odgovor_servera'));
    }
  }
}
