import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/zakupi_store.dart';
import '../widgets/zakup_kartica.dart';

class MojiZakupiScreen extends StatelessWidget {
  const MojiZakupiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moji zakupi')),
      // ListenableBuilder ponovo iscrta listu kad god se zakupi promene
      body: ListenableBuilder(
        listenable: zakupiStore,
        builder: (context, _) {
          final zakupi = [...zakupiStore.zakupi]
            ..sort((a, b) => b.datumOd.compareTo(a.datumOd));

          if (zakupi.isEmpty) {
            return const Center(child: Text('Još nemaš nijedan zakup.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: zakupi.length,
                        itemBuilder: (context, i) => ZakupKartica(
              zakup: zakupi[i],
              onTap: () => context.push('/zakupi/${zakupi[i].id}'),
            ),
          );
        },
      ),
    );
  }
}