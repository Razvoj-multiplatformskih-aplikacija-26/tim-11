part of 'zakupi_bloc.dart';

sealed class ZakupiState extends Equatable {
  const ZakupiState();

  @override
  List<Object?> get props => [];
}

sealed class ZakupiObavestenje extends Equatable {
  const ZakupiObavestenje();

  @override
  List<Object?> get props => [];
}

final class ZakupiUcitavanje extends ZakupiState {
  const ZakupiUcitavanje();
}

final class ZakupiPrazno extends ZakupiState {
  const ZakupiPrazno();
}

final class ZakupiGreska extends ZakupiState {
  final Object greska;

  const ZakupiGreska(this.greska);

  @override
  List<Object?> get props => [greska];
}

final class ZakupiUcitani extends ZakupiState {
  final List<Zakup> zakupi;
  final ZakupId? otkazivanje;
  final ZakupiObavestenje? obavestenje;

  const ZakupiUcitani({
    required this.zakupi,
    this.otkazivanje,
    this.obavestenje,
  });

  ZakupiUcitani copyWith({
    List<Zakup>? zakupi,
    ZakupId? otkazivanje,
    ZakupiObavestenje? obavestenje,
  }) {
    return ZakupiUcitani(
      zakupi: zakupi ?? this.zakupi,
      otkazivanje: otkazivanje ?? this.otkazivanje,
      obavestenje: obavestenje,
    );
  }

  @override
  List<Object?> get props => [zakupi, otkazivanje, obavestenje];
}

final class ZakupOtkazan extends ZakupiObavestenje {
  final Zakup zakup;

  const ZakupOtkazan(this.zakup);

  @override
  List<Object?> get props => [zakup];
}

final class OtkazivanjeOdbijeno extends ZakupiObavestenje {
  final Object greska;

  const OtkazivanjeOdbijeno(this.greska);

  @override
  List<Object?> get props => [greska];
}

final class ZakupOdobren extends ZakupiObavestenje {
  final Zakup zakup;

  const ZakupOdobren(this.zakup);

  @override
  List<Object?> get props => [zakup];
}

final class PromenaZakupaOdbijena extends ZakupiObavestenje {
  const PromenaZakupaOdbijena(this.greska);

  final DomenskaGreska greska;

  @override
  List<Object?> get props => [greska];
}
