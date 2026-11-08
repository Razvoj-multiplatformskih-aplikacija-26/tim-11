import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/katalog_repository.dart';
import 'package:mobile/screens/katalog_screen.dart';

void main() {
  testWidgets('Katalog prikazuje prazan rezultat repozitorijuma', (
    tester,
  ) async {
    await tester.pumpWidget(
      RepositoryProvider<KatalogRepository>.value(
        value: const _PrazanKatalog(),
        child: const MaterialApp(home: KatalogScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Katalog'), findsOneWidget);
    expect(find.text('Nema predmeta za izabrani filter.'), findsOneWidget);
  });
}

final class _PrazanKatalog implements KatalogRepository {
  const _PrazanKatalog();

  @override
  Future<List<Predmet>> preuzmiPredmete() async => [];
}
