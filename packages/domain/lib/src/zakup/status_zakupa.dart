import 'package:meta/meta.dart';

/// Status zakupa. Sealed hijerarhija: svaki status nosi samo svoje podatke,
/// a switch bez default grane mora da pokrije sve statuse
@immutable
sealed class StatusZakupa {
  const StatusZakupa();

  /// Redovan tok zakupa, od zahteva do zavrsetka.
  static const glavniTok = <StatusZakupa>[
    Zahtev(),
    Odobren(),
    Placen(),
    Preuzet(),
    Vracen(),
    Zavrsen(),
  ];

  /// Da li zakup u ovom statusu drzi termin, pa drugi ne mogu da ga zakupe
  bool get zauzimaTermin => switch (this) {
    Odobren() || Placen() || Preuzet() => true,
    Zahtev() || Vracen() || Zavrsen() || Odbijen() || Otkazan() || Sporan() => false,
  };

  /// Da li je zakup u ovom statusu zavrsen i vise se ne menja
  bool get jeKonacan => switch (this) {
    Zavrsen() || Odbijen() || Otkazan() => true,
    Zahtev() || Odobren() || Placen() || Preuzet() || Vracen() || Sporan() => false,
  };

  List<StatusZakupa> get sledeciKoraci => switch (this) {
    Sporan() => const <StatusZakupa>[Zavrsen()],
    Zavrsen() || Odbijen() || Otkazan() => const <StatusZakupa>[],
    Zahtev() || Odobren() || Placen() || Preuzet() || Vracen() => glavniTok.sublist(glavniTok.indexOf(this) + 1),
  };

  // Statusi bez podataka su jednaki ako su iste vrste
  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Zakupac je poslao zahtev, vlasnik jos nije odgovorio
final class Zahtev extends StatusZakupa {
  const Zahtev();
}

/// Vlasnik je odobrio zahtev; ceka se placanje
final class Odobren extends StatusZakupa {
  const Odobren();
}

/// Zakupac je platio zakup i depozit
final class Placen extends StatusZakupa {
  const Placen();
}

/// Zakupac je preuzeo predmet
final class Preuzet extends StatusZakupa {
  const Preuzet();
}

/// Zakupac je vratio predmet; ceka se provera stanja
final class Vracen extends StatusZakupa {
  const Vracen();
}

/// Predmet je proveren i depozit vracen
final class Zavrsen extends StatusZakupa {
  const Zavrsen();
}

/// Vlasnik je odbio zahtev, uz razlog
final class Odbijen extends StatusZakupa {
  const Odbijen({required this.razlog});

  final String razlog;

  @override
  bool operator ==(Object other) => other is Odbijen && other.razlog == razlog;

  @override
  int get hashCode => Object.hash(Odbijen, razlog);
}

/// Zakupac je otkazao zakup; pamti se kada i da li je otkazivanje besplatno
final class Otkazan extends StatusZakupa {
  const Otkazan({required this.otkazanoU, required this.besplatno});

  final DateTime otkazanoU;
  final bool besplatno;

  @override
  bool operator ==(Object other) => other is Otkazan && other.otkazanoU == otkazanoU && other.besplatno == besplatno;

  @override
  int get hashCode => Object.hash(Otkazan, otkazanoU, besplatno);
}

/// Pri vracanju je uocena steta ili nedostatak; opis pise vlasnik
final class Sporan extends StatusZakupa {
  const Sporan({required this.opis});

  final String opis;

  @override
  bool operator ==(Object other) => other is Sporan && other.opis == opis;

  @override
  int get hashCode => Object.hash(Sporan, opis);
}

/// Tabela dozvoljenih prelaza: jedna funkcija nad parom (od, ka)
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