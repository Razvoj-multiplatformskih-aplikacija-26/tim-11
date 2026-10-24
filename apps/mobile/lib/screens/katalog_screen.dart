import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/lazni_podaci.dart';
import 'package:domain/domain.dart';
import '../text/nazivi.dart';
import '../widgets/predmet_kartica.dart';

/// Katalog predmeta sa pretragom i filterom po kategoriji
class KatalogScreen extends StatefulWidget {
  const KatalogScreen({super.key});

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  /// Izabrana kategorija; null znači "Sve"
  Kategorija? _izabrana;

  /// Tekst iz polja za pretragu.
  String _pretraga = '';

  @override
  Widget build(BuildContext context) {
    final upit = _pretraga.trim().toLowerCase();
    final predmeti = lazniPredmeti.where((p) {
      final odgovaraKategoriji =
          _izabrana == null || p.kategorija == _izabrana;
      final odgovaraPretrazi = upit.isEmpty ||
          p.brend.toLowerCase().contains(upit) ||
          p.naziv.toLowerCase().contains(upit) ||
          p.kategorija.naziv.toLowerCase().contains(upit);
      return odgovaraKategoriji && odgovaraPretrazi;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Katalog')),
      body: Column(
        children: [
          // Polje za pretragu po brendu, nazivu ili kategoriji
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              onChanged: (tekst) => setState(() => _pretraga = tekst),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Pretraži brend ili predmet',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),

          // Red sa čipovima za kategorije
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Sve'),
                    selected: _izabrana == null,
                    onSelected: (_) => setState(() => _izabrana = null),
                  ),
                ),
                for (final k in Kategorija.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(k.naziv),
                      selected: _izabrana == k,
                      onSelected: (_) => setState(() => _izabrana = k),
                    ),
                  ),
              ],
            ),
          ),

          // Mreža predmeta, po dva u redu
          Expanded(
            child: predmeti.isEmpty
                ? const Center(child: Text('Nema predmeta za izabrani filter.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: predmeti.length,
                    itemBuilder: (context, i) => PredmetKartica(
                      predmet: predmeti[i],
                      onTap: () => context.push('/predmet/${predmeti[i].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}