import 'package:flutter/material.dart';
import 'package:domain/domain.dart';
import '../text/nazivi.dart';

/// Mala obojena oznaka sa nazivom statusa
class StatusOznaka extends StatelessWidget {
  const StatusOznaka({super.key, required this.status});

  final StatusZakupa status;

  Color get _boja => switch (status) {
        Zahtev() => Colors.blueGrey,
        Odobren() => Colors.blue,
        Placen() => Colors.indigo,
        Preuzet() => Colors.teal,
        Vracen() => Colors.lightGreen,
        Zavrsen() => Colors.green,
        Odbijen() => Colors.red,
        Otkazan() => Colors.grey,
        Sporan() => Colors.orange,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _boja.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.naziv,
        style: TextStyle(
          color: _boja,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}