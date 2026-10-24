import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/zahtev_forma_screen.dart';

void main() {
  testWidgets('forma traži datume pre slanja zahteva', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ZahtevFormaScreen(predmetId: PredmetId('p-1'))),
    );

    await tester.tap(find.text('Pošalji zahtev'));
    await tester.pump();

    expect(find.text('Izaberi datume zakupa.'), findsOneWidget);
  });
}