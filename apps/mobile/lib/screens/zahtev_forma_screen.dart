import 'package:blocs/blocs.dart';
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

class ZahtevFormaScreen extends StatelessWidget {
  const ZahtevFormaScreen({super.key, required this.predmetId});

  final PredmetId predmetId;

  @override
  Widget build(BuildContext context) => UcitavanjeKataloga(
    builder: (context, predmeti) {
      for (final predmet in predmeti) {
        if (predmet.id == predmetId) {
          return BlocProvider(
            key: ValueKey(predmet.id.value),
            create: (context) => NoviZakupBloc(
              repository: context.read<NoviZakupRepository>(),
              predmet: predmet,
            )..add(const DostupnostZatrazena()),
            child: _FormaZakupa(predmet: predmet),
          );
        }
      }

      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Predmet ne postoji.')),
      );
    },
  );
}

class _FormaZakupa extends StatefulWidget {
  const _FormaZakupa({required this.predmet});

  final Predmet predmet;

  @override
  State<_FormaZakupa> createState() => _FormaZakupaState();
}

class _FormaZakupaState extends State<_FormaZakupa> {
  bool _trazenoSlanje = false;
  bool _prijavaUToku = false;

  Future<void> _izaberiPeriod(NoviZakupStanje stanje) async {
    final danas = DateTime.now();

    final izabrano = await showDateRangePicker(
      context: context,
      firstDate: DateTime(danas.year, danas.month, danas.day),
      lastDate: DateTime(danas.year + 1, danas.month, danas.day),
      initialDateRange: stanje.od != null && stanje.doDatuma != null
          ? DateTimeRange(start: stanje.od!, end: stanje.doDatuma!)
          : null,
      helpText: 'Izaberi period zakupa',
      saveText: 'Potvrdi',
    );

    if (!mounted || izabrano == null) return;

    context.read<NoviZakupBloc>().add(
      PeriodZakupaIzabran(od: izabrano.start, doDatuma: izabrano.end),
    );
  }

  Future<void> _posalji() async {
    final bloc = context.read<NoviZakupBloc>();
    final stanje = bloc.state;

    if (_prijavaUToku || stanje.slanje || stanje.ucitavanje) return;

    setState(() => _trazenoSlanje = true);

    if (stanje.od == null || stanje.doDatuma == null) return;

    if (stanje.provera?.jeUspeh != true) {
      bloc.add(const SlanjeZakupaZatrazeno());
      return;
    }

    setState(() => _prijavaUToku = true);

    try {
      final prijavljen = await zatraziPrijavuZakupca(context);
      if (!mounted || !prijavljen) return;

      bloc.add(const SlanjeZakupaZatrazeno());
    } finally {
      if (mounted) setState(() => _prijavaUToku = false);
    }
  }

  Future<void> _prikaziPromenu(
    BuildContext context,
    NoviZakupStanje stanje,
  ) async {
    if (stanje.poslatId != null) {
      context.read<ZakupiBloc>().add(const ZatrazeniZakupi());

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Zahtev je poslat.')));

      context.go('/zakupi');
      return;
    }

    final greska = stanje.greska;
    if (greska == null) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(greska.poruka)));

    if (greska case ServerskaGreska(kod: 'potrebna_prijava')) {
      final sesija = context.read<MobilnaSesija>();
      final token = sesija.token;

      if (token != null) {
        try {
          await sesija.zaboraviToken(token);
        } on Exception {
          // Sesija je već uklonjena iz memorije.
        }
      }

      if (!mounted || !context.mounted) return;
      await zatraziPrijavuZakupca(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NoviZakupBloc, NoviZakupStanje>(
      listenWhen: (prethodno, sledece) =>
          prethodno.greska != sledece.greska ||
          prethodno.poslatId != sledece.poslatId,
      listener: _prikaziPromenu,
      builder: (context, stanje) {
        final predmet = widget.predmet;
        final tekst = Theme.of(context).textTheme;
        final zauzeto = stanje.slanje || stanje.ucitavanje || _prijavaUToku;

        final period = stanje.provera?.vrednostIliNull;
        final greskaPerioda = stanje.provera?.greskaIliNull;

        return Scaffold(
          appBar: AppBar(title: const Text('Zahtev za zakup')),
          body: ListView(
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
              if (stanje.ucitavanje)
                const LinearProgressIndicator()
              else ...[
                if (stanje.greska != null)
                  Text(
                    stanje.greska!.poruka,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (stanje.periodi.isNotEmpty) ...[
                  const Text('Zauzeti termini:'),
                  for (final period in stanje.periodi)
                    Text(
                      '${_datum.format(period.od)} – '
                      '${_datum.format(period.doDatuma)}',
                    ),
                ],
                TextButton.icon(
                  onPressed: zauzeto
                      ? null
                      : () {
                          context.read<NoviZakupBloc>().add(
                            const DostupnostZatrazena(),
                          );
                        },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Osveži dostupnost'),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: zauzeto ? null : () => _izaberiPeriod(stanje),
                icon: const Icon(Icons.date_range),
                label: Text(
                  stanje.od == null || stanje.doDatuma == null
                      ? 'Izaberi datume'
                      : '${_datum.format(stanje.od!)} – '
                            '${_datum.format(stanje.doDatuma!)}',
                ),
              ),
              if (_trazenoSlanje && stanje.od == null)
                _tekstGreske('Izaberi datume zakupa.'),
              if (greskaPerioda != null) _tekstGreske(greskaPerioda.poruka),
              if (period != null) ...[
                const SizedBox(height: 16),
                _Red('Broj dana', '${period.brojDana}'),
                _Red('Ukupno', '${period.brojDana * predmet.cenaPoDanu} €'),
                _Red('Depozit (vraća se)', '${predmet.depozit} €'),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: zauzeto ? null : _posalji,
                child: Text(
                  stanje.slanje
                      ? 'Slanje je u toku…'
                      : _prijavaUToku
                      ? 'Prijava je u toku…'
                      : 'Pošalji zahtev',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tekstGreske(String poruka) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      poruka,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
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
          Expanded(child: Text(naziv)),
          Text(vrednost, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
