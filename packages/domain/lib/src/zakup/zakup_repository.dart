import 'package:domain/domain.dart';

abstract interface class ZakupRepository {

  Future<Rezultat<List<Zakup>>> preuzmiSveZakupe();

  Future<Rezultat<Zakup>> promeniStatusZakupa(
      {required ZakupId id, required StatusZakupa noviZakup});

  Future<Rezultat<Zakup>> otkaziZakup(ZakupId id);

  void simulirajGresku();
}