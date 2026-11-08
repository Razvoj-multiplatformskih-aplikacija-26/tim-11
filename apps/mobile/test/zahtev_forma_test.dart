import 'package:api_client/api_client.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/katalog_repository.dart';
import 'package:mobile/screens/zahtev_forma_screen.dart';

void main() {
  testWidgets('Forma traži datume pre slanja zahteva', (tester) async {
    final api = RentApi(
      adresaServera: Uri.parse('http://localhost:8080'),
      klijent: MockClient((zahtev) async {
        expect(zahtev.method, 'GET');
        expect(zahtev.url.path, '/predmeti/p-1/zauzeti-periodi');
        return http.Response('{"periodi":[]}', 200);
      }),
    );
    addTearDown(api.zatvori);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<RentApi>.value(value: api),
          RepositoryProvider<KatalogRepository>.value(
            value: const _ProbniKatalog(),
          ),
        ],
        child: const MaterialApp(
          home: ZahtevFormaScreen(predmetId: PredmetId('p-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pošalji zahtev'));
    await tester.pump();

    expect(find.text('Izaberi datume zakupa.'), findsOneWidget);
  });
}

final class _ProbniKatalog implements KatalogRepository {
  const _ProbniKatalog();

  @override
  Future<List<Predmet>> preuzmiPredmete() async => [
    const Predmet(
      id: PredmetId('p-1'),
      naziv: 'Probna torba',
      brend: 'Demo',
      kategorija: Kategorija.torba,
      cenaPoDanu: 45,
      depozit: 800,
      opis: 'Predmet za test forme.',
      vlasnik: 'Demo vlasnik',
    ),
  ];
}
