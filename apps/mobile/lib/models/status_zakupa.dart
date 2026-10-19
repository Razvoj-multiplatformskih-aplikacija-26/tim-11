/// stanja kroz koja zakup prolazi 
enum StatusZakupa {
  zahtev('Zahtev poslat'),
  odobren('Odobren'),
  placen('Placen'),
  preuzet('Preuzet'),
  vracen('Vracen'),
  zavrsen('Zavrsen'),
  odbijen('Odbijen'),
  otkazan('Otkazan'),
  sporan('Sporan');

  const StatusZakupa(this.naziv);

  ///ono sto korisnik vidi
  final String naziv;
    ///glavni tok zakupa
  static const glavniTok = [zahtev, odobren, placen, preuzet, vracen, zavrsen];

  /// prvo pravilo 
  bool get mozeDaSeOtkaze =>
      this == zahtev || this == odobren || this == placen;


  bool get zauzimaTermin =>
      this == odobren || this == placen || this == preuzet;
}