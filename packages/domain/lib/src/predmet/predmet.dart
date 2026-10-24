import 'package:meta/meta.dart';

import '../identifikatori.dart';

/// Kategorije predmeta. Nazive na srpskom bira aplikacija
enum Kategorija { torba, sat, nakit, odeca, naocare }

/// Luksuzni predmet koji vlasnik nudi za zakup
@immutable
final class Predmet {
  const Predmet({
    required this.id,
    required this.naziv,
    required this.brend,
    required this.kategorija,
    required this.cenaPoDanu,
    required this.depozit,
    required this.opis,
    required this.vlasnik,
  });

  final PredmetId id;
  final String naziv;
  final String brend;
  final Kategorija kategorija;
  final int cenaPoDanu;
  final int depozit;
  final String opis;
  final String vlasnik;

  @override
  bool operator ==(Object other) => other is Predmet && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Predmet($id)';
}