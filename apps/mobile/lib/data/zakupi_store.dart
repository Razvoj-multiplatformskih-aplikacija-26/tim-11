import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'lazni_podaci.dart';

/// mesto gde aplikacija drzi zakupe u memoriji. Kad se nesto promeni (otkazivanje, nov zahtev), javlja ekranima da se ponovo iscrtaju
class ZakupiStore extends ChangeNotifier {
  final List<Zakup> _zakupi = [...lazniZakupi];
  List<Zakup> get zakupi => List.unmodifiable(_zakupi);

  Zakup? nadji(ZakupId id) {
    for (final z in _zakupi) {
      if (z.id == id) return z;
    }
    return null;
  }

  /// Zamenjuje zakup novom verzijom koju je vratilo pravilo iz domena.
  void azuriraj(Zakup novi) {
    final i = _zakupi.indexWhere((z) => z.id == novi.id);
    if (i == -1) return;
    _zakupi[i] = novi;
    notifyListeners();
  }

  void dodaj(Zakup zakup) {
    _zakupi.add(zakup);
    notifyListeners();
  }
}
final zakupiStore = ZakupiStore();