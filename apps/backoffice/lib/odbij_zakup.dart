import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> odbijZakup(BuildContext context, Zakup zakup) async {
  if (zakup.status is! Zahtev ||
      !imaPravoNaAkciju(
        uloga: Uloga.osoblje,
        akcija: AkcijaZakupa.odbij,
        jeSvojZakup: false,
      )) {
    return;
  }

  final forma = GlobalKey<FormState>();
  var razlog = '';

  final potvrda = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Odbij zahtev'),
      content: Form(
        key: forma,
        child: TextFormField(
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Razlog odbijanja'),
          onChanged: (vrednost) => razlog = vrednost.trim(),
          validator: (vrednost) => (vrednost ?? '').trim().isEmpty
              ? 'Unesi razlog odbijanja.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Nazad'),
        ),
        FilledButton(
          onPressed: () {
            if (forma.currentState!.validate()) {
              Navigator.of(dialogContext).pop(razlog);
            }
          },
          child: const Text('Odbij zahtev'),
        ),
      ],
    ),
  );

  if (!context.mounted || potvrda == null) return;

  context.read<ZakupiBloc>().add(
    PromenaStatusaZakupa(
      id: zakup.id,
      noviStatus: Odbijen(razlog: potvrda),
    ),
  );
}
