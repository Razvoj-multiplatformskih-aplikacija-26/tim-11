import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final sviStatusi = <StatusZakupa>[
    const Zahtev(),
    const Odobren(),
    const Placen(),
    const Preuzet(),
    const Vracen(),
    const Zavrsen(),
    const Odbijen(razlog: 'test'),
    Otkazan(otkazanoU: danas, besplatno: true),
    const Sporan(opis: 'test'),
  ];

  group('Prelazi statusa', () {
    test('dozvoljava tacno 11 prelaza od 81 mogucih', () {
      final dozvoljeni = <(Type, Type)>[
        for (final od in sviStatusi)
          for (final ka in sviStatusi)
            if (mozePrelaz(od, ka)) (od.runtimeType, ka.runtimeType),
      ];
      expect(dozvoljeni, [
        (Zahtev, Odobren),
        (Zahtev, Odbijen),
        (Zahtev, Otkazan),
        (Odobren, Placen),
        (Odobren, Otkazan),
        (Placen, Preuzet),
        (Placen, Otkazan),
        (Preuzet, Vracen),
        (Vracen, Zavrsen),
        (Vracen, Sporan),
        (Sporan, Zavrsen),
      ]);
    });

    test('termin drze samo odobren, placen i preuzet zakup', () {
      final drze = [for (final s in sviStatusi) if (s.zauzimaTermin) s.runtimeType];
      expect(drze, [Odobren, Placen, Preuzet]);
    });

    test('sledeci koraci placenog zakupa su preuzimanje, vracanje i zavrsetak', () {
      expect(const Placen().sledeciKoraci, const [Preuzet(), Vracen(), Zavrsen()]);
    });

    test('sporan zakup jos moze samo da se zavrsi', () {
      expect(const Sporan(opis: 'ogrebotina').sledeciKoraci, const [Zavrsen()]);
    });
  });

  group('Istorija zakupa', () {
    test('placen zakup je prosao zahtev i odobrenje', () {
      expect(testZakup(status: const Placen()).istorija, const [Zahtev(), Odobren(), Placen()]);
    });

    test('odbijen zakup ima samo zahtev i odbijanje', () {
      const odbijen = Odbijen(razlog: 'predmet je na servisu');
      expect(testZakup(status: odbijen).istorija, const [Zahtev(), odbijen]);
    });
  });
}