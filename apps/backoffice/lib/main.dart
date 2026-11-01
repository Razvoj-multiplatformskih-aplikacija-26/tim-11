import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocs/src/moji_zakupi/zakupi_bloc.dart';

import 'privremeni_zakup_repository.dart';
import 'screens/schedule_screen.dart';

void main() {
  final zakupRepository = PrivremeniZakupRepository();

  runApp(BackofficeApp(zakupRepository: zakupRepository));
}

class BackofficeApp extends StatelessWidget {
  final PrivremeniZakupRepository zakupRepository;

  const BackofficeApp({
    super.key,
    required this.zakupRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Backoffice',
      home: BlocProvider(
        create: (context) => ZakupiBloc(
          zakupRepository: zakupRepository,
        )..add(const ZatrazeniZakupi()),
        child: const ScheduleScreen(),
      ),
    );
  }
}