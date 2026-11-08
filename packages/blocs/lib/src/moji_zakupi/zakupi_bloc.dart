import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'zakupi_event.dart';
part 'zakupi_state.dart';

final class ZakupiBloc extends Bloc<ZakupiEvent, ZakupiState> {
  ZakupiBloc({required this.zakupRepository})
    : super(const ZakupiUcitavanje()) {
    on<ZatrazeniZakupi>((event, emit) async {
      emit(const ZakupiUcitavanje());
      await _ucitajZakupe(emit);
    });

    on<IzabranaStranicaZakupa>((event, emit) async {
      final repo = zakupRepository;
      if (state is ZakupiUcitavanje ||
          repo is! StranicniZakupRepository ||
          !repo.izaberiStranicu(event.broj)) {
        return;
      }

      emit(const ZakupiUcitavanje());
      await _ucitajZakupe(emit);
    });

    on<OsvezeniZakupi>((event, emit) async {
      try {
        await _ucitajZakupe(emit);
      } finally {
        event.zavrsi();
      }
    });

    on<ObavestenjePotvrdjeno>((event, emit) {
      final trenutno = state;
      if (trenutno is ZakupiUcitani && trenutno.obavestenje != null) {
        emit(
          ZakupiUcitani(
            zakupi: trenutno.zakupi,
            otkazivanje: trenutno.otkazivanje,
          ),
        );
      }
    });

    on<OtkazivanjeZakupa>((event, emit) async {
      final trenutno = state;
      if (trenutno is! ZakupiUcitani || trenutno.otkazivanje != null) {
        return;
      }

      emit(ZakupiUcitani(zakupi: trenutno.zakupi, otkazivanje: event.id));

      final rezultat = await zakupRepository.otkaziZakup(event.id);
      final lista = switch (state) {
        ZakupiUcitani(:final zakupi) => zakupi,
        _ => trenutno.zakupi,
      };

      switch (rezultat) {
        case Uspeh(:final vrednost):
          emit(
            ZakupiUcitani(
              zakupi: _zameniZakup(lista, vrednost),
              obavestenje: ZakupOtkazan(vrednost),
            ),
          );
        case Neuspeh(:final greska):
          emit(
            ZakupiUcitani(
              zakupi: lista,
              obavestenje: OtkazivanjeOdbijeno(greska),
            ),
          );
          await _ucitajZakupe(emit);
      }
    });

    on<PromenaStatusaZakupa>((event, emit) async {
      final trenutno = state;
      if (trenutno is! ZakupiUcitani) return;

      final rezultat = await zakupRepository.promeniStatusZakupa(
        id: event.id,
        noviZakup: event.noviStatus,
      );

      final stanjePoslePoziva = state;
      final lista = switch (stanjePoslePoziva) {
        ZakupiUcitani(:final zakupi) => zakupi,
        _ => trenutno.zakupi,
      };

      switch (rezultat) {
        case Uspeh(:final vrednost):
          emit(
            ZakupiUcitani(
              zakupi: _zameniZakup(lista, vrednost),
              otkazivanje: stanjePoslePoziva is ZakupiUcitani
                  ? stanjePoslePoziva.otkazivanje
                  : null,
              obavestenje: vrednost.status is Odobren
                  ? ZakupOdobren(vrednost)
                  : null,
            ),
          );
        case Neuspeh(:final greska):
          emit(
            ZakupiUcitani(
              zakupi: lista,
              obavestenje: PromenaZakupaOdbijena(greska),
            ),
          );
          await _ucitajZakupe(emit);
      }
    });
  }

  final ZakupRepository zakupRepository;

  int get stranica => switch (zakupRepository) {
    StranicniZakupRepository(:final stranica) => stranica,
    _ => 0,
  };

  bool get imaSledecuStranicu => switch (zakupRepository) {
    StranicniZakupRepository(:final imaSledecuStranicu) => imaSledecuStranicu,
    _ => false,
  };

  Future<void> _ucitajZakupe(Emitter<ZakupiState> emit) async {
    final rezultat = await zakupRepository.preuzmiSveZakupe();

    switch (rezultat) {
      case Uspeh(:final vrednost):
        if (vrednost.isEmpty) {
          emit(const ZakupiPrazno());
        } else {
          emit(ZakupiUcitani(zakupi: vrednost));
        }
      case Neuspeh(:final greska):
        emit(ZakupiGreska(greska));
    }
  }

  List<Zakup> _zameniZakup(List<Zakup> zakupi, Zakup azuriran) => [
    for (final zakup in zakupi)
      if (zakup.id == azuriran.id) azuriran else zakup,
  ];
}
