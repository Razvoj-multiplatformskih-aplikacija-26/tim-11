import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/text/nazivi.dart';
import 'package:mobile/text/poruke_gresaka.dart';

void main() {
  test('greska iz domena dobija poruku na srpskom u aplikaciji', () {
    expect(
      const NedozvoljenoTrajanje(20).poruka,
      'Zakup traje od 1 do 14 dana.',
    );
    expect(
      const TerminZauzet().poruka,
      'Predmet je već zauzet u delu izabranog perioda.',
    );
  });

  test('poruka koristi granice koje je vratio server', () {
    const greska = ServerskaGreska(
      'nedozvoljeno_trajanje',
      podaci: {'minDana': 1, 'maxDana': 7},
    );

    expect(greska.poruka, 'Zakup traje od 1 do 7 dana.');
  });

  test('status ima naziv na srpskom', () {
    expect(const Placen().naziv, 'Plaćen');
    expect(const Odbijen(razlog: 'servis').naziv, 'Odbijen');
  });
}
