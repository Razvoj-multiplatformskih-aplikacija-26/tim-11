part of 'zakupi_bloc.dart';

sealed class ZakupiEvent{
  const ZakupiEvent();
}

final class ZatrazeniZakupi extends ZakupiEvent{
  const ZatrazeniZakupi ();
}

final class OsvezeniZakupi extends ZakupiEvent{
  OsvezeniZakupi();

  final _handled=Completer<void>();
  Future<void> get handled => _handled.future;

  void zavrsi(){
    if(!_handled.isCompleted){
      _handled.complete();
    }
  }
}

final class OtkazivanjeZakupa extends ZakupiEvent{

  final ZakupId id;
  final String razlog;

  const OtkazivanjeZakupa (this.id,{this.razlog=''});
}

final class ObavestenjePotvrdjeno extends ZakupiEvent{
  const ObavestenjePotvrdjeno();
}

final class PromenaStatusaZakupa extends ZakupiEvent {
  final ZakupId id;
  final StatusZakupa noviStatus;

  const PromenaStatusaZakupa({
    required this.id,
    required this.noviStatus,
  });

  @override
  List<Object?> get props => [id, noviStatus];
}