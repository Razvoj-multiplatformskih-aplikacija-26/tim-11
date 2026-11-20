import '../identifikatori.dart';
import '../rezultat.dart';
import '../greske.dart';
import 'period_zakupa.dart';

abstract interface class NoviZakupRepository {
  Future<Rezultat<List<PeriodZakupa>>> preuzmiZauzetePeriode(
    PredmetId predmetId,
  );

  Future<Rezultat<ZakupId>> posaljiZahtev({
    required PredmetId predmetId,
    required PeriodZakupa period,
  });
}

Rezultat<PeriodZakupa> proveriSlobodanPeriod(
  PeriodZakupa period,
  List<PeriodZakupa> zauzeti,
) {
  if (zauzeti.any(period.preklapaSe)) {
    return const Neuspeh<PeriodZakupa>(TerminZauzet());
  }

  return Uspeh(period);
}
