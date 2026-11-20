import 'package:backoffice/backoffice_shortcuts.dart';
import 'package:backoffice/odbij_zakup.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_text/ui_text.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    super.key,
    this.onOdjava,
    this.prikaziStranice = false,
  });

  final VoidCallback? onOdjava;
  final bool prikaziStranice;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  ZakupId? _izabraniId;
  final FocusNode _fokus = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<ZakupiBloc>().add(const ZatrazeniZakupi());
  }

  @override
  void dispose() {
    _fokus.dispose();
    super.dispose();
  }

  void _izaberi(ZakupId id) {
    setState(() {
      _izabraniId = _izabraniId == id ? null : id;
    });
  }

  void _idiNaStranicu(int stranica) {
    setState(() => _izabraniId = null);
    context.read<ZakupiBloc>().add(IzabranaStranicaZakupa(stranica));
  }

  bool _imaPravo(AkcijaZakupa akcija) => imaPravoNaAkciju(
    uloga: Uloga.osoblje,
    akcija: akcija,
    jeSvojZakup: false,
  );

  void _potvrdi(Zakup zakup) {
    if (!_imaPravo(AkcijaZakupa.odobri) ||
        !mozePrelaz(zakup.status, const Odobren())) {
      return;
    }

    context.read<ZakupiBloc>().add(
      PromenaStatusaZakupa(id: zakup.id, noviStatus: const Odobren()),
    );
  }

  Future<void> _zavrsiSpor(Zakup zakup, bool depozitVracen) async {
    if (!_imaPravo(AkcijaZakupa.resiSpor) ||
        zakup.status is! Sporan ||
        !mozePrelaz(zakup.status, const Zavrsen())) {
      return;
    }

    final odluka = depozitVracen ? 'Vrati depozit' : 'Naplati depozit';

    final potvrda = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$odluka?'),
        content: const Text(
          'Spor će biti završen. Ova radnja ne može da se poništi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Nazad'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );

    if (!mounted || potvrda != true) return;

    context.read<ZakupiBloc>().add(
      PromenaStatusaZakupa(
        id: zakup.id,
        noviStatus: Zavrsen(depozitVracen: depozitVracen),
      ),
    );
  }

  void _prikaziObavestenje(BuildContext context, ZakupiState stanje) {
    if (stanje is! ZakupiUcitani) return;

    final poruka = switch (stanje.obavestenje) {
      ZakupOtkazan() => 'Zakup je uspešno otkazan.',
      ZakupOdobren() => 'Zakup je uspešno odobren.',
      OtkazivanjeOdbijeno(:final greska) => porukaGreskeZakupa(greska),
      PromenaZakupaOdbijena(:final greska) => porukaGreskeZakupa(greska),
      _ => null,
    };

    if (poruka == null) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(poruka)));

    context.read<ZakupiBloc>().add(const ObavestenjePotvrdjeno());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Backoffice - Raspored i zakupi',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Osveži zakupe',
            onPressed: () {
              context.read<ZakupiBloc>().add(OsvezeniZakupi());
            },
          ),
          if (widget.onOdjava != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Odjavi se',
              onPressed: widget.onOdjava,
            ),
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Simuliraj grešku',
            onPressed: () {
              context.read<ZakupRepository>().simulirajGresku();
              context.read<ZakupiBloc>().add(const ZatrazeniZakupi());
            },
          ),
        ],
      ),
      bottomNavigationBar: widget.prikaziStranice ? _stranice() : null,
      body: BackofficeShortcuts(
        focusNode: _fokus,
        selectedId: _izabraniId,
        onSelectionChanged: (id) {
          setState(() => _izabraniId = id);
        },
        child: BlocConsumer<ZakupiBloc, ZakupiState>(
          listener: _prikaziObavestenje,
          builder: (context, stanje) => switch (stanje) {
            ZakupiUcitavanje() => const Center(
              child: CircularProgressIndicator(),
            ),
            ZakupiPrazno() => const Center(
              child: Text('Trenutno nema zakupa.'),
            ),
            ZakupiGreska(:final greska) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(porukaGreskeZakupa(greska)),
                  TextButton(
                    onPressed: () {
                      context.read<ZakupiBloc>().add(const ZatrazeniZakupi());
                    },
                    child: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            ),
            ZakupiUcitani(:final zakupi) => _raspored(zakupi),
          },
        ),
      ),
    );
  }

  Widget _stranice() {
    return BlocBuilder<ZakupiBloc, ZakupiState>(
      builder: (context, stanje) {
        final bloc = context.read<ZakupiBloc>();
        final stranica = bloc.stranica;
        final ucitavanje = stanje is ZakupiUcitavanje;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: !ucitavanje && stranica > 0
                      ? () => _idiNaStranicu(stranica - 1)
                      : null,
                  child: const Text('Prethodna'),
                ),
                Text('Stranica ${stranica + 1}'),
                TextButton(
                  onPressed: stanje is ZakupiUcitani && bloc.imaSledecuStranicu
                      ? () => _idiNaStranicu(stranica + 1)
                      : null,
                  child: const Text('Sledeća'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _raspored(List<Zakup> zakupi) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imaIzbor = zakupi.any((zakup) => zakup.id == _izabraniId);

        if (constraints.maxWidth < 950) {
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: zakupi.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final zakup = zakupi[index];

                    return ListTile(
                      isThreeLine: true,
                      selected: zakup.id == _izabraniId,
                      selectedTileColor: Colors.blue.shade50,
                      title: Text(
                        _naslovZakupa(zakup),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${_periodZakupa(zakup)}\n'
                        'Status: ${zakup.status.runtimeType}',
                      ),
                      onTap: () => _izaberi(zakup.id),
                    );
                  },
                ),
              ),
              if (imaIzbor) ...[
                const Divider(height: 1, thickness: 2),
                Expanded(child: _detalj(zakupi)),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: DataTable(
                  showCheckboxColumn: false,
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('Zahtev')),
                    DataColumn(label: Text('Termin')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: [
                    for (final zakup in zakupi)
                      DataRow(
                        selected: zakup.id == _izabraniId,
                        onSelectChanged: (_) => _izaberi(zakup.id),
                        cells: [
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 210),
                              child: Text(
                                _naslovZakupa(zakup),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(_periodZakupa(zakup))),
                          DataCell(Text(zakup.status.runtimeType.toString())),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _detalj(zakupi)),
          ],
        );
      },
    );
  }

  Widget _detalj(List<Zakup> zakupi) {
    Zakup? izabrani;

    for (final zakup in zakupi) {
      if (zakup.id == _izabraniId) {
        izabrani = zakup;
        break;
      }
    }

    if (izabrani == null) {
      return const Center(child: Text('Izaberi zakup za prikaz detalja.'));
    }

    final zakup = izabrani;

    final mozeDaPotvrdi =
        _imaPravo(AkcijaZakupa.odobri) &&
        mozePrelaz(zakup.status, const Odobren());

    final mozeDaOdbije =
        _imaPravo(AkcijaZakupa.odbij) &&
        mozePrelaz(zakup.status, const Odbijen(razlog: ''));

    final mozeDaResiSpor =
        _imaPravo(AkcijaZakupa.resiSpor) &&
        zakup.status is Sporan &&
        mozePrelaz(zakup.status, const Zavrsen());

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          _naslovZakupa(zakup),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final visina = (constraints.maxWidth * 0.45)
                .clamp(88.0, 180.0)
                .toDouble();

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Image.asset(
                  'assets/predmeti/${zakup.predmet.id}.jpg',
                  package: 'mobile',
                  height: visina,
                  fit: BoxFit.contain,
                  semanticLabel: zakup.predmet.naziv,
                  errorBuilder: (context, error, stackTrace) => SizedBox(
                    height: visina,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Predmet'),
          subtitle: Text(zakup.predmet.naziv),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Period zakupa'),
          subtitle: Text('${_periodZakupa(zakup)} (${zakup.brojDana} dana)'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Status'),
          subtitle: Text(zakup.status.runtimeType.toString()),
        ),
        if (zakup.status case Zavrsen(depozitVracen: final bool vracen))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Odluka o depozitu'),
            subtitle: Text(vracen ? 'Depozit vraćen' : 'Depozit naplaćen'),
          ),
        if (zakup.status case Odbijen(:final razlog))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Razlog odbijanja'),
            subtitle: Text(razlog),
          ),
        if (zakup.status case Sporan(:final opis)) ...[
          const Divider(),
          Text(opis),
          const SizedBox(height: 12),
          const Text(
            'Otvoren spor — poređenje fotografija',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _fotografijaSpora(
                  'Preuzimanje',
                  Icons.inventory_2_outlined,
                  Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _fotografijaSpora(
                  'Vraćanje',
                  Icons.broken_image_outlined,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: mozeDaResiSpor
                    ? () => _zavrsiSpor(zakup, true)
                    : null,
                child: const Text('Vrati depozit'),
              ),
              FilledButton(
                onPressed: mozeDaResiSpor
                    ? () => _zavrsiSpor(zakup, false)
                    : null,
                child: const Text('Naplati depozit'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: mozeDaPotvrdi ? () => _potvrdi(zakup) : null,
              child: const Text('Potvrdi'),
            ),
            OutlinedButton(
              onPressed: mozeDaOdbije ? () => odbijZakup(context, zakup) : null,
              child: const Text('Odbij'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fotografijaSpora(String naslov, IconData ikonica, Color boja) =>
      Column(
        children: [
          Text(naslov),
          const SizedBox(height: 4),
          Container(
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: boja),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(ikonica, color: boja, size: 36),
          ),
        ],
      );
}

String _naslovZakupa(Zakup zakup) {
  final oznaka = zakup.oznakaZakupca;

  return oznaka == null
      ? zakup.predmet.naziv
      : '$oznaka — ${zakup.predmet.naziv}';
}

String _periodZakupa(Zakup zakup) {
  String datum(DateTime d) => '${d.day}.${d.month}.${d.year}.';

  return '${datum(zakup.datumOd)} – ${datum(zakup.datumDo)}';
}
