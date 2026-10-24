import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:domain/domain.dart';
import 'slika_predmeta.dart';
import 'status_oznaka.dart';


final _datum = DateFormat('d. M. yyyy.');

/// Jedan zakup u listi: predmet, datumi, cena i, dole desno, status
class ZakupKartica extends StatelessWidget {
  const ZakupKartica({super.key, required this.zakup, this.onTap});
  final Zakup zakup;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final predmet = zakup.predmet;
    final tekst = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gornji deo: ikonica + naziv, datumi, cena
              Row(
                children: [
                                      SlikaPredmeta(predmet: predmet, sirina: 64, visina: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${predmet.brend} ${predmet.naziv}',
                          style: tekst.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_datum.format(zakup.datumOd)} – '
                          '${_datum.format(zakup.datumDo)}',
                        ),
                        Text('${zakup.ukupnaCena} €'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

                             // Donji desni ugao
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Status: ', style: tekst.bodySmall),
                      StatusOznaka(status: zakup.status),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}