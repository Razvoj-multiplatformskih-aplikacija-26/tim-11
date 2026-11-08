import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart';

Handler katalogHandler(Session baza) {
  return (request) async {
    final redovi = await baza.execute('''
      SELECT id, naziv, brend, kategorija, cena_po_danu, depozit, opis, vlasnik
      FROM predmeti
      ORDER BY naziv, id
    ''');

    final odgovor = ListaPredmetaOdgovor(
      predmeti: [
        for (final red in redovi)
          PredmetDto(
            id: red[0] as String,
            naziv: red[1] as String,
            brend: red[2] as String,
            kategorija: red[3] as String,
            cenaPoDanu: red[4] as int,
            depozit: red[5] as int,
            opis: red[6] as String,
            vlasnik: red[7] as String,
          ),
      ],
    );

    return Response.ok(
      body: Body.fromString(
        jsonEncode(odgovor.toJson()),
        mimeType: MimeType.json,
      ),
    );
  };
}

Handler zauzetiPeriodiHandler(Session baza) {
  return (request) async {
    final predmetId = request.pathParameters.raw[#id]!;
    final redovi = await baza.execute(
      Sql.named('''
        SELECT datum_od::text, datum_do::text
        FROM zakupi
        WHERE predmet_id = @predmet
          AND datum_do >= CURRENT_DATE
          AND status IN ('zahtev', 'odobren', 'placen', 'preuzet')
        ORDER BY datum_od, datum_do
      '''),
      parameters: {'predmet': predmetId},
    );

    final odgovor = ZauzetiPeriodiOdgovor(
      periodi: [
        for (final red in redovi)
          ZauzetPeriodDto(datumOd: red[0] as String, datumDo: red[1] as String),
      ],
    );

    return Response.ok(
      body: Body.fromString(
        jsonEncode(odgovor.toJson()),
        mimeType: MimeType.json,
      ),
    );
  };
}
