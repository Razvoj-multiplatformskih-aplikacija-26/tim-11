import 'package:domain/domain.dart';
import 'package:mobile/data/lazni_podaci.dart';

class PrivremeniZakupRepository implements ZakupRepository {
  final List<Zakup> _zakupi = List.from(lazniZakupi);

  bool _trebaDaBaciGresku = false;

  @override
  Future<Rezultat<List<Zakup>>> preuzmiSveZakupe() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_trebaDaBaciGresku) {
      _trebaDaBaciGresku = false;
      return const Neuspeh(ZakupVecPoceo());
    }

    return Uspeh(_zakupi);
  }

  @override
  Future<Rezultat<Zakup>> promeniStatusZakupa({
    required ZakupId id,
    required StatusZakupa noviZakup,
  }) async {
    final index = _zakupi.indexWhere((z) => z.id == id);
    if (index != -1) {
      final azuriran = _zakupi[index].saStatusom(noviZakup);
      _zakupi[index] = azuriran;
      return Uspeh(azuriran);
    }
    return const Neuspeh(ZakupVecPoceo());
  }

  @override
  Future<Rezultat<Zakup>> otkaziZakup(ZakupId id) async {
    return promeniStatusZakupa(
      id: id,
      noviZakup: Otkazan(otkazanoU: DateTime.now(), besplatno: true),
    );
  }

  @override
  void simulirajGresku() {
    _trebaDaBaciGresku = true;
  }
}
