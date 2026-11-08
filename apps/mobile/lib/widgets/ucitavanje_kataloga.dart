import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/katalog_repository.dart';

class UcitavanjeKataloga extends StatefulWidget {
  const UcitavanjeKataloga({super.key, required this.builder});

  final Widget Function(BuildContext, List<Predmet>) builder;

  @override
  State<UcitavanjeKataloga> createState() => _UcitavanjeKatalogaState();
}

class _UcitavanjeKatalogaState extends State<UcitavanjeKataloga> {
  late Future<List<Predmet>> _ucitavanje;

  @override
  void initState() {
    super.initState();
    _ucitavanje = context.read<KatalogRepository>().preuzmiPredmete();
  }

  void _pokusajPonovo() {
    setState(() {
      _ucitavanje = context.read<KatalogRepository>().preuzmiPredmete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Predmet>>(
      future: _ucitavanje,
      builder: (context, stanje) {
        if (stanje.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Katalog')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final predmeti = stanje.data;
        if (predmeti == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Katalog')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Katalog trenutno nije dostupan.'),
                  TextButton(
                    onPressed: _pokusajPonovo,
                    child: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            ),
          );
        }

        return widget.builder(context, predmeti);
      },
    );
  }
}
