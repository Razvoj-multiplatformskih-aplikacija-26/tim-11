const putanjaAkcijeZakupa = '/zakupi/:id/akcije';

String akcijaZakupaPutanja(String id) =>
    '/zakupi/${Uri.encodeComponent(id)}/akcije';

final class AkcijaZakupaZahtev {
  const AkcijaZakupaZahtev({required this.akcija, this.razlog});

  final String akcija;
  final String? razlog;

  factory AkcijaZakupaZahtev.fromJson(Map<String, Object?> json) =>
      AkcijaZakupaZahtev(
        akcija: json['akcija'] as String,
        razlog: json['razlog'] as String?,
      );

  Map<String, Object?> toJson() => {
    'akcija': akcija,
    if (razlog != null) 'razlog': razlog,
  };
}
