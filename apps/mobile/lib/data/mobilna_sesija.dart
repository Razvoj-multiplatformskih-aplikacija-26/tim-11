import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:session_storage/session_storage.dart';

final class MobilnaSesija {
  MobilnaSesija(this._api);

  final RentApi _api;

  final SkladisteSesije _skladiste = const BezbednoSkladisteSesije(
    kljuc: 'rent_a_luxury_mobilna_sesija',
  );

  PrijavaOdgovor? _sesija;

  String? get token {
    final sesija = _sesija;
    if (sesija == null) return null;

    final isticeU = DateTime.tryParse(sesija.isticeU);

    if (isticeU == null || !isticeU.isAfter(DateTime.now())) {
      return null;
    }

    return sesija.token;
  }

  Future<void> obnovi() async {
    try {
      final sacuvana = await _skladiste.ucitaj();

      if (sacuvana?.uloga == 'zakupac') {
        _sesija = sacuvana;
      }
    } on Exception {
      _sesija = null;
    }
  }

  Future<void> prijaviSe({
    required String email,
    required String lozinka,
  }) async {
    final sesija = await _api.prijaviSe(
      PrijavaZahtev(email: email, lozinka: lozinka, aplikacija: 'mobile'),
    );

    if (sesija.token == null) {
      throw const ApiIzuzetak(ApiGreska(kod: 'neispravan_odgovor_servera'));
    }

    try {
      await _skladiste.sacuvaj(sesija);
    } on Exception {
      throw const ApiIzuzetak(ApiGreska(kod: 'sesija_nije_sacuvana'));
    }

    _sesija = sesija;
  }

  Future<void> odjaviSe() async {
    final sesija = _sesija;
    if (sesija == null) return;

    final token = sesija.token;
    if (token == null) return;

    await _api.odjaviSe(token: token);
    await zaboraviToken(token);
  }

  Future<void> zaboraviToken(String odbijeniToken) async {
    if (_sesija?.token != odbijeniToken) return;

    _sesija = null;
    await _skladiste.obrisi();
  }
}
