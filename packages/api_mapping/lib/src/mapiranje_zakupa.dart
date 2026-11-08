import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

typedef UnosZakupa = ({
  PredmetId predmetId,
  DateTime datumOd,
  DateTime datumDo,
});

UnosZakupa noviZakupIzApi(NoviZakupZahtev zahtev) => (
  predmetId: PredmetId(zahtev.predmetId),
  datumOd: _procitajDatum(zahtev.datumOd),
  datumDo: _procitajDatum(zahtev.datumDo),
);

NoviZakupZahtev noviZakupZaApi(UnosZakupa unos) => NoviZakupZahtev(
  predmetId: unos.predmetId.toString(),
  datumOd: _upisiDatum(unos.datumOd),
  datumDo: _upisiDatum(unos.datumDo),
);

DateTime _procitajDatum(String tekst) {
  if (!RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$').hasMatch(tekst)) {
    throw FormatException('Očekivan je datum u formatu YYYY-MM-DD.', tekst);
  }

  final datum = DateTime.tryParse(tekst);
  if (datum == null || _upisiDatum(datum) != tekst) {
    throw FormatException('Datum ne postoji.', tekst);
  }

  return samoDatum(datum);
}

String _upisiDatum(DateTime datum) {
  final godina = datum.year.toString().padLeft(4, '0');
  final mesec = datum.month.toString().padLeft(2, '0');
  final dan = datum.day.toString().padLeft(2, '0');
  return '$godina-$mesec-$dan';
}

({int httpStatus, ApiGreska greska}) greskaNovogZakupaZaApi(
  DomenskaGreska greska,
) => switch (greska) {
  TerminZauzet() => (
    httpStatus: 409,
    greska: const ApiGreska(kod: 'termin_zauzet'),
  ),
  PocetakUProslosti() => (
    httpStatus: 422,
    greska: const ApiGreska(kod: 'pocetak_u_proslosti'),
  ),
  NedozvoljenoTrajanje() => (
    httpStatus: 422,
    greska: const ApiGreska(
      kod: 'nedozvoljeno_trajanje',
      podaci: {
        'minDana': PeriodZakupa.minDana,
        'maxDana': PeriodZakupa.maxDana,
      },
    ),
  ),
  _ => throw ArgumentError.value(greska, 'greska'),
};
PredmetDto predmetZaApi(Predmet predmet) => PredmetDto(
  id: predmet.id.value,
  naziv: predmet.naziv,
  brend: predmet.brend,
  kategorija: predmet.kategorija.name,
  cenaPoDanu: predmet.cenaPoDanu,
  depozit: predmet.depozit,
  opis: predmet.opis,
  vlasnik: predmet.vlasnik,
);

Predmet predmetIzApi(PredmetDto dto) => Predmet(
  id: PredmetId(dto.id),
  naziv: dto.naziv,
  brend: dto.brend,
  kategorija: Kategorija.values.byName(dto.kategorija),
  cenaPoDanu: dto.cenaPoDanu,
  depozit: dto.depozit,
  opis: dto.opis,
  vlasnik: dto.vlasnik,
);

StatusZakupaDto statusZaApi(StatusZakupa status) => switch (status) {
  Zahtev() => const StatusZakupaDto(status: 'zahtev'),
  Odobren() => const StatusZakupaDto(status: 'odobren'),
  Placen() => const StatusZakupaDto(status: 'placen'),
  Preuzet() => const StatusZakupaDto(status: 'preuzet'),
  Vracen() => const StatusZakupaDto(status: 'vracen'),
  Zavrsen() => const StatusZakupaDto(status: 'zavrsen'),
  Odbijen(:final razlog) => StatusZakupaDto(
    status: 'odbijen',
    podaci: {'razlog': razlog},
  ),
  Otkazan(:final otkazanoU, :final besplatno) => StatusZakupaDto(
    status: 'otkazan',
    podaci: {
      'otkazanoU': otkazanoU.toUtc().toIso8601String(),
      'besplatno': besplatno,
    },
  ),
  Sporan(:final opis) => StatusZakupaDto(
    status: 'sporan',
    podaci: {'opis': opis},
  ),
};

StatusZakupa statusIzApi(StatusZakupaDto dto) => switch (dto.status) {
  'zahtev' => const Zahtev(),
  'odobren' => const Odobren(),
  'placen' => const Placen(),
  'preuzet' => const Preuzet(),
  'vracen' => const Vracen(),
  'zavrsen' => const Zavrsen(),
  'odbijen' => Odbijen(razlog: dto.podaci['razlog'] as String),
  'otkazan' => Otkazan(
    otkazanoU: DateTime.parse(dto.podaci['otkazanoU'] as String),
    besplatno: dto.podaci['besplatno'] as bool,
  ),
  'sporan' => Sporan(opis: dto.podaci['opis'] as String),
  _ => throw FormatException('Nepoznat status zakupa.', dto.status),
};

ZakupDto zakupZaApi(Zakup zakup) => ZakupDto(
  id: zakup.id.value,
  predmet: predmetZaApi(zakup.predmet),
  datumOd: _upisiDatum(zakup.datumOd),
  datumDo: _upisiDatum(zakup.datumDo),
  status: statusZaApi(zakup.status),
  oznakaZakupca: zakup.oznakaZakupca,
  istorija: [for (final korak in zakup.istorija) statusZaApi(korak)],
);

Zakup zakupIzApi(ZakupDto dto) => Zakup(
  id: ZakupId(dto.id),
  predmet: predmetIzApi(dto.predmet),
  period: PeriodZakupa.izBaze(
    od: _procitajDatum(dto.datumOd),
    doDatuma: _procitajDatum(dto.datumDo),
  ),
  status: statusIzApi(dto.status),
  oznakaZakupca: dto.oznakaZakupca,
  istorija: [for (final korak in dto.istorija) statusIzApi(korak)],
);

DomenskaGreska greskaIzApi(ApiGreska greska) => switch (greska.kod) {
  'termin_zauzet' => const TerminZauzet(),
  'pocetak_u_proslosti' => const PocetakUProslosti(),
  'zakup_vec_poceo' => const ZakupVecPoceo(),
  _ => ServerskaGreska(greska.kod, podaci: greska.podaci),
};
