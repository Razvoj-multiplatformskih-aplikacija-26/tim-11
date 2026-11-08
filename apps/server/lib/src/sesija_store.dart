import 'package:api_contract/api_contract.dart';
import 'package:postgres/postgres.dart';

final class SesijaStore {
  const SesijaStore(this._baza, {required this.ttlMinuta});

  final Connection _baza;
  final int ttlMinuta;

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
      parameters: {'email': email, 'lozinka': lozinka},
    );

    if (redovi.isEmpty) return null;

    final red = redovi.single;
    return (id: red[0] as String, uloga: red[1] as String);
  }

  Future<PrijavaOdgovor> napraviSesiju({
    required String korisnikId,
    required String uloga,
  }) async {
    final redovi = await _baza.execute(
      Sql.named('''
        WITH novi_token AS (
          SELECT encode(gen_random_bytes(32), 'hex') AS token
        ),
        upis AS (
          INSERT INTO sesije (token_hes, korisnik_id, istice_u)
          SELECT
            encode(digest(token, 'sha256'), 'hex'),
            @id,
            now() + make_interval(mins => @ttl)
          FROM novi_token
          RETURNING istice_u
        )
        SELECT novi_token.token, upis.istice_u
        FROM novi_token CROSS JOIN upis
      '''),
      parameters: {'id': korisnikId, 'ttl': ttlMinuta},
    );

    final red = redovi.single;
    return PrijavaOdgovor(
      token: red[0] as String,
      uloga: uloga,
      isticeU: (red[1] as DateTime).toUtc().toIso8601String(),
    );
  }

  Future<({String id, String uloga})?> procitaj(String token) async {
    final redovi = await _baza.execute(
      Sql.named('''
        SELECT k.id, k.uloga
        FROM sesije s
        JOIN korisnici k ON k.id = s.korisnik_id
        WHERE s.token_hes = encode(digest(CAST(@token AS text), 'sha256'), 'hex')
          AND s.istice_u > now()
      '''),
      parameters: {'token': token},
    );

    if (redovi.isEmpty) return null;

    final red = redovi.single;
    return (id: red[0] as String, uloga: red[1] as String);
  }

  Future<void> obrisi(String token) async {
    await _baza.execute(
      Sql.named('''
        DELETE FROM sesije
        WHERE token_hes = encode(digest(CAST(@token AS text), 'sha256'), 'hex')
      '''),
      parameters: {'token': token},
    );
  }
}
