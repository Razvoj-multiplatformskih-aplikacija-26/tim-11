const putanjaAkcijeZakupa = '/zakupi/:id/akcije';

String akcijaZakupaPutanja(String id) =>
    '/zakupi/${Uri.encodeComponent(id)}/akcije';

final class AkcijaZakupaZahtev {
  const AkcijaZakupaZahtev({
    required this.akcija,
    this.razlog,
    this.depozitVracen,
  });

  final String akcija;
  final String? razlog;
  final bool? depozitVracen;

  factory AkcijaZakupaZahtev.fromJson(
    Map<String, Object?> json,
  ) => AkcijaZakupaZahtev(
    akcija: json['akcija'] as String,
    razlog: json['razlog'] as String?,
    depozitVracen: json['depozitVracen'] as bool?,
  );

  Map<String, Object?> toJson() => {
    'akcija': akcija,
    if (razlog != null) 'razlog': razlog,
    if (depozitVracen != null) 'depozitVracen': depozitVracen,
  };
}