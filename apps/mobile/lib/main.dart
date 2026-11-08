import 'package:api_client/api_client.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/katalog_repository.dart';
import 'data/mobilna_sesija.dart';
import 'router.dart';

void main() => runApp(const RentALuxuryApp());

class RentALuxuryApp extends StatefulWidget {
  const RentALuxuryApp({super.key});

  @override
  State<RentALuxuryApp> createState() => _RentALuxuryAppState();
}

class _RentALuxuryAppState extends State<RentALuxuryApp> {
  final _api = RentApi(
    adresaServera: Uri.parse(
      const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://10.0.2.2:8080',
      ),
    ),
  );

  late final KatalogRepository _katalog = HttpKatalogRepository(_api);
  late final MobilnaSesija _sesija = MobilnaSesija(_api);
  late final Future<void> _obnovaSesije = _sesija.obnovi();
  late final ZakupRepository _zakupRepository = HttpZakupRepository(
    api: _api,
    procitajToken: () => _sesija.token,
  );

  @override
  void dispose() {
    _api.zatvori();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _obnovaSesije,
      builder: (context, stanje) {
        if (stanje.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return _prikaziAplikaciju();
      },
    );
  }

  Widget _prikaziAplikaciju() {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<KatalogRepository>.value(value: _katalog),
        RepositoryProvider<MobilnaSesija>.value(value: _sesija),
        RepositoryProvider<RentApi>.value(value: _api),
        RepositoryProvider<ZakupRepository>.value(value: _zakupRepository),
      ],
      child: BlocProvider(
        create: (_) => ZakupiBloc(zakupRepository: _zakupRepository),
        child: MaterialApp.router(
          title: 'Rent a Luxury',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8B6F47),
            ),
            fontFamily: 'Lato',
          ),
          routerConfig: router,
          locale: const Locale.fromSubtags(
            languageCode: 'sr',
            scriptCode: 'Latn',
          ),
          supportedLocales: const [
            Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      ),
    );
  }
}
