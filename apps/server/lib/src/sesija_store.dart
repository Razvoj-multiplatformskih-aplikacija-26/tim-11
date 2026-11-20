import 'package:api_contract/api_contract.dart';
import 'package:postgres/postgres.dart';

import 'jwt_sesije.dart';

final class SesijaStore {
  const SesijaStore(this._baza, {required this.jwt});

  final Connection _baza;
  final JwtSesije jwt;

  Future<({String id, String uloga})?> proveriLozinku(
    String email,
    String lozinka,
  ) async {
    final redovi = await _baza.execute(
      Sql.named('''
        SELECT id, uloga
        FROM korisnici
        WHERE email = @email
          AND lozinka_hes = crypt(@lozinka, lozinka_hes)
      '''),
      parameters: {
        'email': email,
        'lozinka': lozinka,
      },
    );

    if (redovi.isEmpty) return null;

    final red = redovi.single;
    return (
      id: red[0] as String,
      uloga: red[1] as String,
    );
  }

  Future<PrijavaOdgovor> napraviSesiju({
    required String korisnikId,
    required String uloga,
  }) async {
    final sesija = jwt.napravi(
      id: korisnikId,
      uloga: uloga,
    );

    await _baza.execute(
      Sql.named('''
        INSERT INTO sesije (token_hes, korisnik_id, istice_u)
        VALUES (
          encode(digest(CAST(@token AS text), 'sha256'), 'hex'),
          @id,
          CAST(@istice AS text)::timestamptz
        )
      '''),
      parameters: {
        'token': sesija.token!,
        'id': korisnikId,
        'istice': sesija.isticeU,
      },
    );

    return sesija;
  }

  Future<({String id, String uloga})?> procitaj(String token) async {
    final potpisana = jwt.proveri(token);
    if (potpisana == null) return null;

    final redovi = await _baza.execute(
      Sql.named('''
        SELECT k.id, k.uloga
        FROM sesije s
        JOIN korisnici k ON k.id = s.korisnik_id
        WHERE s.token_hes =
              encode(digest(CAST(@token AS text), 'sha256'), 'hex')
          AND s.korisnik_id = @id
          AND s.istice_u > now()
      '''),
      parameters: {
        'token': token,
        'id': potpisana.id,
      },
    );

    if (redovi.isEmpty || redovi.single[1] != potpisana.uloga) {
      return null;
    }

    return (
      id: potpisana.id,
      uloga: potpisana.uloga,
    );
  }

  Future<PrijavaOdgovor?> trenutna(String token) async {
    final korisnik = await procitaj(token);
    if (korisnik == null) return null;

    final podaci = jwt.proveri(token)!;

    return PrijavaOdgovor(
      uloga: korisnik.uloga,
      isticeU: podaci.isticeU.toIso8601String(),
    );
  }

  Future<void> obrisi(String token) async {
    await _baza.execute(
      Sql.named('''
        DELETE FROM sesije
        WHERE token_hes =
              encode(digest(CAST(@token AS text), 'sha256'), 'hex')
      '''),
      parameters: {'token': token},
    );
  }
}