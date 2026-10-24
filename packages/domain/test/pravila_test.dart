import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  Rezultat<PeriodZakupa> proveri(int od, int doDana, [List<Zakup> postojeci = const []]) => proveriZahtev(
    predmet: testPredmet,
    od: dan(od),
    doDatuma: dan(doDana),
    danas: danas,
    postojeciZakupi: postojeci,
  );

  group('Pravilo 2 · nov zahtev (proveriZahtev)', () {
    test('prihvata slobodan termin', () {
      expect(proveri(2, 4).jeUspeh, isTrue);
    });

    test('dozvoljava pocetak danas', () {
      expect(proveri(0, 1).jeUspeh, isTrue);
    });

    test('odbija pocetak u proslosti', () {
      expect(proveri(-1, 2), const Neuspeh<PeriodZakupa>(PocetakUProslosti()));
    });

    test('odbija termin koji se preklapa sa odobrenim zakupom istog predmeta', () {
      final postojeci = [testZakup(od: 5, doDana: 7, status: const Odobren())];
      expect(proveri(7, 9, postojeci), const Neuspeh<PeriodZakupa>(TerminZauzet()));
    });

    test('zahtev koji jos nije odobren ne zauzima termin', () {
      final postojeci = [testZakup(od: 5, doDana: 7)];
      expect(proveri(5, 7, postojeci).jeUspeh, isTrue);
    });

    test('zakup drugog predmeta ne smeta', () {
      final postojeci = [testZakup(od: 5, doDana: 7, status: const Placen(), predmet: drugiPredmet)];
      expect(proveri(5, 7, postojeci).jeUspeh, isTrue);
    });
  });

  group('Izracunavanje · zauzeti periodi nad listom zakupa', () {
    test('vraca samo periode zakupa koji drze termin', () {
      final zakupi = [
        testZakup(od: 1, doDana: 2, status: const Odobren()),
        testZakup(od: 4, doDana: 5),
        testZakup(od: 7, doDana: 8, status: const Preuzet()),
        testZakup(od: 9, doDana: 10, status: const Placen(), predmet: drugiPredmet),
      ];
      expect(zauzetiPeriodi(testPredmet.id, zakupi), [period(1, 2), period(7, 8)]);
    });
  });

  group('Pravilo 3 · otkazivanje (otkaziZakup)', () {
    test('besplatno kad do pocetka ima bar 2 dana', () {
      final status = otkaziZakup(testZakup(od: 2, doDana: 3, status: const Placen()), sada: danas).vrednostIliNull?.status;
      expect(status, Otkazan(otkazanoU: danas, besplatno: true));
    });

    test('uz naknadu kad zakup pocinje sutra', () {
      final status = otkaziZakup(testZakup(od: 1, doDana: 3, status: const Placen()), sada: danas).vrednostIliNull?.status;
      expect(status, Otkazan(otkazanoU: danas, besplatno: false));
    });

    test('odbija otkazivanje zakupa koji je vec poceo', () {
      expect(
        otkaziZakup(testZakup(od: 0, doDana: 2, status: const Placen()), sada: danas),
        const Neuspeh<Zakup>(ZakupVecPoceo()),
      );
    });

    test('odbija otkazivanje preuzetog zakupa', () {
      final rezultat = otkaziZakup(testZakup(status: const Preuzet()), sada: danas);
      expect(rezultat.greskaIliNull, isA<NedozvoljenPrelaz>());
    });

    test('otkazivanje ulazi u istoriju', () {
      final zakup = otkaziZakup(testZakup(), sada: danas).vrednostIliNull!;
      expect(zakup.istorija.last, isA<Otkazan>());
      expect(zakup.istorija.length, 2);
    });
  });

  group('Placanje (platiZakup)', () {
    test('odobren zakup postaje placen', () {
      expect(platiZakup(testZakup(status: const Odobren())).vrednostIliNull?.status, const Placen());
    });

    test('zahtev koji nije odobren ne moze da se plati', () {
      expect(
        platiZakup(testZakup()),
        const Neuspeh<Zakup>(NedozvoljenPrelaz(od: Zahtev(), ka: Placen())),
      );
    });
  });
}