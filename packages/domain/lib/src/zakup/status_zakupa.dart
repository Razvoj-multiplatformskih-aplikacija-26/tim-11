import 'package:meta/meta.dart';

@immutable
sealed class StatusZakupa {
  const StatusZakupa();

  static const glavniTok = <StatusZakupa>[
    Zahtev(),
    Odobren(),
    Placen(),
    Preuzet(),
    Vracen(),
    Zavrsen(),
  ];

  bool get zauzimaTermin => switch (this) {
    Zahtev() || Odobren() || Placen() || Preuzet() => true,
    Vracen() || Zavrsen() || Odbijen() || Otkazan() || Sporan() => false,
  };

  bool get jeKonacan => switch (this) {
    Zavrsen() || Odbijen() || Otkazan() => true,
    Zahtev() ||
    Odobren() ||
    Placen() ||
    Preuzet() ||
    Vracen() ||
    Sporan() => false,
  };

  List<StatusZakupa> get sledeciKoraci => switch (this) {
    Sporan() => const <StatusZakupa>[Zavrsen()],
    Zavrsen() || Odbijen() || Otkazan() => const <StatusZakupa>[],
    Zahtev() ||
    Odobren() ||
    Placen() ||
    Preuzet() ||
    Vracen() => glavniTok.sublist(glavniTok.indexOf(this) + 1),
  };

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class Zahtev extends StatusZakupa {
  const Zahtev();
}

final class Odobren extends StatusZakupa {
  const Odobren();
}

final class Placen extends StatusZakupa {
  const Placen();
}

final class Preuzet extends StatusZakupa {
  const Preuzet();
}

final class Vracen extends StatusZakupa {
  const Vracen();
}

/// null označava stariji zapis bez sačuvane odluke.
/// true znači da se depozit vraća, false da se naplaćuje.
final class Zavrsen extends StatusZakupa {
  const Zavrsen({this.depozitVracen});

  final bool? depozitVracen;

  @override
  bool operator ==(Object other) =>
      other is Zavrsen && other.depozitVracen == depozitVracen;

  @override
  int get hashCode => Object.hash(Zavrsen, depozitVracen);
}

final class Odbijen extends StatusZakupa {
  const Odbijen({required this.razlog});

  final String razlog;

  @override
  bool operator ==(Object other) =>
      other is Odbijen && other.razlog == razlog;

  @override
  int get hashCode => Object.hash(Odbijen, razlog);
}

final class Otkazan extends StatusZakupa {
  const Otkazan({
    required this.otkazanoU,
    required this.besplatno,
  });

  final DateTime otkazanoU;
  final bool besplatno;

  @override
  bool operator ==(Object other) =>
      other is Otkazan &&
      other.otkazanoU == otkazanoU &&
      other.besplatno == besplatno;

  @override
  int get hashCode => Object.hash(Otkazan, otkazanoU, besplatno);
}

final class Sporan extends StatusZakupa {
  const Sporan({required this.opis});

  final String opis;

  @override
  bool operator ==(Object other) =>
      other is Sporan && other.opis == opis;

  @override
  int get hashCode => Object.hash(Sporan, opis);
}

bool mozePrelaz(StatusZakupa od, StatusZakupa ka) => switch ((od, ka)) {
  (Zahtev(), Odobren() || Odbijen()) => true,
  (Zahtev() || Odobren() || Placen(), Otkazan()) => true,
  (Odobren(), Placen()) => true,
  (Placen(), Preuzet()) => true,
  (Preuzet(), Vracen()) => true,
  (Vracen(), Zavrsen() || Sporan()) => true,
  (Sporan(), Zavrsen()) => true,
  _ => false,
};