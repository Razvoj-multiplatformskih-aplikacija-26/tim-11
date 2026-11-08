import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../data/mobilna_sesija.dart';
import '../text/poruke_gresaka.dart';
import '../widgets/prijava_zakupca.dart';
import '../widgets/zakup_kartica.dart';

class MojiZakupiScreen extends StatefulWidget {
  const MojiZakupiScreen({super.key});

  @override
  State<MojiZakupiScreen> createState() => _MojiZakupiScreenState();
}

class _MojiZakupiScreenState extends State<MojiZakupiScreen> {
  bool _odjavaUToku = false;

  @override
  void initState() {
    super.initState();
    if (context.read<MobilnaSesija>().token != null) {
      context.read<ZakupiBloc>().add(const ZatrazeniZakupi());
    }
  }

  Future<void> _prijaviSe() async {
    final prijavljen = await zatraziPrijavuZakupca(context);
    if (!mounted || !prijavljen) return;

    context.read<ZakupiBloc>().add(const ZatrazeniZakupi());
    setState(() {});
  }

  Future<void> _odjaviSe() async {
    if (_odjavaUToku) return;

    final sesija = context.read<MobilnaSesija>();
    setState(() => _odjavaUToku = true);

    try {
      await sesija.odjaviSe();
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odjava nije u potpunosti uspela.')),
      );
    } finally {
      if (mounted) setState(() => _odjavaUToku = false);
    }
  }

  Future<void> _osvezi() {
    final dogadjaj = OsvezeniZakupi();
    context.read<ZakupiBloc>().add(dogadjaj);
    return dogadjaj.handled;
  }

  @override
  Widget build(BuildContext context) {
    final sesija = context.read<MobilnaSesija>();
    final token = sesija.token;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moji zakupi'),
        actions: [
          if (token != null)
            IconButton(
              onPressed: _osvezi,
              icon: const Icon(Icons.refresh),
              tooltip: 'Osveži zakupe',
            ),
          if (token != null)
            IconButton(
              onPressed: _odjavaUToku ? null : _odjaviSe,
              icon: const Icon(Icons.logout),
              tooltip: 'Odjavi se',
            ),
        ],
      ),
      body: token == null
          ? Center(
              child: FilledButton(
                onPressed: _prijaviSe,
                child: const Text('Prijavi se da vidiš svoje zakupe'),
              ),
            )
          : BlocConsumer<ZakupiBloc, ZakupiState>(
              listener: (context, stanje) async {
                if (stanje case ZakupiGreska(
                  greska: ServerskaGreska(kod: 'potrebna_prijava'),
                )) {
                  try {
                    await sesija.zaboraviToken(token);
                  } on Exception {
                    // Sesija je već uklonjena iz memorije.
                  }
                  if (!mounted || !context.mounted) return;
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Prijava je istekla. Prijavi se ponovo.'),
                    ),
                  );
                }
              },
              builder: (context, stanje) => switch (stanje) {
                ZakupiUcitavanje() => const Center(
                  child: CircularProgressIndicator(),
                ),
                ZakupiPrazno() => const Center(
                  child: Text('Još nemaš nijedan zakup.'),
                ),
                ZakupiGreska(:final greska) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        greska is DomenskaGreska
                            ? greska.poruka
                            : 'Zakupi trenutno nisu dostupni.',
                      ),
                      TextButton(
                        onPressed: _osvezi,
                        child: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  ),
                ),
                ZakupiUcitani(:final zakupi) => RefreshIndicator(
                  onRefresh: _osvezi,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: zakupi.length,
                    itemBuilder: (context, i) {
                      final zakup = zakupi[i];
                      return ZakupKartica(
                        zakup: zakup,
                        onTap: () => context.push('/zakupi/${zakup.id.value}'),
                      );
                    },
                  ),
                ),
              },
            ),
    );
  }
}
