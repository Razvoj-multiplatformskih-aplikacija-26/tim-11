const putanjaZauzetihPerioda = '/predmeti/:id/zauzeti-periodi';

String zauzetiPeriodiPutanja(String predmetId) =>
    '/predmeti/${Uri.encodeComponent(predmetId)}/zauzeti-periodi';

final class ZauzetPeriodDto {
  const ZauzetPeriodDto({required this.datumOd, required this.datumDo});

  final String datumOd;
  final String datumDo;

  factory ZauzetPeriodDto.fromJson(Map<String, Object?> json) =>
      ZauzetPeriodDto(
        datumOd: json['datumOd'] as String,
        datumDo: json['datumDo'] as String,
      );

  Map<String, Object?> toJson() => {'datumOd': datumOd, 'datumDo': datumDo};
}

final class ZauzetiPeriodiOdgovor {
  const ZauzetiPeriodiOdgovor({required this.periodi});

  final List<ZauzetPeriodDto> periodi;

  factory ZauzetiPeriodiOdgovor.fromJson(Map<String, Object?> json) =>
      ZauzetiPeriodiOdgovor(
        periodi: [
          for (final period in json['periodi'] as List<Object?>)
            ZauzetPeriodDto.fromJson(period as Map<String, Object?>),
        ],
      );

  Map<String, Object?> toJson() => {
    'periodi': [for (final period in periodi) period.toJson()],
  };
}
