import 'package:flutter/material.dart';

import '../models/status_zakupa.dart';
import '../models/zakup.dart';

enum _Vrsta { prosao, trenutni, sledi }

class TimelineZakupa extends StatelessWidget {
  const TimelineZakupa({super.key, required this.zakup});

  final Zakup zakup;

  @override
  Widget build(BuildContext context) {
    final istorija = zakup.istorija;
    final koraci = <(StatusZakupa, _Vrsta)>[
      for (var i = 0; i < istorija.length; i++)
        (
          istorija[i],
          i == istorija.length - 1 ? _Vrsta.trenutni : _Vrsta.prosao,
        ),
      for (final s in zakup.sledeciKoraci) (s, _Vrsta.sledi),
    ];

    return Column(
      children: [
        for (var i = 0; i < koraci.length; i++)
          _Korak(
            status: koraci[i].$1,
            vrsta: koraci[i].$2,
            poslednji: i == koraci.length - 1,
          ),
      ],
    );
  }
}

class _Korak extends StatelessWidget {
  const _Korak({
    required this.status,
    required this.vrsta,
    required this.poslednji,
  });

  final StatusZakupa status;
  final _Vrsta vrsta;
  final bool poslednji;

  bool get _negativan =>
      status == StatusZakupa.odbijen ||
      status == StatusZakupa.otkazan ||
      status == StatusZakupa.sporan;

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).colorScheme;
    final tekst = Theme.of(context).textTheme;

    final bojaKruga = switch (vrsta) {
      _Vrsta.sledi => boje.outlineVariant,
      _ when _negativan => boje.error,
      _ => boje.primary,
    };
    // Linija ispod kruga je obojena samo ako je i sledeći korak već prošao
    final bojaLinije =
        vrsta == _Vrsta.prosao ? boje.primary : boje.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Leva kolona: krug + linija do sledećeg koraka
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: vrsta == _Vrsta.sledi
                        ? Colors.transparent
                        : bojaKruga,
                    border: Border.all(color: bojaKruga, width: 2),
                  ),
                ),
                if (!poslednji)
                  Expanded(child: Container(width: 2, color: bojaLinije)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Desna kolona: naziv statusa
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                vrsta == _Vrsta.trenutni
                    ? '${status.naziv} (trenutno)'
                    : status.naziv,
                style: switch (vrsta) {
                  _Vrsta.trenutni => tekst.titleSmall?.copyWith(
                      color: bojaKruga,
                      fontWeight: FontWeight.bold,
                    ),
                  _Vrsta.prosao => tekst.bodyMedium,
                  _Vrsta.sledi => tekst.bodyMedium?.copyWith(
                      color: boje.onSurfaceVariant,
                    ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}