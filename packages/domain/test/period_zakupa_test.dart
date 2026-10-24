import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('Pravilo 1 · trajanje zakupa (PeriodZakupa.parse)', () {
    test('prihvata zakup od jednog dana', () {
      final rezultat = PeriodZakupa.parse(od: dan(1), doDatuma: dan(1));
      expect(rezultat.vrednostIliNull?.brojDana, 1);
    });

    test('prihvata najduzi zakup od 14 dana', () {
      final rezultat = PeriodZakupa.parse(od: dan(1), doDatuma: dan(14));
      expect(rezultat.vrednostIliNull?.brojDana, 14);
    });

    test('odbija zakup od 15 dana i vraca tip greske, ne tekst', () {
      expect(
        PeriodZakupa.parse(od: dan(1), doDatuma: dan(15)),
        const Neuspeh<PeriodZakupa>(NedozvoljenoTrajanje(15)),
      );
    });

    test('odbija kraj pre pocetka', () {
      final rezultat = PeriodZakupa.parse(od: dan(3), doDatuma: dan(1));
      expect(rezultat.greskaIliNull, isA<NedozvoljenoTrajanje>());
    });

    test('broji dane tacno i kad se sat pomera na zimsko vreme', () {
      // 25. 10. 2026. sat se vraca sa 3 na 2.
      final rezultat = PeriodZakupa.parse(od: DateTime(2026, 10, 24), doDatuma: DateTime(2026, 10, 27));
      expect(rezultat.vrednostIliNull?.brojDana, 4);
    });

    test('periodi koji dele jedan dan se preklapaju', () {
      expect(period(1, 3).preklapaSe(period(3, 5)), isTrue);
      expect(period(1, 3).preklapaSe(period(4, 5)), isFalse);
    });
  });
}