import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/zakupi_store.dart';
import '../text/poruke_gresaka.dart';
import '../widgets/slika_predmeta.dart';
import '../widgets/status_oznaka.dart';
import '../widgets/timeline_zakupa.dart';

final _datum = DateFormat('d. M. yyyy.');

/// Ekran sa detaljem jednog zakupa
class ZakupDetaljScreen extends StatelessWidget {
  const ZakupDetaljScreen({super.key, required this.id});

  final ZakupId id;

  @override
  Widget build(BuildContext context) {
    // Sluša store, pa se ekran sam osveži kad se status promeni.
    return ListenableBuilder(
      listenable: zakupiStore,
      builder: (context, _) {
        final zakup = zakupiStore.nadji(id);
        if (zakup == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Zakup ne postoji.')),
          );
        }
        return _Sadrzaj(zakup: zakup);
      },
    );
  }
}

class _Sadrzaj extends StatelessWidget {
  const _Sadrzaj({required this.zakup});

  final Zakup zakup;

  @override
  Widget build(BuildContext context) {
    final predmet = zakup.predmet;
    final tekst = Theme.of(context).textTheme;

    // Ekran ne odlučuje sam: pita domen da li je radnja sada dozvoljena.
    final mozeDaPlati = platiZakup(zakup).jeUspeh;
    final mozeDaOtkaze = otkaziZakup(zakup, sada: DateTime.now()).jeUspeh;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalj zakupa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Zaglavlje: velika fotografija, pa brend i naziv
          SlikaPredmeta(
            predmet: predmet,
            sirina: double.infinity,
            visina: 260,
            zaobljenje: 16,
          ),
          const SizedBox(height: 16),
          Text(predmet.brend, style: tekst.labelLarge),
          Text(predmet.naziv, style: tekst.headlineSmall),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusOznaka(status: zakup.status),
          ),
          const SizedBox(height: 16),

          // Podaci o zakupu
          _Red('Preuzimanje', _datum.format(zakup.datumOd)),
          _Red('Vraćanje', _datum.format(zakup.datumDo)),
          _Red('Broj dana', '${zakup.brojDana}'),
          _Red('Cena po danu', '${predmet.cenaPoDanu} €'),
          _Red('Ukupno', '${zakup.ukupnaCena} €'),
          _Red('Depozit', '${predmet.depozit} €'),
          _Red('Vlasnik', predmet.vlasnik),

          // Podaci koje nosi sam status (sealed klasa iz domena)
          if (zakup.status case Odbijen(:final razlog)) _Red('Razlog odbijanja', razlog),
          if (zakup.status case Otkazan(:final besplatno))
            _Red('Otkazivanje', besplatno ? 'besplatno' : 'uz naknadu'),
          if (zakup.status case Sporan(:final opis)) _Red('Opis problema', opis),

          const SizedBox(height: 24),
          Text('Tok zakupa', style: tekst.titleMedium),
          const SizedBox(height: 12),
          TimelineZakupa(zakup: zakup),

          // Akcije: prikazuju se samo kad ih pravila iz domena dozvoljavaju
          if (mozeDaPlati)
            FilledButton.icon(
              onPressed: () => _plati(context),
              icon: const Icon(Icons.payment),
              label: const Text('Plati'),
            ),
          if (mozeDaOtkaze) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _otkazi(context),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Otkaži zakup'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _plati(BuildContext context) async {
    final potvrdjeno = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Platiti zakup?'),
        content: Text(
          'Biće naplaćeno ${zakup.ukupnaCena} € za zakup i '
          '${zakup.predmet.depozit} € depozita, koji se vraća '
          'kad predmet bude vraćen neoštećen. Za sada su ta sredstva rezervisana.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Plati'),
          ),
        ],
      ),
    );

    if (potvrdjeno != true || !context.mounted) return;
    _primeni(context, platiZakup(zakup), 'Zakup je plaćen.');
  }

  Future<void> _otkazi(BuildContext context) async {
    final besplatno = besplatnoOtkazivanje(zakup, sada: DateTime.now());

    // Dijalog vraća true (potvrđeno) ili false/null (odustala).
    final potvrdjeno = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Otkazati zakup?'),
        content: Text(
          besplatno
              ? 'Otkazivanje je besplatno jer do preuzimanja ima bar '
                  '$danaZaBesplatnoOtkazivanje dana. Ova radnja ne može da se poništi.'
              : 'Do preuzimanja je ostalo manje od $danaZaBesplatnoOtkazivanje dana, '
                  'pa otkazivanje nije besplatno. Ova radnja ne može da se poništi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Otkaži zakup'),
          ),
        ],
      ),
    );

    // Posle await proveravamo da li ekran još postoji
    if (potvrdjeno != true || !context.mounted) return;
    _primeni(context, otkaziZakup(zakup, sada: DateTime.now()), 'Zakup je otkazan.');
  }

  /// Uspeh: store dobija novu verziju zakupa. Neuspeh: prikaži poruku greške.
  void _primeni(BuildContext context, Rezultat<Zakup> rezultat, String porukaUspeha) {
    final String poruka;
    switch (rezultat) {
      case Uspeh(:final vrednost):
        zakupiStore.azuriraj(vrednost);
        poruka = porukaUspeha;
      case Neuspeh(:final greska):
        poruka = greska.poruka;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(poruka)));
  }
}

class _Red extends StatelessWidget {
  const _Red(this.naziv, this.vrednost);

  final String naziv;
  final String vrednost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              naziv,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Flexible: dug tekst (npr. razlog odbijanja) prelazi u novi red
          Flexible(
            child: Text(
              vrednost,
              textAlign: TextAlign.start,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}