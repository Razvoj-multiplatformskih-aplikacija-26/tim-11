import 'package:flutter/material.dart';
import '../data/lazni_podaci.dart';
import '../widgets/slika_predmeta.dart';
import 'package:go_router/go_router.dart';

/// Detalj predmeta iz kataloga
class PredmetDetaljScreen extends StatelessWidget {
  const PredmetDetaljScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final predmet = nadjiPredmet(id);
    if (predmet == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Predmet ne postoji.')),
      );
    }

    final tekst = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(predmet.brend)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SlikaPredmeta(
            predmet: predmet,
            sirina: double.infinity,
            visina: 300,
            zaobljenje: 16,
          ),
          const SizedBox(height: 16),
          Text(predmet.brend, style: tekst.labelLarge),
          Text(predmet.naziv, style: tekst.headlineSmall),
          const SizedBox(height: 8),
          Text(predmet.opis),
          const SizedBox(height: 16),
          _Red('Kategorija', predmet.kategorija.naziv),
          _Red('Cena po danu', '${predmet.cenaPoDanu} €'),
          _Red('Depozit', '${predmet.depozit} €'),
          _Red('Vlasnik', predmet.vlasnik),
          const SizedBox(height: 24),
           FilledButton.icon(
            onPressed: () => context.push('/predmet/${predmet.id}/zahtev'),
            icon: const Icon(Icons.event_available),
            label: const Text('Iznajmi'),
          ),
        ],
      ),
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