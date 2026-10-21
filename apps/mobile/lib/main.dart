import 'package:flutter/material.dart';
import 'router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() => runApp(const RentALuxuryApp());

class RentALuxuryApp extends StatelessWidget {
  const RentALuxuryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rent a Luxury',
      debugShowCheckedModeBanner: false,
            theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B6F47)),
        fontFamily: 'Lato',
      ),
      routerConfig: router,
              locale: const Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
        supportedLocales: const [
          Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
        ],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}