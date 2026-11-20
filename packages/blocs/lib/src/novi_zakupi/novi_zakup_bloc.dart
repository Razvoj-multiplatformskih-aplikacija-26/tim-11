import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

sealed class NoviZakupDogadjaj {
  const NoviZakupDogadjaj();
}

final class DostupnostZatrazena extends NoviZakupDogadjaj {
  const DostupnostZatrazena();
}

final class PeriodZakupaIzabran extends NoviZakupDogadjaj {
  const PeriodZakupaIzabran({required this.od, required this.doDatuma});

  final DateTime od;
  final DateTime doDatuma;
}

final class SlanjeZakupaZatrazeno extends NoviZakupDogadjaj {
  const SlanjeZakupaZatrazeno();
}

final class NoviZakupStanje extends Equatable {
  const NoviZakupStanje({
    this.ucitavanje = true,
    this.slanje = false,
    this.periodi = const [],
    this.od,
    this.doDatuma,
    this.provera,
    this.greska,
    this.poslatId,
  });

  final bool ucitavanje;
  final bool slanje;
  final List<PeriodZakupa> periodi;
  final DateTime? od;
  final DateTime? doDatuma;
  final Rezultat<PeriodZakupa>? provera;
  final DomenskaGreska? greska;
  final ZakupId? poslatId;

  NoviZakupStanje copyWith({
    bool? ucitavanje,
    bool? slanje,
    List<PeriodZakupa>? periodi,
    DateTime? od,
    DateTime? doDatuma,
    Rezultat<PeriodZakupa>? provera,
    DomenskaGreska? greska,
    ZakupId? poslatId,
  }) => NoviZakupStanje(
    ucitavanje: ucitavanje ?? this.ucitavanje,
    slanje: slanje ?? this.slanje,
    periodi: periodi ?? this.periodi,
    od: od ?? this.od,
    doDatuma: doDatuma ?? this.doDatuma,
    provera: provera ?? this.provera,
    greska: greska,
    poslatId: poslatId ?? this.poslatId,
  );

  @override
  List<Object?> get props => [
    ucitavanje,
    slanje,
    periodi,
    od,
    doDatuma,
    provera,
    greska,
    poslatId,
  ];
}

final class NoviZakupBloc extends Bloc<NoviZakupDogadjaj, NoviZakupStanje> {
  NoviZakupBloc({
    required this.repository,
    required this.predmet,
    this.sada = DateTime.now,
  }) : super(const NoviZakupStanje()) {
    on<DostupnostZatrazena>((event, emit) async {
      if (state.ucitavanje && _ucitavanjePokrenuto) return;
      if (state.slanje || state.poslatId != null) return;

      await _ucitaj(emit);
    });

    on<PeriodZakupaIzabran>((event, emit) {
      if (state.slanje || state.poslatId != null) return;

      emit(
        state.copyWith(
          od: event.od,
          doDatuma: event.doDatuma,
          provera: _proveri(event.od, event.doDatuma, state.periodi),
        ),
      );
    });

    on<SlanjeZakupaZatrazeno>((event, emit) async {
      if (state.slanje || state.ucitavanje || state.poslatId != null) {
        return;
      }

      final od = state.od;
      final doDatuma = state.doDatuma;

      if (od == null || doDatuma == null) return;

      final provera = _proveri(od, doDatuma, state.periodi);
      final period = provera.vrednostIliNull;

      if (period == null) {
        emit(state.copyWith(provera: provera));
        return;
      }

      emit(state.copyWith(slanje: true, provera: provera));

      final rezultat = await repository.posaljiZahtev(
        predmetId: predmet.id,
        period: period,
      );

      switch (rezultat) {
        case Uspeh(:final vrednost):
          emit(state.copyWith(slanje: false, poslatId: vrednost));

        case Neuspeh(:final greska):
          emit(state.copyWith(slanje: false, greska: greska));

          if (greska is TerminZauzet) {
            await _ucitaj(emit, razlogOdbijanja: greska);
          }
      }
    });
  }

  final NoviZakupRepository repository;
  final Predmet predmet;
  final DateTime Function() sada;

  bool _ucitavanjePokrenuto = false;

  Rezultat<PeriodZakupa> _proveri(
    DateTime od,
    DateTime doDatuma,
    List<PeriodZakupa> zauzeti,
  ) {
    final rezultat = proveriZahtev(
      predmet: predmet,
      od: od,
      doDatuma: doDatuma,
      danas: sada(),
      postojeciZakupi: const [],
    );

    final period = rezultat.vrednostIliNull;

    return period == null ? rezultat : proveriSlobodanPeriod(period, zauzeti);
  }

  Future<void> _ucitaj(
    Emitter<NoviZakupStanje> emit, {
    DomenskaGreska? razlogOdbijanja,
  }) async {
    _ucitavanjePokrenuto = true;

    emit(state.copyWith(ucitavanje: true, greska: razlogOdbijanja));

    final rezultat = await repository.preuzmiZauzetePeriode(predmet.id);

    switch (rezultat) {
      case Uspeh(:final vrednost):
        final periodi = List<PeriodZakupa>.unmodifiable(vrednost);
        final od = state.od;
        final doDatuma = state.doDatuma;

        emit(
          state.copyWith(
            ucitavanje: false,
            periodi: periodi,
            provera: od != null && doDatuma != null
                ? _proveri(od, doDatuma, periodi)
                : null,
            greska: razlogOdbijanja,
          ),
        );

      case Neuspeh(:final greska):
        emit(
          state.copyWith(ucitavanje: false, greska: razlogOdbijanja ?? greska),
        );
    }
  }
}
