import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mobilna_sesija.dart';

Future<bool> zatraziPrijavuZakupca(BuildContext context) async {
  final sesija = context.read<MobilnaSesija>();
  if (sesija.token != null) return true;

  return await showDialog<bool>(
        context: context,
        builder: (_) => _PrijavaZakupca(sesija: sesija),
      ) ??
      false;
}

class _PrijavaZakupca extends StatefulWidget {
  const _PrijavaZakupca({required this.sesija});

  final MobilnaSesija sesija;

  @override
  State<_PrijavaZakupca> createState() => _PrijavaZakupcaState();
}

class _PrijavaZakupcaState extends State<_PrijavaZakupca> {
  final _email = TextEditingController();
  final _lozinka = TextEditingController();
  bool _prijavaUToku = false;
  String? _greska;

  Future<void> _prijaviSe() async {
    if (_prijavaUToku) return;

    final email = _email.text.trim();
    final lozinka = _lozinka.text;
    if (email.isEmpty || lozinka.isEmpty) {
      setState(() => _greska = 'Unesi email i lozinku.');
      return;
    }

    setState(() {
      _prijavaUToku = true;
      _greska = null;
    });

    try {
      await widget.sesija.prijaviSe(email: email, lozinka: lozinka);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiIzuzetak catch (greska) {
      if (!mounted) return;

      setState(() {
        _prijavaUToku = false;
        _greska = switch (greska.greska.kod) {
          'neispravni_podaci_za_prijavu' => 'Email ili lozinka nisu ispravni.',
          'pogresna_aplikacija' => 'Mobilna aplikacija je namenjena zakupcima.',
          'server_nedostupan' => 'Server trenutno nije dostupan.',
          _ => 'Prijava nije uspela. Pokušaj ponovo.',
        };
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _lozinka.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_prijavaUToku,
      child: AlertDialog(
        title: const Text('Prijava zakupca'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _email,
                enabled: !_prijavaUToku,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _lozinka,
                enabled: !_prijavaUToku,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Lozinka'),
                onSubmitted: (_) => _prijaviSe(),
              ),
              if (_greska case final poruka?) ...[
                const SizedBox(height: 12),
                Text(
                  poruka,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _prijavaUToku ? null : () => Navigator.of(context).pop(),
            child: const Text('Nazad'),
          ),
          FilledButton(
            onPressed: _prijavaUToku ? null : _prijaviSe,
            child: Text(_prijavaUToku ? 'Prijava je u toku…' : 'Prijavi se'),
          ),
        ],
      ),
    );
  }
}
