import 'predmet.dart';
import 'zakup.dart';

const minDanaZakupa = 1;
const maxDanaZakupa = 14;


enum GreskaPerioda { uProslosti, nedozvoljenoTrajanje, zauzet }

/// Pravila za period zakupa
/// Vraća null ako je period ispravan, inače razlog greške
GreskaPerioda? proveriPeriod({
  required Predmet predmet,
  required DateTime od,
  required DateTime doDatuma,
  required DateTime danas,
  required List<Zakup> postojeciZakupi,
}) {
  final pocetakDanas = DateTime(danas.year, danas.month, danas.day);
  if (od.isBefore(pocetakDanas)) return GreskaPerioda.uProslosti;

  final brojDana = doDatuma.difference(od).inDays + 1;
  if (brojDana < minDanaZakupa || brojDana > maxDanaZakupa) {
    return GreskaPerioda.nedozvoljenoTrajanje;
  }

  // Preklapanje sa zakupima istog predmeta koji zauzimaju termin.
  for (final z in postojeciZakupi) {
    if (z.predmet.id != predmet.id) continue;
    if (!z.status.zauzimaTermin) continue;
    final preklapa = !od.isAfter(z.datumDo) && !z.datumOd.isAfter(doDatuma);
    if (preklapa) return GreskaPerioda.zauzet;
  }

  return null;
}