import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/zakupi_store.dart';
import '../models/status_zakupa.dart';
import '../models/zakup.dart';
import '../widgets/slika_predmeta.dart';
import '../widgets/status_oznaka.dart';
import '../widgets/timeline_zakupa.dart';

final _datum = DateFormat('d. M. yyyy.');

/// Ekran sa detaljem jednog zakupa
class ZakupDetaljScreen extends StatelessWidget {
  const ZakupDetaljScreen({super.key, required this.id});

  final String id;

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
          const SizedBox(height: 24),
          Text('Tok zakupa', style: tekst.titleMedium),
          const SizedBox(height: 12),
          TimelineZakupa(zakup: zakup),

          // Akcije: prikazuju se samo kad su dozvoljene u trenutnom stanju
          if (zakup.status == StatusZakupa.odobren)
            FilledButton.icon(
              onPressed: () => _plati(context),
              icon: const Icon(Icons.payment),
              label: const Text('Plati'),
            ),
          if (zakup.status.mozeDaSeOtkaze) ...[
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
          'kad predmet bude vraćen neoštećen. Za sada su ta sredstva rezervisana',
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
    zakupiStore.promeniStatus(zakup.id, StatusZakupa.placen);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zakup je plaćen.')),
    );
  }

  Future<void> _otkazi(BuildContext context) async {
    final besplatno = zakup.besplatnoOtkazivanje(DateTime.now());

    // Dijalog vraća true (potvrđeno) ili false/null (odustala).
    final potvrdjeno = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Otkazati zakup?'),
        content: Text(
          besplatno
              ? 'Otkazivanje je besplatno jer je do preuzimanja ostalo '
                  'više od 48 sati. Ova radnja ne može da se poništi.'
              : 'Do preuzimanja je ostalo manje od 48 sati, pa otkazivanje '
                  'nije besplatno. Ova radnja ne može da se poništi.',
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
    zakupiStore.promeniStatus(zakup.id, StatusZakupa.otkazan);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zakup je otkazan.')),
    );
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
        children: [
          Expanded(
            child: Text(
              naziv,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(vrednost, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}