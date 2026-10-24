import 'package:domain/domain.dart';

/// Switch nema default granu: nova greska u domenu ovde javlja gresku kompajliranja
extension PorukaGreske on DomenskaGreska {
  String get poruka => switch (this) {
    PocetakUProslosti() => 'Zakup ne može da počne u prošlosti.',
    NedozvoljenoTrajanje() => 'Zakup traje od ${PeriodZakupa.minDana} do ${PeriodZakupa.maxDana} dana.',
    TerminZauzet() => 'Predmet je već zauzet u delu izabranog perioda.',
    ZakupVecPoceo() => 'Zakup je već počeo, pa ne može da se otkaže.',
    NedozvoljenPrelaz() => 'Ova promena zakupa trenutno nije moguća.',
  };
}