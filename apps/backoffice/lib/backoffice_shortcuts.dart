import 'package:backoffice/odbij_zakup.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BackofficeShortcuts extends StatelessWidget {
  const BackofficeShortcuts({
    super.key,
    required this.focusNode,
    required this.selectedId,
    required this.onSelectionChanged,
    required this.child,
  });

  final FocusNode focusNode;
  final ZakupId? selectedId;
  final ValueChanged<ZakupId?> onSelectionChanged;
  final Widget child;

  void _navigirajKrozListu(List<Zakup> zakupi, int smer) {
    if (zakupi.isEmpty) return;

    final trenutniIndeks = zakupi.indexWhere((zakup) => zakup.id == selectedId);

    if (trenutniIndeks == -1) {
      onSelectionChanged(zakupi.first.id);
      return;
    }

    final noviIndeks = trenutniIndeks + smer;

    if (noviIndeks >= 0 && noviIndeks < zakupi.length) {
      onSelectionChanged(zakupi[noviIndeks].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        final stanje = context.read<ZakupiBloc>().state;
        if (stanje is! ZakupiUcitani) return KeyEventResult.ignored;

        final zakupi = stanje.zakupi;
        final taster = event.logicalKey;

        if (taster == LogicalKeyboardKey.arrowDown) {
          _navigirajKrozListu(zakupi, 1);
          return KeyEventResult.handled;
        }

        if (taster == LogicalKeyboardKey.arrowUp) {
          _navigirajKrozListu(zakupi, -1);
          return KeyEventResult.handled;
        }

        final indeks = zakupi.indexWhere((zakup) => zakup.id == selectedId);

        if (indeks == -1) return KeyEventResult.ignored;

        final zakup = zakupi[indeks];

        if (taster == LogicalKeyboardKey.enter &&
            imaPravoNaAkciju(
              uloga: Uloga.osoblje,
              akcija: AkcijaZakupa.odobri,
              jeSvojZakup: false,
            ) &&
            mozePrelaz(zakup.status, const Odobren())) {
          context.read<ZakupiBloc>().add(
            PromenaStatusaZakupa(id: zakup.id, noviStatus: const Odobren()),
          );

          return KeyEventResult.handled;
        }

        if ((taster == LogicalKeyboardKey.delete ||
                taster == LogicalKeyboardKey.backspace) &&
            imaPravoNaAkciju(
              uloga: Uloga.osoblje,
              akcija: AkcijaZakupa.odbij,
              jeSvojZakup: false,
            ) &&
            mozePrelaz(zakup.status, const Odbijen(razlog: ''))) {
          odbijZakup(context, zakup);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
