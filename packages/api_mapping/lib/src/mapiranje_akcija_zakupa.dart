import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'mapiranje_zakupa.dart';

AkcijaZakupa akcijaZakupaIzApi(AkcijaZakupaZahtev zahtev) =>
    switch (zahtev.akcija) {
      'otkazi' => AkcijaZakupa.otkazi,
      'plati' => AkcijaZakupa.plati,
      'odobri' => AkcijaZakupa.odobri,
      'odbij' => AkcijaZakupa.odbij,
      'resi_spor' => AkcijaZakupa.resiSpor,
      _ => throw FormatException('Nepoznata akcija zakupa.', zahtev.akcija),
    };

AkcijaZakupaZahtev akcijaZakupaZaApi(AkcijaZakupa akcija, {String? razlog}) =>
    AkcijaZakupaZahtev(
      akcija: switch (akcija) {
        AkcijaZakupa.otkazi => 'otkazi',
        AkcijaZakupa.plati => 'plati',
        AkcijaZakupa.odobri => 'odobri',
        AkcijaZakupa.odbij => 'odbij',
        AkcijaZakupa.resiSpor => 'resi_spor',
      },
      razlog: razlog,
    );
({int httpStatus, ApiGreska greska}) greskaAkcijeZakupaZaApi(
  DomenskaGreska greska,
) => switch (greska) {
  ZakupVecPoceo() => (
    httpStatus: 422,
    greska: const ApiGreska(kod: 'zakup_vec_poceo'),
  ),
  NedozvoljenPrelaz(:final od, :final ka) => (
    httpStatus: 409,
    greska: ApiGreska(
      kod: 'nedozvoljen_prelaz',
      podaci: {'od': statusZaApi(od).status, 'ka': statusZaApi(ka).status},
    ),
  ),
  _ => greskaNovogZakupaZaApi(greska),
};
