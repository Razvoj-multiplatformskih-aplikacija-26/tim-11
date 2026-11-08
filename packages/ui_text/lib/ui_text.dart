import 'package:domain/domain.dart';

/// Switch nema default granu: nova greska u domenu ovde javlja gresku kompajliranja
extension PorukaGreske on DomenskaGreska {
  String get poruka => switch (this) {
    PocetakUProslosti() => 'Zakup ne može da počne u prošlosti.',
    NedozvoljenoTrajanje() =>
      'Zakup traje od ${PeriodZakupa.minDana} do ${PeriodZakupa.maxDana} dana.',
    TerminZauzet() => 'Predmet je već zauzet u delu izabranog perioda.',
    ZakupVecPoceo() => 'Zakup je već počeo, pa ne može da se otkaže.',
    NedozvoljenPrelaz() => 'Ova promena zakupa trenutno nije moguća.',
    ServerskaGreska(:final kod, :final podaci) => switch (kod) {
      'nedozvoljeno_trajanje' => switch ((
        podaci['minDana'],
        podaci['maxDana'],
      )) {
        (final int min, final int max) => 'Zakup traje od $min do $max dana.',
        _ => 'Trajanje zakupa je van dozvoljenih granica.',
      },
      'server_nedostupan' => 'Server trenutno nije dostupan. Pokušaj ponovo.',
      'potrebna_prijava' => 'Prijava je istekla. Prijavi se ponovo.',
      'zabranjena_akcija' => 'Nemaš pravo da izvršiš ovu akciju.',
      'nedozvoljen_prelaz' => 'Ova promena zakupa trenutno nije moguća.',
      'zakup_nije_pronadjen' => 'Zakup više nije dostupan.',
      'predmet_nije_pronadjen' => 'Predmet više nije dostupan.',
      'placanje_odbijeno' => 'Plaćanje je odbijeno. Pokušaj ponovo.',
      'potreban_razlog_odbijanja' => 'Unesi razlog odbijanja.',
      'neispravna_stranica' => 'Tražena stranica nije dostupna.',
      _ => 'Došlo je do greške. Pokušaj ponovo.',
    },
  };
}

String porukaGreskeZakupa(Object greska) => greska is DomenskaGreska
    ? greska.poruka
    : 'Došlo je do greške. Pokušaj ponovo.';
