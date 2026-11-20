import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../text/poruke_gresaka.dart';
import '../widgets/slika_predmeta.dart';
import '../widgets/status_oznaka.dart';
import '../widgets/timeline_zakupa.dart';

final _datum = DateFormat('d. M. yyyy.');

class ZakupDetaljScreen extends StatelessWidget {
  const ZakupDetaljScreen({super.key, required this.id});

  final ZakupId id;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ZakupiBloc, ZakupiState>(
      listenWhen: (prethodno, sledece) =>
          sledece is ZakupiUcitani &&
          sledece.obavestenje != null &&
          (prethodno is! ZakupiUcitani ||
              prethodno.obavestenje != sledece.obavestenje),
      listener: (context, stanje) {
        final obavestenje = (stanje as ZakupiUcitani).obavestenje;

        final poruka = switch (obavestenje) {
          ZakupOtkazan(:final zakup) when zakup.id == id => 'Zakup je otkazan.',
          OtkazivanjeOdbijeno(:final greska) when greska is DomenskaGreska =>
            greska.poruka,
          PromenaZakupaOdbijena(:final greska) => greska.poruka,
          _ => null,
        };

        if (poruka == null) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(poruka)));

        context.read<ZakupiBloc>().add(const ObavestenjePotvrdjeno());
      },
      builder: (context, stanje) {
        if (stanje is ZakupiUcitani) {
          for (final zakup in stanje.zakupi) {
            if (zakup.id == id) {
              return _Sadrzaj(
                zakup: zakup,
                otkazivanjeUToku: stanje.otkazivanje == id,
              );
            }
          }
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Detalj zakupa')),
          body: Center(
            child: switch (stanje) {
              ZakupiUcitavanje() => const CircularProgressIndicator(),
              ZakupiGreska(:final greska) when greska is DomenskaGreska => Text(
                greska.poruka,
              ),
              _ => const Text('Zakup nije dostupan.'),
            },
          ),
        );
      },
    );
  }
}

class _Sadrzaj extends StatelessWidget {
  const _Sadrzaj({required this.zakup, required this.otkazivanjeUToku});

  final Zakup zakup;
  final bool otkazivanjeUToku;

  bool get _mozeDaPlati =>
      imaPravoNaAkciju(
        uloga: Uloga.zakupac,
        akcija: AkcijaZakupa.plati,
        jeSvojZakup: true,
      ) &&
      platiZakup(zakup).jeUspeh;

  bool get _mozeDaOtkaze =>
      imaPravoNaAkciju(
        uloga: Uloga.zakupac,
        akcija: AkcijaZakupa.otkazi,
        jeSvojZakup: true,
      ) &&
      otkaziZakup(zakup, sada: DateTime.now()).jeUspeh;

  @override
  Widget build(BuildContext context) {
    final predmet = zakup.predmet;
    final tekst = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalj zakupa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          _Red('Preuzimanje', _datum.format(zakup.datumOd)),
          _Red('Vraćanje', _datum.format(zakup.datumDo)),
          _Red('Broj dana', '${zakup.brojDana}'),
          _Red('Cena po danu', '${predmet.cenaPoDanu} €'),
          _Red('Ukupno', '${zakup.ukupnaCena} €'),
          _Red('Depozit', '${predmet.depozit} €'),
          _Red('Vlasnik', predmet.vlasnik),
          if (zakup.status case Zavrsen(depozitVracen: final bool vracen))
            _Red('Odluka o depozitu', vracen ? 'Vraćen' : 'Naplaćen'),
          if (zakup.status case Odbijen(:final razlog))
            _Red('Razlog odbijanja', razlog),
          if (zakup.status case Otkazan(:final besplatno))
            _Red('Otkazivanje', besplatno ? 'besplatno' : 'uz naknadu'),
          if (zakup.status case Sporan(:final opis))
            _Red('Opis problema', opis),
          const SizedBox(height: 24),
          Text('Tok zakupa', style: tekst.titleMedium),
          const SizedBox(height: 12),
          TimelineZakupa(zakup: zakup),
          if (_mozeDaPlati)
            FilledButton.icon(
              onPressed: otkazivanjeUToku ? null : () => _plati(context),
              icon: const Icon(Icons.payment),
              label: const Text('Plati'),
            ),
          if (_mozeDaOtkaze) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: otkazivanjeUToku ? null : () => _otkazi(context),
              icon: const Icon(Icons.cancel_outlined),
              label: Text(otkazivanjeUToku ? 'Otkazivanje…' : 'Otkaži zakup'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _plati(BuildContext context) async {
    if (!_mozeDaPlati || otkazivanjeUToku) return;

    final potvrdjeno = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: const Text('Platiti zakup?'),
        content: Text(
          'Cena zakupa je ${zakup.ukupnaCena} €, a depozit '
          '${zakup.predmet.depozit} €. '
          'U ovom demou plaćanje je simulirano.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Plati'),
          ),
        ],
      ),
    );

    if (potvrdjeno != true || !context.mounted) return;

    context.read<ZakupiBloc>().add(
      PromenaStatusaZakupa(id: zakup.id, noviStatus: const Placen()),
    );
  }

  Future<void> _otkazi(BuildContext context) async {
    if (!_mozeDaOtkaze || otkazivanjeUToku) return;

    final besplatno = besplatnoOtkazivanje(zakup, sada: DateTime.now());

    final potvrdjeno = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: const Text('Otkazati zakup?'),
        content: Text(
          besplatno
              ? 'Otkazivanje je besplatno jer do preuzimanja ima bar '
                    '$danaZaBesplatnoOtkazivanje dana. '
                    'Ova radnja ne može da se poništi.'
              : 'Do preuzimanja je ostalo manje od '
                    '$danaZaBesplatnoOtkazivanje dana, pa otkazivanje '
                    'nije besplatno. Ova radnja ne može da se poništi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Otkaži zakup'),
          ),
        ],
      ),
    );

    if (potvrdjeno != true || !context.mounted) return;

    context.read<ZakupiBloc>().add(OtkazivanjeZakupa(zakup.id));
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
          Flexible(
            child: Text(
              vrednost,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
