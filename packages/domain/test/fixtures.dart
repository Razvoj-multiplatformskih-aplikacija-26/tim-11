import 'package:domain/domain.dart';

/// Predmet za testove.
const testPredmet = Predmet(
  id: PredmetId('p-test'),
  naziv: 'Test torba',
  brend: 'Test',
  kategorija: Kategorija.torba,
  cenaPoDanu: 50,
  depozit: 500,
  opis: 'Predmet za testove.',
  vlasnik: 'Test',
);

/// Drugi predmet, za proveru da zakupi drugih predmeta ne smetaju
const drugiPredmet = Predmet(
  id: PredmetId('p-drugi'),
  naziv: 'Test sat',
  brend: 'Test',
  kategorija: Kategorija.sat,
  cenaPoDanu: 80,
  depozit: 1000,
  opis: 'Drugi predmet za testove.',
  vlasnik: 'Test',
);

/// "Danas" u testovima: fiksan trenutak, da testovi ne zavise od pravog datuma
final danas = DateTime(2026, 10, 23, 15, 30);

/// Dan udaljen [pomeraj] dana od [danas].
DateTime dan(int pomeraj) => DateTime(2026, 10, 23 + pomeraj);

PeriodZakupa period(int od, int doDana) => PeriodZakupa.parse(od: dan(od), doDatuma: dan(doDana)).vrednostIliNull!;

Zakup testZakup({
  int od = 5,
  int doDana = 7,
  StatusZakupa status = const Zahtev(),
  Predmet predmet = testPredmet,
}) => Zakup(id: const ZakupId('z-test'), predmet: predmet, period: period(od, doDana), status: status);