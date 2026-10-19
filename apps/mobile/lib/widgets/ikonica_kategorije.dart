import 'package:flutter/material.dart';
import '../models/predmet.dart';

IconData ikonicaKategorije(Kategorija kategorija) => switch (kategorija) {
      Kategorija.torba => Icons.shopping_bag_outlined,
      Kategorija.sat => Icons.watch_outlined,
      Kategorija.nakit => Icons.diamond_outlined,
      Kategorija.odeca => Icons.checkroom_outlined,
      Kategorija.naocare => Icons.visibility_outlined,
    };