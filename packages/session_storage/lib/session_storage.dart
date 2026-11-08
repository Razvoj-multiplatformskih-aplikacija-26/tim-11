import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SkladisteSesije {
  Future<PrijavaOdgovor?> ucitaj();
  Future<void> sacuvaj(PrijavaOdgovor sesija);
  Future<void> obrisi();
}

final class BezbednoSkladisteSesije implements SkladisteSesije {
  const BezbednoSkladisteSesije({required this.kljuc});

  final String kljuc;
  static const _storage = FlutterSecureStorage();

  @override
  Future<PrijavaOdgovor?> ucitaj() async {
    final sacuvano = await _storage.read(key: kljuc);
    if (sacuvano == null) return null;

    try {
      final json = jsonDecode(sacuvano);
      if (json is Map<String, Object?>) {
        final sesija = PrijavaOdgovor.fromJson(json);
        final isticeU = DateTime.tryParse(sesija.isticeU);
        if (isticeU != null && isticeU.isAfter(DateTime.now())) {
          return sesija;
        }
      }
    } on FormatException {
      // Nečitljiv zapis se briše ispod.
    } on TypeError {
      // Zapis sa pogrešnim tipovima se briše ispod.
    }

    await obrisi();
    return null;
  }

  @override
  Future<void> sacuvaj(PrijavaOdgovor sesija) =>
      _storage.write(key: kljuc, value: jsonEncode(sesija.toJson()));

  @override
  Future<void> obrisi() => _storage.delete(key: kljuc);
}
