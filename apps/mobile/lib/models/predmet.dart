/// vrste predmeta u katalogu
enum Kategorija {
  torba('Torbe'),
  sat('Satovi'),
  nakit('Nakit'),
  odeca('Odeca'),
  naocare('Naocare');

  const Kategorija(this.naziv);
  final String naziv;
}

/// predmet koji vlasnik izdaje
class Predmet {
  const Predmet({
    required this.id,
    required this.naziv,
    required this.brend,
    required this.kategorija,
    required this.cenaPoDanu,
    required this.depozit,
    required this.opis,
    required this.vlasnik,
  });

  final String id;
  final String naziv;
  final String brend;
  final Kategorija kategorija;

  /// cena za zakup u evrima, po danu
  final int cenaPoDanu;
  final int depozit;
  final String opis;
  final String vlasnik;
}