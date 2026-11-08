final class PredmetDto {
  const PredmetDto({
    required this.id,
    required this.naziv,
    required this.brend,
    required this.kategorija,
    required this.cenaPoDanu,
    required this.depozit,
    required this.opis,
    required this.vlasnik,
  });

  final String id;
  final String naziv;
  final String brend;
  final String kategorija;
  final int cenaPoDanu;
  final int depozit;
  final String opis;
  final String vlasnik;

  factory PredmetDto.fromJson(Map<String, Object?> json) => PredmetDto(
    id: json['id'] as String,
    naziv: json['naziv'] as String,
    brend: json['brend'] as String,
    kategorija: json['kategorija'] as String,
    cenaPoDanu: json['cenaPoDanu'] as int,
    depozit: json['depozit'] as int,
    opis: json['opis'] as String,
    vlasnik: json['vlasnik'] as String,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'naziv': naziv,
    'brend': brend,
    'kategorija': kategorija,
    'cenaPoDanu': cenaPoDanu,
    'depozit': depozit,
    'opis': opis,
    'vlasnik': vlasnik,
  };
}

final class StatusZakupaDto {
  const StatusZakupaDto({required this.status, this.podaci = const {}});

  final String status;
  final Map<String, Object?> podaci;

  factory StatusZakupaDto.fromJson(Map<String, Object?> json) =>
      StatusZakupaDto(
        status: json['status'] as String,
        podaci: json['podaci'] as Map<String, Object?>,
      );

  Map<String, Object?> toJson() => {'status': status, 'podaci': podaci};
}

final class ZakupDto {
  const ZakupDto({
    required this.id,
    required this.predmet,
    required this.datumOd,
    required this.datumDo,
    required this.status,
    required this.istorija,
    this.oznakaZakupca,
  });

  final String id;
  final PredmetDto predmet;
  final String datumOd;
  final String datumDo;
  final StatusZakupaDto status;
  final List<StatusZakupaDto> istorija;
  final String? oznakaZakupca;

  factory ZakupDto.fromJson(Map<String, Object?> json) => ZakupDto(
    id: json['id'] as String,
    predmet: PredmetDto.fromJson(json['predmet'] as Map<String, Object?>),
    datumOd: json['datumOd'] as String,
    datumDo: json['datumDo'] as String,
    status: StatusZakupaDto.fromJson(json['status'] as Map<String, Object?>),
    oznakaZakupca: json['oznakaZakupca'] as String?,
    istorija: [
      for (final korak in json['istorija'] as List<Object?>)
        StatusZakupaDto.fromJson(korak as Map<String, Object?>),
    ],
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'predmet': predmet.toJson(),
    'datumOd': datumOd,
    'datumDo': datumDo,
    'status': status.toJson(),
    if (oznakaZakupca != null) 'oznakaZakupca': oznakaZakupca,
    'istorija': [for (final korak in istorija) korak.toJson()],
  };
}

final class ListaZakupaOdgovor {
  const ListaZakupaOdgovor({required this.zakupi, this.sledeciPomeraj});

  final List<ZakupDto> zakupi;
  final int? sledeciPomeraj;

  factory ListaZakupaOdgovor.fromJson(Map<String, Object?> json) =>
      ListaZakupaOdgovor(
        zakupi: [
          for (final zakup in json['zakupi'] as List<Object?>)
            ZakupDto.fromJson(zakup as Map<String, Object?>),
        ],
        sledeciPomeraj: json['sledeciPomeraj'] as int?,
      );

  Map<String, Object?> toJson() => {
    'zakupi': [for (final zakup in zakupi) zakup.toJson()],
    if (sledeciPomeraj != null) 'sledeciPomeraj': sledeciPomeraj,
  };
}

const putanjaPredmeta = '/predmeti';

final class ListaPredmetaOdgovor {
  const ListaPredmetaOdgovor({required this.predmeti});

  final List<PredmetDto> predmeti;

  factory ListaPredmetaOdgovor.fromJson(Map<String, Object?> json) =>
      ListaPredmetaOdgovor(
        predmeti: [
          for (final predmet in json['predmeti'] as List<Object?>)
            PredmetDto.fromJson(predmet as Map<String, Object?>),
        ],
      );

  Map<String, Object?> toJson() => {
    'predmeti': [for (final predmet in predmeti) predmet.toJson()],
  };
}
