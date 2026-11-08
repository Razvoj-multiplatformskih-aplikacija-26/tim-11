enum Uloga { zakupac, osoblje }

enum AkcijaZakupa { otkazi, plati, odobri, odbij, resiSpor }

bool imaPravoNaAkciju({
  required Uloga uloga,
  required AkcijaZakupa akcija,
  required bool jeSvojZakup,
}) => switch (akcija) {
  AkcijaZakupa.otkazi ||
  AkcijaZakupa.plati => uloga == Uloga.zakupac && jeSvojZakup,
  AkcijaZakupa.odobri ||
  AkcijaZakupa.odbij ||
  AkcijaZakupa.resiSpor => uloga == Uloga.osoblje,
};
