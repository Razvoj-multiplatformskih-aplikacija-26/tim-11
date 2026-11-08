import 'package:api_client/api_client.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';

abstract interface class KatalogRepository {
  Future<List<Predmet>> preuzmiPredmete();
}

final class HttpKatalogRepository implements KatalogRepository {
  const HttpKatalogRepository(this._api);

  final RentApi _api;

  @override
  Future<List<Predmet>> preuzmiPredmete() async {
    final odgovor = await _api.preuzmiPredmete();
    return odgovor.predmeti.map(predmetIzApi).toList();
  }
}
