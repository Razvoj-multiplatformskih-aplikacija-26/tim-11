const putanjaPrijave = '/sesije/prijava';
const putanjaOdjave = '/sesije/odjava';
const putanjaTrenutneSesije = '/sesije/trenutna';

final class PrijavaZahtev {
  const PrijavaZahtev({
    required this.email,
    required this.lozinka,
    required this.aplikacija,
    this.cookie = false,
  });

  final String email;
  final String lozinka;
  final String aplikacija;
  final bool cookie;

  factory PrijavaZahtev.fromJson(Map<String, Object?> json) => PrijavaZahtev(
    email: json['email'] as String,
    lozinka: json['lozinka'] as String,
    aplikacija: json['aplikacija'] as String,
    cookie: json['cookie'] as bool? ?? false,
  );

  Map<String, Object?> toJson() => {
    'email': email,
    'lozinka': lozinka,
    'aplikacija': aplikacija,
    'cookie': cookie,
  };
}

final class PrijavaOdgovor {
  const PrijavaOdgovor({
    this.token,
    required this.uloga,
    required this.isticeU,
  });

  final String? token;
  final String uloga;
  final String isticeU;

  factory PrijavaOdgovor.fromJson(Map<String, Object?> json) => PrijavaOdgovor(
    token: json['token'] as String?,
    uloga: json['uloga'] as String,
    isticeU: json['isticeU'] as String,
  );

  Map<String, Object?> toJson() => {
    if (token != null) 'token': token,
    'uloga': uloga,
    'isticeU': isticeU,
  };
}