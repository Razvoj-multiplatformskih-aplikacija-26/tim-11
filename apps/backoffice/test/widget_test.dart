import 'package:api_contract/api_contract.dart';
import 'package:backoffice/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:session_storage/session_storage.dart';

void main() {
  testWidgets('Backoffice bez sesije traži prijavu osoblja', (tester) async {
    await tester.pumpWidget(const BackofficeApp(skladiste: _PraznoSkladiste()));
    await tester.pumpAndSettle();

    expect(find.text('Prijava osoblja'), findsOneWidget);
    expect(find.text('Prijavi se'), findsOneWidget);
  });
}

final class _PraznoSkladiste implements SkladisteSesije {
  const _PraznoSkladiste();

  @override
  Future<PrijavaOdgovor?> ucitaj() async => null;

  @override
  Future<void> sacuvaj(PrijavaOdgovor sesija) async {}

  @override
  Future<void> obrisi() async {}
}
