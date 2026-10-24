import 'package:meta/meta.dart';

import 'zakup/status_zakupa.dart';

/// Sve greske koje domen moze da vrati. Domen vraca tip greske,
/// a tekst poruke na srpskom bira aplikacija
@immutable
sealed class DomenskaGreska {
  const DomenskaGreska();
}

final class PocetakUProslosti extends DomenskaGreska {
  const PocetakUProslosti();
}

final class NedozvoljenoTrajanje extends DomenskaGreska {
  const NedozvoljenoTrajanje(this.brojDana);

  final int brojDana;

  @override
  bool operator ==(Object other) => other is NedozvoljenoTrajanje && other.brojDana == brojDana;

  @override
  int get hashCode => Object.hash(NedozvoljenoTrajanje, brojDana);

  @override
  String toString() => 'NedozvoljenoTrajanje($brojDana)';
}

final class TerminZauzet extends DomenskaGreska {
  const TerminZauzet();
}

final class ZakupVecPoceo extends DomenskaGreska {
  const ZakupVecPoceo();
}

final class NedozvoljenPrelaz extends DomenskaGreska {
  const NedozvoljenPrelaz({required this.od, required this.ka});

  final StatusZakupa od;
  final StatusZakupa ka;

  @override
  bool operator ==(Object other) => other is NedozvoljenPrelaz && other.od == od && other.ka == ka;

  @override
  int get hashCode => Object.hash(NedozvoljenPrelaz, od, ka);

  @override
  String toString() => 'NedozvoljenPrelaz(${od.runtimeType} -> ${ka.runtimeType})';
}