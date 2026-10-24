import 'package:meta/meta.dart';

import '../greske.dart';
import '../rezultat.dart';

/// Kalendarski dan bez sata. U UTC-u, da prelazak na letnje i zimsko
/// vreme ne bi pomerio broj dana.
DateTime samoDatum(DateTime vreme) => DateTime.utc(vreme.year, vreme.month, vreme.day);

/// Period zakupa, od prvog do poslednjeg dana, oba ukljucena.
/// Nastaje samo kroz [parse]: privatni konstruktor znaci da period
/// koji krsi pravilo trajanja ne moze ni da postoji
@immutable
final class PeriodZakupa {
  const PeriodZakupa._(this.od, this.doDatuma);

  static const minDana = 1;
  static const maxDana = 14;

  final DateTime od;
  final DateTime doDatuma;

  int get brojDana => doDatuma.difference(od).inDays + 1;

  /// Da li dva perioda imaju bar jedan zajednicki dan
  bool preklapaSe(PeriodZakupa drugi) => !od.isAfter(drugi.doDatuma) && !drugi.od.isAfter(doDatuma);

  /// Pravilo: zakup traje od [minDana] do [maxDana] dana
  static Rezultat<PeriodZakupa> parse({required DateTime od, required DateTime doDatuma}) {
    final pocetak = samoDatum(od);
    final kraj = samoDatum(doDatuma);
    final brojDana = kraj.difference(pocetak).inDays + 1;
    if (brojDana < minDana || brojDana > maxDana) {
      return Neuspeh(NedozvoljenoTrajanje(brojDana));
    }
    return Uspeh(PeriodZakupa._(pocetak, kraj));
  }

  @override
  bool operator ==(Object other) => other is PeriodZakupa && other.od == od && other.doDatuma == doDatuma;

  @override
  int get hashCode => Object.hash(od, doDatuma);

  @override
  String toString() => 'PeriodZakupa($od - $doDatuma)';
}