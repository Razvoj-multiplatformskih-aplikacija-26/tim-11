import 'package:api_client/api_client.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/mobilna_sesija.dart';
import '../text/poruke_gresaka.dart';
import '../widgets/prijava_zakupca.dart';
import '../widgets/slika_predmeta.dart';
import '../widgets/ucitavanje_kataloga.dart';

final _datum = DateFormat('d. M. yyyy.');

class ZahtevFormaScreen extends StatefulWidget {
  const ZahtevFormaScreen({super.key, required this.predmetId});

  final PredmetId predmetId;

  @override
  State<ZahtevFormaScreen> createState() => _ZahtevFormaScreenState();
}

class _ZahtevFormaScreenState extends State<ZahtevFormaScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTimeRange? _period;
  bool _slanjeUToku = false;
  late Future<List<PeriodZakupa>> _dostupnost;
  List<PeriodZakupa> _zauzetiPeriodi = const [];

  @override
  void initState() {
    super.initState();
    _dostupnost = _ucitajDostupnost();
  }

  Future<List<PeriodZakupa>> _ucitajDostupnost() async {
    final odgovor = await context.read<RentApi>().preuzmiZauzetePeriode(
      widget.predmetId.value,
    );

    final periodi = [
      for (final period in odgovor.periodi)
        PeriodZakupa.izBaze(
          od: DateTime.parse(period.datumOd),
          doDatuma: DateTime.parse(period.datumDo),
        ),
    ];

    if (mounted) _zauzetiPeriodi = periodi;
    return periodi;
  }

  void _osveziDostupnost() {
    setState(() => _dostupnost = _ucitajDostupnost());
  }

  Rezultat<PeriodZakupa> _proveri(Predmet predmet, DateTimeRange izabrano) {
    final rezultat = proveriZahtev(
      predmet: predmet,
      od: izabrano.start,
      doDatuma: izabrano.end,
      danas: DateTime.now(),
      postojeciZakupi: const [],
    );

    final period = rezultat.vrednostIliNull;
    if (period != null && _zauzetiPeriodi.any(period.preklapaSe)) {
      return const Neuspeh<PeriodZakupa>(TerminZauzet());
    }

    return rezultat;
  }

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

    if (!mounted || !polje.mounted || izabrano == null) return;

    setState(() => _period = izabrano);
    polje.didChange(izabrano);
    polje.validate();
  }

  Future<void> _posalji(Predmet predmet) async {
    if (_slanjeUToku || _formKey.currentState?.validate() != true) return;

    final izabrano = _period;
    if (izabrano == null) return;

    final period = _proveri(predmet, izabrano).vrednostIliNull;
    if (period == null) return;

    final api = context.read<RentApi>();
    final sesija = context.read<MobilnaSesija>();
    setState(() => _slanjeUToku = true);

    try {
      final prijavljen = await zatraziPrijavuZakupca(context);
      if (!mounted || !prijavljen) return;

      final token = sesija.token;
      if (token == null) return;

      final zahtev = noviZakupZaApi((
        predmetId: predmet.id,
        datumOd: period.od,
        datumDo: period.doDatuma,
      ));

      try {
        await api.napraviZakup(zahtev, token: token);
      } on ApiIzuzetak catch (greska) {
        if (greska.httpStatus == 401) {
          try {
            await sesija.zaboraviToken(token);
          } on Exception {
            // Sesija je već uklonjena iz memorije.
          }
        }

        if (!mounted) return;

        if (greska.greska.kod == 'termin_zauzet') {
          _osveziDostupnost();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(greskaIzApi(greska.greska).poruka)),
        );
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Zahtev je poslat.')));
      context.go('/');
    } finally {
      if (mounted) setState(() => _slanjeUToku = false);
    }
  }

  @override
  Widget build(BuildContext context) => UcitavanjeKataloga(
    builder: (context, predmeti) {
      for (final predmet in predmeti) {
        if (predmet.id == widget.predmetId) {
          return _prikaziFormu(context, predmet);
        }
      }

      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Predmet ne postoji.')),
      );
    },
  );

  Widget _prikaziFormu(BuildContext context, Predmet predmet) {
    final tekst = Theme.of(context).textTheme;
    final period = _period;
    final brojDana = period == null
        ? 0
        : samoDatum(period.end).difference(samoDatum(period.start)).inDays + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Zahtev za zakup')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            _prikaziDostupnost(),
            const SizedBox(height: 8),
            FormField<DateTimeRange>(
              initialValue: period,
              validator: (izabrano) {
                if (izabrano == null) return 'Izaberi datume zakupa.';

                return switch (_proveri(predmet, izabrano)) {
                  Uspeh() => null,
                  Neuspeh(:final greska) => greska.poruka,
                };
              },
              builder: (polje) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _slanjeUToku
                        ? null
                        : () => _izaberiPeriod(polje),
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
            if (period != null) ...[
              const SizedBox(height: 16),
              _Red('Broj dana', '$brojDana'),
              _Red('Ukupno', '${brojDana * predmet.cenaPoDanu} €'),
              _Red('Depozit (vraća se)', '${predmet.depozit} €'),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _slanjeUToku ? null : () => _posalji(predmet),
              child: Text(
                _slanjeUToku ? 'Slanje je u toku…' : 'Pošalji zahtev',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prikaziDostupnost() {
    return FutureBuilder<List<PeriodZakupa>>(
      future: _dostupnost,
      builder: (context, stanje) {
        if (stanje.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }

        final periodi = stanje.data;
        if (periodi == null) {
          return TextButton(
            onPressed: _osveziDostupnost,
            child: const Text('Dostupnost nije učitana. Pokušaj ponovo.'),
          );
        }

        if (periodi.isEmpty) {
          return const Text('Nema zauzetih termina.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Zauzeti termini:'),
            for (final period in periodi)
              Text(
                '${_datum.format(period.od)} – '
                '${_datum.format(period.doDatuma)}',
              ),
          ],
        );
      },
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
