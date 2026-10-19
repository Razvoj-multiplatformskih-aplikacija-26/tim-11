import 'predmet.dart';
import 'status_zakupa.dart';

/// Glavni pojam sistema: jedan zakup jednog predmeta
class Zakup {
  Zakup({
    required this.id,
    required this.predmet,
    required this.datumOd,
    required this.datumDo,
    required this.status,
    List<StatusZakupa>? istorija,
  }) : istorija = istorija ?? podrazumevanaIstorija(status);

  final String id;
  final Predmet predmet;
  final DateTime datumOd;
  final DateTime datumDo;
  final StatusZakupa status;

  /// Svi statusi kroz koje je zakup prošao, redom; poslednji je trenutni
  final List<StatusZakupa> istorija;

  /// Broj dana zakupa, računajući i prvi i poslednji dan
  int get brojDana => datumDo.difference(datumOd).inDays + 1;

  /// Ukupna cena zakupa (bez depozita)
  int get ukupnaCena => brojDana * predmet.cenaPoDanu;

  bool besplatnoOtkazivanje(DateTime sada) =>
      datumOd.difference(sada) >= const Duration(hours: 48);

  List<StatusZakupa> get sledeciKoraci {
    // Spor rešava osoblje, posle čega je zakup završen
    if (status == StatusZakupa.sporan) return const [StatusZakupa.zavrsen];
    final i = StatusZakupa.glavniTok.indexOf(status);
    // Odbijen i otkazan su kraj: posle njih nema ništa
    if (i == -1) return const [];
    return StatusZakupa.glavniTok.sublist(i + 1);
  }

  /// Nova kopija sa novim statusom; novi status se dodaje u istoriju
  Zakup copyWith({StatusZakupa? status}) => Zakup(
        id: id,
        predmet: predmet,
        datumOd: datumOd,
        datumDo: datumDo,
        status: status ?? this.status,
        istorija: status == null ? istorija : [...istorija, status],
      );

  /// Istorija za lažne podatke: najverovatniji put do datog statusa.
  static List<StatusZakupa> podrazumevanaIstorija(StatusZakupa status) {
    const tok = StatusZakupa.glavniTok;
    return switch (status) {
      StatusZakupa.odbijen => const [StatusZakupa.zahtev, StatusZakupa.odbijen],
      StatusZakupa.otkazan => const [StatusZakupa.zahtev, StatusZakupa.otkazan],
      StatusZakupa.sporan => [...tok.sublist(0, 5), StatusZakupa.sporan],
      _ => tok.sublist(0, tok.indexOf(status) + 1),
    };
  }
}