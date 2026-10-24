import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/lazni_podaci.dart';
import '../data/zakupi_store.dart';
import '../text/poruke_gresaka.dart';
import '../widgets/slika_predmeta.dart';

final _datum = DateFormat('d. M. yyyy.');

/// Forma za slanje zahteva za zakup
class ZahtevFormaScreen extends StatefulWidget {
  const ZahtevFormaScreen({super.key, required this.predmetId});

  final PredmetId predmetId;

  @override
  State<ZahtevFormaScreen> createState() => _ZahtevFormaScreenState();
}

class _ZahtevFormaScreenState extends State<ZahtevFormaScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTimeRange? _period;

  /// Pravilo iz domena: ne u prošlosti, 1 do 14 dana, predmet slobodan
  Rezultat<PeriodZakupa> _proveri(Predmet predmet, DateTimeRange izabrano) =>
      proveriZahtev(
        predmet: predmet,
        od: izabrano.start,
        doDatuma: izabrano.end,
        danas: DateTime.now(),
        postojeciZakupi: zakupiStore.zakupi,
      );

  Future<void> _izaberiPeriod(FormFieldState<DateTimeRange> polje) async {
    final danas = DateTime.now();
    final izabrano = await showDateRangePicker(
      context: context,
      firstDate: DateTime(danas.year, danas.month, danas.day),
      lastDate: DateTime(danas.year + 1, danas.month, danas.day),
      initialDateRange: _period,
      helpText: 'Izaberi period zakupa',
      saveText: 'Potvrdi',
    );
    if (izabrano == null) return; // odustajanje

    setState(() => _period = izabrano);
    polje.didChange(izabrano);
    polje.validate(); // provera pravila
  }

  void _posalji(Predmet predmet) {
    // Pokreće sve validatore u formi; ako neki vrati grešku, staje
    if (!_formKey.currentState!.validate()) return;

    // Validator je već proverio pravilo, pa je ovde rezultat uspeh
    final period = _proveri(predmet, _period!).vrednostIliNull;
    if (period == null) return;
    zakupiStore.dodaj(
      Zakup(
        id: ZakupId('z-${DateTime.now().millisecondsSinceEpoch}'),
        predmet: predmet,
        period: period,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zahtev je poslat vlasniku.')),
    );
    context.go('/zakupi');
  }

  @override
  Widget build(BuildContext context) {
    final predmet = nadjiPredmet(widget.predmetId);
    if (predmet == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Predmet ne postoji.')),
      );
    }

    final tekst = Theme.of(context).textTheme;
    final period = _period;
    final brojDana =
        period == null ? 0 : period.end.difference(period.start).inDays + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Zahtev za zakup')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Koji predmet se iznajmljuje
            Row(
              children: [
                SlikaPredmeta(predmet: predmet, sirina: 64, visina: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(predmet.brend, style: tekst.labelMedium),
                      Text(predmet.naziv, style: tekst.titleMedium),
                      Text('${predmet.cenaPoDanu} € / dan'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text('Period zakupa', style: tekst.titleSmall),
            const SizedBox(height: 8),

            // Polje forme za period: dugme otvara kalendar i proveravaju se pravila
            FormField<DateTimeRange>(
              validator: (izabrano) {
                if (izabrano == null) return 'Izaberi datume zakupa.';
                // Domen vraća tip greške, ekran bira tekst poruke.
                return switch (_proveri(predmet, izabrano)) {
                  Uspeh() => null,
                  Neuspeh(:final greska) => greska.poruka,
                };
              },
              builder: (polje) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _izaberiPeriod(polje),
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      period == null
                          ? 'Izaberi datume'
                          : '${_datum.format(period.start)} – '
                              '${_datum.format(period.end)}',
                    ),
                  ),
                  if (polje.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        polje.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Pregled cene, kad je period izabran
            if (period != null) ...[
              const SizedBox(height: 16),
              _Red('Broj dana', '$brojDana'),
              _Red('Ukupno', '${brojDana * predmet.cenaPoDanu} €'),
              _Red('Depozit (vraća se)', '${predmet.depozit} €'),
            ],

            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _posalji(predmet),
              child: const Text('Pošalji zahtev'),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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