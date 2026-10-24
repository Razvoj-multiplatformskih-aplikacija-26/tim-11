import 'package:domain/domain.dart';

/// datum udaljen [pomeraj] dana od danas (negativno = u proslosti)
DateTime _dan(int pomeraj) {
  final danas = DateTime.now();
  return DateTime(danas.year, danas.month, danas.day + pomeraj);
}

/// Period od [od] do [doDana] dana od danas; lazni podaci uvek postuju pravilo trajanja
PeriodZakupa _period(int od, int doDana) =>
    PeriodZakupa.parse(od: _dan(od), doDatuma: _dan(doDana)).vrednostIliNull!;

const lazniPredmeti = <Predmet>[
  Predmet(
    id: PredmetId('p-1'),
    naziv: 'Lady Dior torba',
    brend: 'Dior',
    kategorija: Kategorija.torba,
    cenaPoDanu: 45,
    depozit: 800,
    opis: 'Klasična Lady Dior torba od bele jagnjeće kože, srednja veličina.',
    vlasnik: 'Ana N.',
  ),
  Predmet(
    id: PredmetId('p-2'),
    naziv: 'Submariner',
    brend: 'Rolex',
    kategorija: Kategorija.sat,
    cenaPoDanu: 90,
    depozit: 2500,
    opis: 'Rolex Submariner Date, čelik, plavi brojčanik.',
    vlasnik: 'Marko P.',
  ),
  Predmet(
    id: PredmetId('p-3'),
    naziv: 'Love narukvica',
    brend: 'Cartier',
    kategorija: Kategorija.nakit,
    cenaPoDanu: 60,
    depozit: 1500,
    opis: 'Cartier Love narukvica od žutog zlata, veličina 17.',
    vlasnik: 'Ivana K.',
  ),
  Predmet(
    id: PredmetId('p-4'),
    naziv: 'Classic Flap',
    brend: 'Chanel',
    kategorija: Kategorija.torba,
    cenaPoDanu: 55,
    depozit: 1000,
    opis: 'Chanel Classic Flap, plava prošivena koža, zlatni lanac.',
    vlasnik: 'Jelena M.',
  ),
  Predmet(
    id: PredmetId('p-5'),
    naziv: 'Speedmaster Moonwatch',
    brend: 'Omega',
    kategorija: Kategorija.sat,
    cenaPoDanu: 50,
    depozit: 1200,
    opis: 'Omega Speedmaster Professional, hronograf, crni brojčanik.',
    vlasnik: 'Nikola S.',
  ),
  Predmet(
    id: PredmetId('p-6'),
    naziv: 'HardWear ogrlica',
    brend: 'Tiffany & Co.',
    kategorija: Kategorija.nakit,
    cenaPoDanu: 35,
    depozit: 600,
    opis: 'Tiffany HardWear ogrlica od srebra, dužina 45 cm.',
    vlasnik: 'Ivana K.',
  ),
  Predmet(
    id: PredmetId('p-7'),
    naziv: 'Jackie 1961',
    brend: 'Gucci',
    kategorija: Kategorija.torba,
    cenaPoDanu: 35,
    depozit: 600,
    opis: 'Gucci Jackie 1961, mala torba od teget kože.',
    vlasnik: 'Ana T.',
  ),
  Predmet(
    id: PredmetId('p-8'),
    naziv: 'Večernja haljina',
    brend: 'Valentino',
    kategorija: Kategorija.odeca,
    cenaPoDanu: 70,
    depozit: 900,
    opis: 'Duga bež svilena haljina, veličina 38.',
    vlasnik: 'Milica R.',
  ),
  Predmet(
    id: PredmetId('p-9'),
    naziv: 'Santos naočare',
    brend: 'Cartier',
    kategorija: Kategorija.naocare,
    cenaPoDanu: 25,
    depozit: 400,
    opis: 'Cartier Santos naočare za sunce, srebrno-drveni okvir.',
    vlasnik: 'Marko P.',
  ),
  Predmet(
    id: PredmetId('p-10'),
    naziv: 'Birkin 30',
    brend: 'Hermès',
    kategorija: Kategorija.torba,
    cenaPoDanu: 150,
    depozit: 5000,
    opis: 'Hermès Birkin 30, Togo koža, crne boje.',
    vlasnik: 'Nikola S.',
  ),
];

/// zakupi prijavljenog zakupca
final lazniZakupi = <Zakup>[
  Zakup(id: const ZakupId('z-1'), predmet: lazniPredmeti[0], period: _period(10, 12)),
  Zakup(id: const ZakupId('z-2'), predmet: lazniPredmeti[3], period: _period(1, 3)),
  Zakup(id: const ZakupId('z-3'), predmet: lazniPredmeti[1], period: _period(5, 7), status: const Odobren()),
  Zakup(id: const ZakupId('z-4'), predmet: lazniPredmeti[2], period: _period(3, 6), status: const Placen()),
  Zakup(id: const ZakupId('z-5'), predmet: lazniPredmeti[4], period: _period(-2, 1), status: const Preuzet()),
  Zakup(id: const ZakupId('z-6'), predmet: lazniPredmeti[5], period: _period(-6, -1), status: const Vracen()),
  Zakup(id: const ZakupId('z-7'), predmet: lazniPredmeti[6], period: _period(-30, -27), status: const Zavrsen()),
  Zakup(id: const ZakupId('z-8'), predmet: lazniPredmeti[0], period: _period(-20, -18), status: const Zavrsen()),
  Zakup(
    id: const ZakupId('z-9'),
    predmet: lazniPredmeti[7],
    period: _period(15, 17),
    status: const Odbijen(razlog: 'Haljina je tada na hemijskom čišćenju.'),
  ),
  Zakup(
    id: const ZakupId('z-10'),
    predmet: lazniPredmeti[8],
    period: _period(-10, -8),
    status: Otkazan(otkazanoU: _dan(-13), besplatno: true),
  ),
  Zakup(
    id: const ZakupId('z-11'),
    predmet: lazniPredmeti[9],
    period: _period(-14, -10),
    status: const Sporan(opis: 'Ogrebotina na kopči, vidljiva na fotografiji sa vraćanja.'),
  ),
  Zakup(id: const ZakupId('z-12'), predmet: lazniPredmeti[1], period: _period(20, 25), status: const Placen()),
];

/// Pronalazi predmet po id-ju; null ako ne postoji.
Predmet? nadjiPredmet(PredmetId id) {
  for (final p in lazniPredmeti) {
    if (p.id == id) return p;
  }
  return null;
}