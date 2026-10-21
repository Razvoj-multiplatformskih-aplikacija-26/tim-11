import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/pravila.dart';
import 'package:mobile/models/predmet.dart';
import 'package:mobile/models/status_zakupa.dart';
import 'package:mobile/models/zakup.dart';

void main() {
  final danas = DateTime(2026, 10, 19);

  const sat = Predmet(
    id: 'p-test',
    naziv: 'Test sat',
    brend: 'Test',
    kategorija: Kategorija.sat,
    cenaPoDanu: 50,
    depozit: 1000,
    opis: 'Predmet za testove.',
    vlasnik: 'Test vlasnik',
  );

  Zakup zakup(StatusZakupa status) => Zakup(
        id: 'z-test',
        predmet: sat,
        datumOd: DateTime(2026, 10, 24),
        datumDo: DateTime(2026, 10, 26),
        status: status,
      );

  test('zakup od 14 dana je dozvoljen', () {
    final greska = proveriPeriod(
      predmet: sat,
      od: DateTime(2026, 11, 1),
      doDatuma: DateTime(2026, 11, 14),
      danas: danas,
      postojeciZakupi: const [],
    );
    expect(greska, isNull);
  });

  test('zakup od 15 dana nije dozvoljen', () {
    final greska = proveriPeriod(
      predmet: sat,
      od: DateTime(2026, 11, 1),
      doDatuma: DateTime(2026, 11, 15),
      danas: danas,
      postojeciZakupi: const [],
    );
    expect(greska, GreskaPerioda.nedozvoljenoTrajanje);
  });

  test('termin koji se preklapa sa odobrenim zakupom je zauzet', () {
    final greska = proveriPeriod(
      predmet: sat,
      od: DateTime(2026, 10, 25),
      doDatuma: DateTime(2026, 10, 27),
      danas: danas,
      postojeciZakupi: [zakup(StatusZakupa.odobren)],
    );
    expect(greska, GreskaPerioda.zauzet);
  });

  test('zahtev koji još nije odobren ne zauzima termin', () {
    final greska = proveriPeriod(
      predmet: sat,
      od: DateTime(2026, 10, 25),
      doDatuma: DateTime(2026, 10, 27),
      danas: danas,
      postojeciZakupi: [zakup(StatusZakupa.zahtev)],
    );
    expect(greska, isNull);
  });
}