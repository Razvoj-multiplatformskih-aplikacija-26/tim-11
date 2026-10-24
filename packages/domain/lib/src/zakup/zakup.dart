import 'package:meta/meta.dart';

import '../identifikatori.dart';
import '../predmet/predmet.dart';
import 'period_zakupa.dart';
import 'status_zakupa.dart';

@immutable
final class Zakup {
  Zakup({
    required this.id,
    required this.predmet,
    required this.period,
    this.status = const Zahtev(),
    List<StatusZakupa>? istorija,
  }) : istorija = List.unmodifiable(istorija ?? podrazumevanaIstorija(status));

  final ZakupId id;
  final Predmet predmet;
  final PeriodZakupa period;
  final StatusZakupa status;
  final List<StatusZakupa> istorija;

  DateTime get datumOd => period.od;
  DateTime get datumDo => period.doDatuma;
  int get brojDana => period.brojDana;
  int get ukupnaCena => brojDana * predmet.cenaPoDanu;

  /// Ista vrednost sa novim statusom dodatim u istoriju.
  /// Pravila iz pravila.dart je zovu tek posle provere prelaza
  Zakup saStatusom(StatusZakupa novi) =>
      Zakup(id: id, predmet: predmet, period: period, status: novi, istorija: [...istorija, novi]);

  /// Istorija za zakup koji je napravljen odmah u nekom statusu (npr. lazni podaci)
  static List<StatusZakupa> podrazumevanaIstorija(StatusZakupa status) => switch (status) {
    Odbijen() || Otkazan() => <StatusZakupa>[const Zahtev(), status],
    Sporan() => <StatusZakupa>[...StatusZakupa.glavniTok.take(5), status],
    Zahtev() || Odobren() || Placen() || Preuzet() || Vracen() || Zavrsen() => StatusZakupa.glavniTok.sublist(
      0,
      StatusZakupa.glavniTok.indexOf(status) + 1,
    ),
  };

  @override
  bool operator ==(Object other) =>
      other is Zakup &&
      other.id == id &&
      other.predmet == predmet &&
      other.period == period &&
      other.status == status &&
      _isteListe(other.istorija, istorija);

  @override
  int get hashCode => Object.hash(id, predmet, period, status, Object.hashAll(istorija));

  @override
  String toString() => 'Zakup($id, ${status.runtimeType})';
}

bool _isteListe(List<StatusZakupa> a, List<StatusZakupa> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}