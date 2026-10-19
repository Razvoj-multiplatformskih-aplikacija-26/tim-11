import 'package:flutter/material.dart';
import '../models/predmet.dart';
import 'slika_predmeta.dart';

/// Kartica predmeta u katalogu: slika, brend, naziv i cena po danu
class PredmetKartica extends StatelessWidget {
  const PredmetKartica({super.key, required this.predmet, this.onTap});
  final Predmet predmet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kvadratna slika preko cele širine kartice
            AspectRatio(
              aspectRatio: 1,
              child: SlikaPredmeta(
                predmet: predmet,
                sirina: double.infinity,
                visina: double.infinity,
                zaobljenje: 0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(predmet.brend, style: tekst.labelMedium),
                  Text(
                    predmet.naziv,
                    style: tekst.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${predmet.cenaPoDanu} € / dan',
                    style: tekst.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}