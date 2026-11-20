import 'dart:convert';
import 'dart:math';

import 'package:api_contract/api_contract.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

final class JwtSesije {
  JwtSesije({
    required String tajna,
    required this.ttl,
  }) : _kljuc = SecretKey(tajna);

  final Duration ttl;
  final SecretKey _kljuc;

  PrijavaOdgovor napravi({
    required String id,
    required String uloga,
  }) {
    final random = Random.secure();
    final jti = base64UrlEncode(
      List.generate(32, (_) => random.nextInt(256)),
    );

    final token = JWT(
      {
        'role': uloga,
        'jti': jti,
      },
      subject: id,
      issuer: 'rent-a-luxury',
    ).sign(
      _kljuc,
      algorithm: JWTAlgorithm.HS256,
      expiresIn: ttl,
    );

    final sesija = proveri(token)!;

    return PrijavaOdgovor(
      token: token,
      uloga: uloga,
      isticeU: sesija.isticeU.toIso8601String(),
    );
  }

  ({String id, String uloga, DateTime isticeU})? proveri(String token) {
    try {
      if (JWT.decode(token).header?['alg'] != JWTAlgorithm.HS256.name) {
        return null;
      }

      final jwt = JWT.verify(token, _kljuc);

      if (jwt.payload case {
        'iss': 'rent-a-luxury',
        'sub': final String id,
        'role': final String uloga,
        'jti': final String jti,
        'exp': final int exp,
      }) {
        final isticeU = DateTime.fromMillisecondsSinceEpoch(
          exp * 1000,
          isUtc: true,
        );

        if (id.isNotEmpty &&
            jti.isNotEmpty &&
            (uloga == 'zakupac' || uloga == 'osoblje') &&
            isticeU.isAfter(DateTime.now())) {
          return (
            id: id,
            uloga: uloga,
            isticeU: isticeU,
          );
        }
      }
    } on JWTException {
      return null;
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }

    return null;
  }
}