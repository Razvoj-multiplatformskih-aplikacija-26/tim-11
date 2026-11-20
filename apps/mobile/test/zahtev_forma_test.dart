import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/katalog_repository.dart';
import 'package:mobile/screens/zahtev_forma_screen.dart';

void main() {
  testWidgets('Forma traži datume pre slanja zahteva', (tester) async {
    final zahtevi = _ProbniZahtevi();

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<KatalogRepository>.value(
            value: const _ProbniKatalog(),
          ),
          RepositoryProvider<NoviZakupRepository>.value(value: zahtevi),
        ],
        child: const MaterialApp(
          home: ZahtevFormaScreen(predmetId: PredmetId('p-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Pošalji zahtev'));
    await tester.tap(find.text('Pošalji zahtev'));
    await tester.pump();

    expect(find.text('Izaberi datume zakupa.'), findsOneWidget);
    expect(zahtevi.brojSlanja, 0);
  });
}

final class _ProbniZahtevi implements NoviZakupRepository {
  int brojSlanja = 0;

  @override
  Future<Rezultat<List<PeriodZakupa>>> preuzmiZauzetePeriode(
    PredmetId predmetId,
  ) async => const Uspeh<List<PeriodZakupa>>([]);

  @override
  Future<Rezultat<ZakupId>> posaljiZahtev({
    required PredmetId predmetId,
    required PeriodZakupa period,
  }) async {
    brojSlanja++;
    return const Uspeh<ZakupId>(ZakupId('test-zakup'));
  }
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
