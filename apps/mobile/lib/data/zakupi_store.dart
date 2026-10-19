import 'package:flutter/foundation.dart';

import '../models/status_zakupa.dart';
import '../models/zakup.dart';
import 'lazni_podaci.dart';

/// mesto gde aplikacija drzi zakupe u memoriji. Kad se nesto promeni (otkazivanje, nov zahtev), javlja ekranima da se ponovo iscrtaju
class ZakupiStore extends ChangeNotifier {
  final List<Zakup> _zakupi = [...lazniZakupi];
  List<Zakup> get zakupi => List.unmodifiable(_zakupi);

  Zakup? nadji(String id) {
    for (final z in _zakupi) {
      if (z.id == id) return z;
    }
    return null;
  }

  void promeniStatus(String id, StatusZakupa noviStatus) {
    final i = _zakupi.indexWhere((z) => z.id == id);
    if (i == -1) return;
    _zakupi[i] = _zakupi[i].copyWith(status: noviStatus);
    notifyListeners();
  }

  void dodaj(Zakup zakup) {
    _zakupi.add(zakup);
    notifyListeners();
  }
}
final zakupiStore = ZakupiStore();