import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

List<PeriodZakupa> dostupnostIzApi(ZauzetiPeriodiOdgovor odgovor) => [
  for (final period in odgovor.periodi)
    PeriodZakupa.izBaze(
      od: _procitajDatum(period.datumOd),
      doDatuma: _procitajDatum(period.datumDo),
    ),
];

DateTime _procitajDatum(String tekst) {
  if (!RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$').hasMatch(tekst)) {
    throw const FormatException('Neispravan datum dostupnosti.');
  }

  final datum = DateTime.tryParse(tekst);

  if (datum == null ||
      datum.year != int.parse(tekst.substring(0, 4)) ||
      datum.month != int.parse(tekst.substring(5, 7)) ||
      datum.day != int.parse(tekst.substring(8, 10))) {
    throw const FormatException('Datum dostupnosti ne postoji.');
  }

  return samoDatum(datum);
}
