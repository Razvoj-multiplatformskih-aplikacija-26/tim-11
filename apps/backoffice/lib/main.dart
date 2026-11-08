import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'screens/schedule_screen.dart';

import 'package:session_storage/session_storage.dart';

void main() {
  runApp(const BackofficeApp());
}

class BackofficeApp extends StatelessWidget {
  const BackofficeApp({
    super.key,
    this.skladiste = const BezbednoSkladisteSesije(
      kljuc: 'rent_a_luxury_backoffice_sesija',
    ),
  });

  final SkladisteSesije skladiste;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rent a Luxury Backoffice',
      home: _BackofficeSesija(skladiste: skladiste),
    );
  }
}

class _BackofficeSesija extends StatefulWidget {
  const _BackofficeSesija({required this.skladiste});

  final SkladisteSesije skladiste;

  @override
  State<_BackofficeSesija> createState() => _BackofficeSesijaState();
}

class _BackofficeSesijaState extends State<_BackofficeSesija> {
  final _email = TextEditingController();
  final _lozinka = TextEditingController();

  final _api = RentApi(
    adresaServera: Uri.parse(
      const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://127.0.0.1:8080',
      ),
    ),
  );

  late final _repository = HttpZakupRepository(
    api: _api,
    procitajToken: () => _sesija?.token,
    velicinaStranice: 5,
  );

  PrijavaOdgovor? _sesija;
  bool _prijavaUToku = false;
  String? _greska;

  SkladisteSesije get _skladiste => widget.skladiste;

  bool _obnovaUToku = true;

  @override
  void initState() {
    super.initState();
    _obnoviSesiju();
  }

  Future<void> _obnoviSesiju() async {
    try {
      final sacuvana = await _skladiste.ucitaj();
      if (!mounted) return;

      setState(() {
        _sesija = sacuvana?.uloga == 'osoblje' ? sacuvana : null;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _greska = 'Sačuvana prijava nije dostupna.');
    } finally {
      if (mounted) setState(() => _obnovaUToku = false);
    }
  }

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
      final sesija = await _api.prijaviSe(
        PrijavaZahtev(email: email, lozinka: lozinka, aplikacija: 'backoffice'),
      );
      await _skladiste.sacuvaj(sesija);

      if (!mounted) return;
      _lozinka.clear();
      setState(() => _sesija = sesija);
    } on ApiIzuzetak catch (greska) {
      if (!mounted) return;
      setState(() {
        _greska = switch (greska.greska.kod) {
          'pogresna_aplikacija' => 'Backoffice je namenjen osoblju.',
          'neispravni_podaci_za_prijavu' => 'Email ili lozinka nisu ispravni.',
          'server_nedostupan' =>
            'Server trenutno nije dostupan. Pokušaj ponovo.',
          _ => 'Prijava nije uspela. Pokušaj ponovo.',
        };
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _greska = 'Prijava nije mogla da se sačuva.');
    } finally {
      if (mounted) {
        setState(() => _prijavaUToku = false);
      }
    }
  }

  Future<void> _odjaviSe() async {
    final token = _sesija?.token;
    if (token == null) return;

    try {
      await _api.odjaviSe(token: token);
      await _skladiste.obrisi();
      if (!mounted) return;
      setState(() => _sesija = null);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odjava nije uspela. Pokušaj ponovo.')),
      );
    }
  }

  Future<void> _obradiIstekSesije() async {
    if (_sesija == null) return;

    setState(() {
      _sesija = null;
      _greska = 'Prijava je istekla. Prijavi se ponovo.';
    });

    try {
      await _skladiste.obrisi();
    } on Exception {
      // Nevažeća sesija je već uklonjena iz memorije.
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _lozinka.dispose();
    _api.zatvori();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_obnovaUToku) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_sesija != null) {
      return RepositoryProvider<ZakupRepository>.value(
        value: _repository,
        child: BlocProvider<ZakupiBloc>(
          create: (_) {
            _repository.izaberiStranicu(0);
            return ZakupiBloc(zakupRepository: _repository);
          },
          child: BlocListener<ZakupiBloc, ZakupiState>(
            listener: (context, stanje) async {
              if (stanje case ZakupiGreska(
                greska: ServerskaGreska(kod: 'potrebna_prijava'),
              )) {
                await _obradiIstekSesije();
              }
            },
            child: ScheduleScreen(onOdjava: _odjaviSe, prikaziStranice: true),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rent a Luxury Backoffice')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Prijava osoblja',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lozinka,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Lozinka'),
                  onSubmitted: (_) => _prijaviSe(),
                ),
                if (_greska case final poruka?) ...[
                  const SizedBox(height: 12),
                  Text(
                    poruka,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _prijavaUToku ? null : _prijaviSe,
                  child: Text(
                    _prijavaUToku ? 'Prijava je u toku…' : 'Prijavi se',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
