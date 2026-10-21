import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('Aplikacija se pokrece sa tabom Katalog', (tester) async {
    await tester.pumpWidget(const RentALuxuryApp());
    expect(find.text('Katalog'), findsWidgets);
  });
}