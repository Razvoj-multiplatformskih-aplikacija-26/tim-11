import 'package:domain/domain.dart';

/// Nazivi statusa na srpskom. Domen ne zna za tekst, bira ga aplikacija
extension NazivStatusa on StatusZakupa {
  String get naziv => switch (this) {
    Zahtev() => 'Zahtev poslat',
    Odobren() => 'Odobren',
    Placen() => 'Plaćen',
    Preuzet() => 'Preuzet',
    Vracen() => 'Vraćen',
    Zavrsen() => 'Završen',
    Odbijen() => 'Odbijen',
    Otkazan() => 'Otkazan',
    Sporan() => 'Sporan',
  };
}

extension NazivKategorije on Kategorija {
  String get naziv => switch (this) {
    Kategorija.torba => 'Torbe',
    Kategorija.sat => 'Satovi',
    Kategorija.nakit => 'Nakit',
    Kategorija.odeca => 'Odeća',
    Kategorija.naocare => 'Naočare',
  };
}