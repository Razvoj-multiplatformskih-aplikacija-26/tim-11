import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';

import 'rent_api.dart';

final class HttpNoviZakupRepository implements NoviZakupRepository {
  const HttpNoviZakupRepository({
    required this.api,
    required this.procitajToken,
  });

  final RentApi api;
  final String? Function() procitajToken;

  @override
  Future<Rezultat<List<PeriodZakupa>>> preuzmiZauzetePeriode(
    PredmetId predmetId,
  ) => _izvrsi(() async {
    final odgovor = await api.preuzmiZauzetePeriode(predmetId.value);
    return dostupnostIzApi(odgovor);
  });

  @override
  Future<Rezultat<ZakupId>> posaljiZahtev({
    required PredmetId predmetId,
    required PeriodZakupa period,
  }) {
    final token = procitajToken();

    if (token == null && !api.sesijaUKolacicu) {
      return Future.value(
        const Neuspeh<ZakupId>(ServerskaGreska('potrebna_prijava')),
      );
    }

    return _izvrsi(() async {
      final zahtev = noviZakupZaApi((
        predmetId: predmetId,
        datumOd: period.od,
        datumDo: period.doDatuma,
      ));

      final odgovor = await api.napraviZakup(zahtev, token: token);

      return ZakupId(odgovor.id);
    });
  }

  Future<Rezultat<T>> _izvrsi<T>(Future<T> Function() poziv) async {
    try {
      return Uspeh(await poziv());
    } on ApiIzuzetak catch (greska) {
      return Neuspeh(greskaIzApi(greska.greska));
    } on FormatException {
      return const Neuspeh(ServerskaGreska('neispravan_odgovor_servera'));
    } on ArgumentError {
      return const Neuspeh(ServerskaGreska('neispravan_odgovor_servera'));
    } on TypeError {
      return const Neuspeh(ServerskaGreska('neispravan_odgovor_servera'));
    }
  }
}
