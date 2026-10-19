import 'package:flutter/material.dart';
import '../models/status_zakupa.dart';

/// Mala obojena oznaka sa nazivom statusa
class StatusOznaka extends StatelessWidget {
  const StatusOznaka({super.key, required this.status});

  final StatusZakupa status;

  Color get _boja => switch (status) {
        StatusZakupa.zahtev => Colors.blueGrey,
        StatusZakupa.odobren => Colors.blue,
        StatusZakupa.placen => Colors.indigo,
        StatusZakupa.preuzet => Colors.teal,
        StatusZakupa.vracen => Colors.lightGreen,
        StatusZakupa.zavrsen => Colors.green,
        StatusZakupa.odbijen => Colors.red,
        StatusZakupa.otkazan => Colors.grey,
        StatusZakupa.sporan => Colors.orange,
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