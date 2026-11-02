import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocs/src/moji_zakupi/zakupi_bloc.dart';

class BackofficeShortcuts extends StatelessWidget {
  final FocusNode focusNode;
  final ZakupId? selectedId;
  final ValueChanged<ZakupId?> onSelectionChanged;
  final Widget child;

  const BackofficeShortcuts({
    super.key,
    required this.focusNode,
    required this.selectedId,
    required this.onSelectionChanged,
    required this.child,
  });

  void _navigirajKrozListu(List<Zakup> zakupi, int smer) {
    if (zakupi.isEmpty) return;

    if (selectedId == null) {
      onSelectionChanged(zakupi.first.id);
      return;
    }

    final currentIndex = zakupi.indexWhere((z) => z.id == selectedId);
    final newIndex = currentIndex + smer;

    if (newIndex >= 0 && newIndex < zakupi.length) {
      onSelectionChanged(zakupi[newIndex].id);
    }
  }

  void _izvrsiAkciju(BuildContext context, List<Zakup> zakupi, String akcija) {
    if (selectedId == null) return;
    final selectedItem = zakupi.firstWhere(
          (z) => z.id == selectedId,
      orElse: () => zakupi.first,
    );

    if (akcija == 'potvrdi' && selectedItem.status is Zahtev) {
      context.read<ZakupiBloc>().add(
        PromenaStatusaZakupa(
          id: selectedItem.id,
          noviStatus: const Odobren(),
        ),
      );
    } else if (akcija == 'otkazi' &&
        (selectedItem.status is Zahtev ||
            selectedItem.status is Odobren ||
            selectedItem.status is Placen)) {
      context.read<ZakupiBloc>().add(
        OtkazivanjeZakupa(selectedItem.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        final state = context.read<ZakupiBloc>().state;
        if (state is! ZakupiUcitani) return KeyEventResult.ignored;

        final zakupi = state.zakupi;

        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _navigirajKrozListu(zakupi, 1);
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _navigirajKrozListu(zakupi, -1);
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.enter) {
          _izvrsiAkciju(context, zakupi, 'potvrdi');
          return KeyEventResult.handled;
        }

        if (event.logicalKey == LogicalKeyboardKey.delete ||
            event.logicalKey == LogicalKeyboardKey.backspace) {
          _izvrsiAkciju(context, zakupi, 'otkazi');
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}