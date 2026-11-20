import '../greske.dart';
import '../identifikatori.dart';
import '../predmet/predmet.dart';
import '../rezultat.dart';
import 'period_zakupa.dart';
import 'status_zakupa.dart';
import 'zakup.dart';

const danaZaBesplatnoOtkazivanje = 2;

/// Periodi u kojima predmet već drži neki aktivan zakup.
List<PeriodZakupa> zauzetiPeriodi(
  PredmetId predmetId,
  List<Zakup> zakupi,
) => [
  for (final zakup in zakupi)
    if (zakup.predmet.id == predmetId && zakup.status.zauzimaTermin)
      zakup.period,
];

bool jeSlobodan(
  PredmetId predmetId,
  PeriodZakupa period,
  List<Zakup> zakupi,
) => !zauzetiPeriodi(predmetId, zakupi).any(period.preklapaSe);

Rezultat<PeriodZakupa> proveriZahtev({
  required Predmet predmet,
  required DateTime od,
  required DateTime doDatuma,
  required DateTime danas,
  required List<Zakup> postojeciZakupi,
}) {
  if (samoDatum(od).isBefore(samoDatum(danas))) {
    return const Neuspeh(PocetakUProslosti());
  }

  final rezultat = PeriodZakupa.parse(
    od: od,
    doDatuma: doDatuma,
  );
  final period = rezultat.vrednostIliNull;

  if (period == null) {
    return rezultat;
  }

  if (!jeSlobodan(predmet.id, period, postojeciZakupi)) {
    return const Neuspeh(TerminZauzet());
  }

  return Uspeh(period);
}

bool besplatnoOtkazivanje(
  Zakup zakup, {
  required DateTime sada,
}) =>
    zakup.datumOd.difference(samoDatum(sada)).inDays >=
    danaZaBesplatnoOtkazivanje;

Rezultat<Zakup> promeniStatus(
  Zakup zakup,
  StatusZakupa novi,
) {
  if (!mozePrelaz(zakup.status, novi)) {
    return Neuspeh(
      NedozvoljenPrelaz(od: zakup.status, ka: novi),
    );
  }

  return Uspeh(zakup.saStatusom(novi));
}

Rezultat<Zakup> platiZakup(Zakup zakup) =>
    promeniStatus(zakup, const Placen());

Rezultat<Zakup> otkaziZakup(
  Zakup zakup, {
  required DateTime sada,
}) {
  final novi = Otkazan(
    otkazanoU: sada,
    besplatno: besplatnoOtkazivanje(zakup, sada: sada),
  );

  if (!mozePrelaz(zakup.status, novi)) {
    return Neuspeh(
      NedozvoljenPrelaz(od: zakup.status, ka: novi),
    );
  }

  if (!samoDatum(sada).isBefore(zakup.datumOd)) {
    return const Neuspeh(ZakupVecPoceo());
  }

  return Uspeh(zakup.saStatusom(novi));
}