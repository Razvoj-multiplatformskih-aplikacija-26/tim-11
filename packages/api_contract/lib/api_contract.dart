export 'src/zakup_dto.dart';
export 'src/sesija_dto.dart';
export 'src/akcija_zakupa_dto.dart';
export 'src/dostupnost_dto.dart';

const putanjaZakupa = '/zakupi';

final class NoviZakupZahtev {
  const NoviZakupZahtev({
    required this.predmetId,
    required this.datumOd,
    required this.datumDo,
  });

  final String predmetId;
  final String datumOd;
  final String datumDo;

  factory NoviZakupZahtev.fromJson(Map<String, Object?> json) {
    return NoviZakupZahtev(
      predmetId: json['predmetId'] as String,
      datumOd: json['datumOd'] as String,
      datumDo: json['datumDo'] as String,
    );
  }

  Map<String, Object?> toJson() => {
    'predmetId': predmetId,
    'datumOd': datumOd,
    'datumDo': datumDo,
  };
}

final class NoviZakupOdgovor {
  const NoviZakupOdgovor({required this.id});

  final String id;

  factory NoviZakupOdgovor.fromJson(Map<String, Object?> json) {
    return NoviZakupOdgovor(id: json['id'] as String);
  }

  Map<String, Object?> toJson() => {'id': id};
}

final class ApiGreska {
  const ApiGreska({required this.kod, this.podaci = const {}});

  final String kod;
  final Map<String, Object?> podaci;

  factory ApiGreska.fromJson(Map<String, Object?> json) {
    return ApiGreska(
      kod: json['kod'] as String,
      podaci: json['podaci'] as Map<String, Object?>,
    );
  }

  Map<String, Object?> toJson() => {'kod': kod, 'podaci': podaci};
}
