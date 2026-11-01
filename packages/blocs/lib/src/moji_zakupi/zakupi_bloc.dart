import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:domain/domain.dart';
import 'package:bloc/bloc.dart';

part 'zakupi_event.dart';
part 'zakupi_state.dart';

final class ZakupiBloc extends Bloc<ZakupiEvent, ZakupiState>{
  ZakupiBloc({
    required ZakupRepository zakupRepository,
  }) : _zakupRepository = zakupRepository,
      super(const ZakupiUcitavanje()) {

    on<ZatrazeniZakupi>((event, emit) async {
      emit(const ZakupiUcitavanje());
      await _ucitajZakupe(emit);
    });

    on<ObavestenjePotvrdjeno>((event,emit) {
      final current=state;
      if(current is ZakupiUcitani && current.obavestenje!=null){
        emit(current.copyWith(obavestenje: null));
      }
    });

    on<OsvezeniZakupi>((event,emit) async{
      await _ucitajZakupe(emit);
      event.zavrsi();
    });

    on<OtkazivanjeZakupa>((event, emit) async {
      final current = state;
      if (current is! ZakupiUcitani) return;

      emit(current.copyWith(otkazivanje: event.id));

      final res = await _zakupRepository.otkaziZakup(event.id);

      switch (res) {
        case Uspeh(:final vrednost):
          final otkazan = current.zakupi.firstWhere(
                (z) => z.id == event.id,
            orElse: () => vrednost,
          );


          final novaLista = current.zakupi.map((z) {
            if (z.id == event.id) {
              return Zakup(
                id: z.id,
                predmet: z.predmet,
                period: z.period,
                istorija: z.istorija,
                ///TREBA UBACITI PROVERU DA LI JE BESPLATNO OTKAZIVANJE
                status:  Otkazan(otkazanoU: DateTime.now(), besplatno: true),
              );
            }
            return z;
          }).toList();

          emit(current.copyWith(
            zakupi: novaLista,
            otkazivanje: null,
            obavestenje: ZakupOtkazan(otkazan),
          ));

        case Neuspeh(:final greska):
          emit(current.copyWith(
            otkazivanje: null,
            obavestenje: OtkazivanjeOdbijeno(greska),
          ));
      }
    });

    on<PromenaStatusaZakupa>((event, emit) async {

      final current = state;
      if (current is! ZakupiUcitani) return;

      final res = await _zakupRepository.promeniStatusZakupa(
        id: event.id,
        noviZakup: event.noviStatus,
      );

      switch (res) {
        case Uspeh():
          Zakup? odobrenZakup;
          final novaLista = current.zakupi.map((z) {
            if (z.id == event.id) {
              final azuriran = z.saStatusom(event.noviStatus);

              if (event.noviStatus is Odobren) {
                odobrenZakup = azuriran;
              }

              return z.saStatusom(event.noviStatus);
            }
            return z;
          }).toList();



          emit(current.copyWith(zakupi: novaLista,
              obavestenje: odobrenZakup != null ? ZakupOdobren(odobrenZakup!) : null ));

        case Neuspeh():
          break;
      }
    });

  }
  final ZakupRepository _zakupRepository;

  Future<void> _ucitajZakupe(Emitter<ZakupiState> emit) async {
    final res =await _zakupRepository.preuzmiSveZakupe();

    switch(res){
      case Uspeh(:final vrednost):
        if(vrednost.isEmpty){
          emit(const ZakupiPrazno());
          return;
        }
        emit(ZakupiUcitani(zakupi: vrednost));
      case Neuspeh(:final greska):
        emit(ZakupiGreska(greska));
    }
  }
}