import 'package:flutter/material.dart';

import '../models/predmet.dart';
import 'ikonica_kategorije.dart';

/// Fotografija predmeta iz assets, ako slika ne postoji, prikazuje ikonicu kategorije umesto nje
class SlikaPredmeta extends StatelessWidget {
  const SlikaPredmeta({
    super.key,
    required this.predmet,
    this.sirina,
    this.visina,
    this.zaobljenje = 12,
  });

  final Predmet predmet;
  final double? sirina;
  final double? visina;
  final double zaobljenje;

    @override
  Widget build(BuildContext context) {
    // Gustina piksela ekrana 
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // Ako je širina "beskonačna" (detalj), uzmi širinu ekrana.
    final prikaznaSirina = (sirina != null && sirina!.isFinite)
        ? sirina!
        : MediaQuery.sizeOf(context).width;

    return ClipRRect(
      borderRadius: BorderRadius.circular(zaobljenje),
      child: Image.asset(
        'assets/predmeti/${predmet.id}.jpg',
        width: sirina,
        height: visina,
        fit: BoxFit.cover,
        // Dekodiraj sliku samo u veličini koja se zaista vidi:
        // brže učitavanje, manje memorije, nema treptanja
        cacheWidth: (prikaznaSirina * dpr).round(),
        // Dok se nova slika učitava, ne prikazuj prazno mesto
        gaplessPlayback: true,
        // Ako slika fali, umesto pada aplikacije prikaži ikonicu
        errorBuilder: (context, error, stackTrace) => Container(
          width: sirina,
          height: visina,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(ikonicaKategorije(predmet.kategorija)),
        ),
      ),
    );
  }
}