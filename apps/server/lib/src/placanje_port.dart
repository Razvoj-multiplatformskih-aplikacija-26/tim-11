import 'package:domain/domain.dart';

abstract interface class PlacanjePort {
  Future<bool> autorizuj({required ZakupId zakupId, required int iznosEvra});
}

final class DemoPlacanje implements PlacanjePort {
  const DemoPlacanje({this.odobreno = true});

  final bool odobreno;

  @override
  Future<bool> autorizuj({
    required ZakupId zakupId,
    required int iznosEvra,
  }) async => odobreno;
}
