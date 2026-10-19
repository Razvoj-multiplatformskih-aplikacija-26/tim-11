import '../models/predmet.dart';
import '../models/status_zakupa.dart';
import '../models/zakup.dart';

/// datum udaljen [pomeraj] dana od danas (negativno = u proslosti)
DateTime _dan(int pomeraj) {
  final danas = DateTime.now();
  return DateTime(danas.year, danas.month, danas.day + pomeraj);
}

const lazniPredmeti = <Predmet>[
  Predmet(
    id: 'p-1',
    naziv: 'Lady Dior torba',
    brend: 'Dior',
    kategorija: Kategorija.torba,
    cenaPoDanu: 45,
    depozit: 800,
    opis: 'Klasična Lady Dior torba od bele jagnjeće kože, srednja veličina.',
    vlasnik: 'Ana N.',
  ),
  Predmet(
    id: 'p-2',
    naziv: 'Submariner',
    brend: 'Rolex',
    kategorija: Kategorija.sat,
    cenaPoDanu: 90,
    depozit: 2500,
    opis: 'Rolex Submariner Date, čelik, plavi brojčanik.',
    vlasnik: 'Marko P.',
  ),
  Predmet(
    id: 'p-3',
    naziv: 'Love narukvica',
    brend: 'Cartier',
    kategorija: Kategorija.nakit,
    cenaPoDanu: 60,
    depozit: 1500,
    opis: 'Cartier Love narukvica od žutog zlata, veličina 17.',
    vlasnik: 'Ivana K.',
  ),
  Predmet(
    id: 'p-4',
    naziv: 'Classic Flap',
    brend: 'Chanel',
    kategorija: Kategorija.torba,
    cenaPoDanu: 55,
    depozit: 1000,
    opis: 'Chanel Classic Flap, plava prošivena koža, zlatni lanac.',
    vlasnik: 'Jelena M.',
  ),
  Predmet(
    id: 'p-5',
    naziv: 'Speedmaster Moonwatch',
    brend: 'Omega',
    kategorija: Kategorija.sat,
    cenaPoDanu: 50,
    depozit: 1200,
    opis: 'Omega Speedmaster Professional, hronograf, crni brojčanik.',
    vlasnik: 'Nikola S.',
  ),
  Predmet(
    id: 'p-6',
    naziv: 'HardWear ogrlica',
    brend: 'Tiffany & Co.',
    kategorija: Kategorija.nakit,
    cenaPoDanu: 35,
    depozit: 600,
    opis: 'Tiffany HardWear ogrlica od srebra, dužina 45 cm.',
    vlasnik: 'Ivana K.',
  ),
  Predmet(
    id: 'p-7',
    naziv: 'Jackie 1961',
    brend: 'Gucci',
    kategorija: Kategorija.torba,
    cenaPoDanu: 35,
    depozit: 600,
    opis: 'Gucci Jackie 1961, mala torba od teget kože.',
    vlasnik: 'Ana T.',
  ),
  Predmet(
    id: 'p-8',
    naziv: 'Večernja haljina',
    brend: 'Valentino',
    kategorija: Kategorija.odeca,
    cenaPoDanu: 70,
    depozit: 900,
    opis: 'Duga bež svilena haljina, veličina 38.',
    vlasnik: 'Milica R.',
  ),
  Predmet(
    id: 'p-9',
    naziv: 'Santos naočare',
    brend: 'Cartier',
    kategorija: Kategorija.naocare,
    cenaPoDanu: 25,
    depozit: 400,
    opis: 'Cartier Santos naočare za sunce, srebrno-drveni okvir.',
    vlasnik: 'Marko P.',
  ),
  Predmet(
    id: 'p-10',
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
  Zakup(id: 'z-1', predmet: lazniPredmeti[0], datumOd: _dan(10), datumDo: _dan(12), status: StatusZakupa.zahtev),
  Zakup(id: 'z-2', predmet: lazniPredmeti[3], datumOd: _dan(1), datumDo: _dan(3), status: StatusZakupa.zahtev),
  Zakup(id: 'z-3', predmet: lazniPredmeti[1], datumOd: _dan(5), datumDo: _dan(7), status: StatusZakupa.odobren),
  Zakup(id: 'z-4', predmet: lazniPredmeti[2], datumOd: _dan(3), datumDo: _dan(6), status: StatusZakupa.placen),
  Zakup(id: 'z-5', predmet: lazniPredmeti[4], datumOd: _dan(-2), datumDo: _dan(1), status: StatusZakupa.preuzet),
  Zakup(id: 'z-6', predmet: lazniPredmeti[5], datumOd: _dan(-6), datumDo: _dan(-1), status: StatusZakupa.vracen),
  Zakup(id: 'z-7', predmet: lazniPredmeti[6], datumOd: _dan(-30), datumDo: _dan(-27), status: StatusZakupa.zavrsen),
  Zakup(id: 'z-8', predmet: lazniPredmeti[0], datumOd: _dan(-20), datumDo: _dan(-18), status: StatusZakupa.zavrsen),
  Zakup(id: 'z-9', predmet: lazniPredmeti[7], datumOd: _dan(15), datumDo: _dan(17), status: StatusZakupa.odbijen),
  Zakup(id: 'z-10', predmet: lazniPredmeti[8], datumOd: _dan(-10), datumDo: _dan(-8), status: StatusZakupa.otkazan),
  Zakup(id: 'z-11', predmet: lazniPredmeti[9], datumOd: _dan(-14), datumDo: _dan(-10), status: StatusZakupa.sporan),
  Zakup(id: 'z-12', predmet: lazniPredmeti[1], datumOd: _dan(20), datumDo: _dan(25), status: StatusZakupa.placen),
];

/// Pronalazi predmet po id-ju; null ako ne postoji.
Predmet? nadjiPredmet(String id) {
  for (final p in lazniPredmeti) {
    if (p.id == id) return p;
  }
  return null;
}