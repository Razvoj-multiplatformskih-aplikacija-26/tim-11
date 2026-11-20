# Rent a Luxury

## Opšti deo

Rent a Luxury je aplikacija za iznajmljivanje dizajnerskih torbi, satova, nakita, odeće i naočara. Zakupac pregleda katalog, bira termin, šalje zahtev i upravlja svojim zakupima. Osoblje koristi backoffice za obradu zahteva i rešavanje sporova.

### Članovi tima

| Ime i prezime | Indeks | GitHub |
| --- | --- | --- |
| Ana Nikolić | 135/24si | `AnaNikolic13524si` |
| Balša Raičević | 123/24si | `braicevic12324si` |

### Tema i obim demonstracije

Glavni tok zakupa je:

zahtev → odobren → plaćen → preuzet → vraćen → završen

Dodatna stanja su odbijen, otkazan i sporan.

KT2 demonstracija obuhvata zakupca i osoblje, javni katalog, dostupnost predmeta, slanje zahteva, odobravanje i odbijanje, simulirano plaćanje, otkazivanje i odluku o depozitu pri rešavanju spora.

Širi plan teme uključuje oglašavanje predmeta od strane vlasnika, proveru autentičnosti i zapisnik o primopredaji sa fotografijama i radom bez mreže. Ti tokovi nisu kompletno implementirani u ovoj demonstraciji.

Kataloške fotografije su lokalni resursi aplikacije. Fotografije preuzimanja i vraćanja u panelu spora trenutno su predstavljene ikonicama; slanje stvarnih fotografija na server nije implementirano.

### Struktura repozitorijuma

| Putanja | Namena |
| --- | --- |
| `apps/mobile` | Flutter aplikacija za zakupce |
| `apps/backoffice` | Flutter aplikacija za osoblje na Windowsu i u pregledaču |
| `apps/server` | Dart HTTP server sa bibliotekom Relic 1.2.0 |
| `packages/domain` | Modeli, poslovna pravila, prava i portovi repozitorijuma |
| `packages/blocs` | BLoC za pregled i izmene zakupa i BLoC za novi zahtev |
| `packages/api_contract` | DTO klase i API ugovor |
| `packages/api_mapping` | Mapiranje domena, DTO objekata i grešaka |
| `packages/api_client` | Zajednički HTTP klijent i HTTP implementacije repozitorijuma |
| `packages/session_storage` | Port i platformsko skladište sesije |
| `packages/ui_text` | Zajedničke poruke o greškama |
| `db` | PostgreSQL šema, demo podaci, zaštita termina i sesije |

### Arhitektura

Klijenti prikazuju podatke i šalju korisničke događaje BLoC-u. BLoC koristi portove repozitorijuma, a HTTP implementacije pozivaju server preko zajedničkog API klijenta.

Server proverava prijavu, ulogu, pripadnost zakupa korisniku i domenska pravila. Upisuje podatke u PostgreSQL unutar transakcije.

Paket `domain` ne zavisi od Fluttera, HTTP-a ni PostgreSQL-a. Klijenti koriste njegova pravila za povratnu informaciju korisniku, a server ih ponovo proverava pre upisa.

## KT1 — Dva klijenta nad istim domenom

Za ocenjivanje KT1 relevantan je commit koji je stigao na GitHub do 4. novembra u 23:59:59. Trenutna grana `main` sadrži i kasnije KT2 izmene i nije zamena za istorijsko KT1 stanje.

KT1 verzija koristi demo podatke u memoriji, bez zajedničkog servera i baze.

Obuhvata:

- Mobilni katalog sa pretragom i filterima.
- Detalj predmeta sa fotografijom, cenom i depozitom.
- Izbor perioda i proveru pravila zakupa.
- Pregled zakupa i akcije dostupne u toj verziji.
- Backoffice tabelu i prikaz detalja izabranog zakupa.
- Tastaturnu navigaciju, prečice i simulaciju greške.
- Zajednički Dart domen sa tipizovanim identifikatorima, statusima, prelazima i pravilima.
- `ZakupiBloc` u backoffice-u.

### Priprema KT1 za odbranu

KT1 treba pripremiti u posebnom klonu, na potvrđenom commitu sa roka. Time se čuva trenutno KT2 radno okruženje.

U tom klonu:

```powershell
git checkout <KT1_COMMIT_SA_ROKA>
flutter pub get
```

Mobilna aplikacija se pokreće iz `apps/mobile`, a backoffice iz `apps/backoffice`, prema platformama dostupnim u tom commitu.

Funkcionalnosti dodate nakon KT1 roka ne prikazuju se kao deo KT1 predaje.

## KT2 — Server i korisnici

KT2 povezuje mobilnu aplikaciju, Windows backoffice i web backoffice sa zajedničkim Dart serverom i PostgreSQL bazom.

### Potrebni alati

- Flutter sa Dart SDK-om koji podržava ograničenja iz `pubspec.yaml`.
- Docker Desktop pokrenut sa Linux kontejnerima.
- Android Studio i pokrenut Android emulator za mobilnu aplikaciju.
- Chrome za web backoffice.
- Visual Studio sa paketom **Desktop development with C++** za Windows backoffice.
- Uključen Windows **Developer Mode** za Flutter dodatke koji zahtevaju simboličke linkove.

### Pokretanje iz čistog klona

Klonirati repozitorijum i otvoriti njegov korenski direktorijum, u kome se nalazi `compose.yaml`.

Sledeće komande pokreću se iz tog direktorijuma:

```powershell
git switch main
git pull --ff-only origin main
Copy-Item .env.example .env
docker compose up --build -d
```

Komanda `Copy-Item` namenjena je novom klonu. U postojećem radnom direktorijumu ne treba njome prepisivati sopstvena podešavanja.

Pri prvom pokretanju Compose inicijalizuje praznu bazu sa:

- Šemom i ograničenjima.
- Deset predmeta.
- Dvanaest demo zakupa u svih devet statusa.
- Dva naloga zakupaca i jednim nalogom osoblja.
- Tabelom sesija.

Inicijalizacione SQL skripte izvršavaju se samo pri kreiranju praznog PostgreSQL volumena. Ponovno pokretanje zadržava postojeće podatke.

Sačekati da server bude spreman:

```powershell
curl.exe --retry 10 --retry-delay 2 --retry-all-errors --max-time 10 -i http://127.0.0.1:8080/health
```

Očekivani odgovor:

```text
HTTP/1.1 200 OK

Server i baza rade.
```

Zatim preuzeti Flutter zavisnosti:

```powershell
flutter pub get
```

Ako server nije dostupan:

```powershell
docker compose ps
docker compose logs --tail=80 server
```

### Lokalna konfiguracija

Lokalni `.env` nije u Gitu. Primer konfiguracije je u `.env.example`.

| Promenljiva | Namena |
| --- | --- |
| `POSTGRES_DB` | Naziv baze |
| `POSTGRES_USER` | Korisnik baze |
| `POSTGRES_PASSWORD` | Lozinka baze |
| `SESSION_TTL_MINUTES` | Trajanje novih sesija; podrazumevano 480 minuta |
| `BACKOFFICE_ORIGIN` | Dozvoljeni web origin, podrazumevano `http://127.0.0.1:5173` |
| `JWT_SECRET` | Tajni ključ za potpisivanje JWT-a |
| `COOKIE_SECURE` | `false` za lokalni HTTP; `true` za HTTPS okruženje |

Vrednosti lozinki i JWT ključa u `.env.example` namenjene su lokalnoj demonstraciji. Za drugo okruženje postavljaju se sopstvene vrednosti.

Posle izmene serverske konfiguracije:

```powershell
docker compose up -d --force-recreate server
```

### Mobilna aplikacija — Android

Pokrenuti emulator kroz Android Studio Device Manager.

U novom terminalu, iz korena repozitorijuma:

```powershell
flutter devices
Push-Location apps/mobile
flutter run -d emulator-5554
Pop-Location
```

Ako emulator ima drugi ID, koristiti ID iz `flutter devices`.

Podrazumevana adresa servera za Android emulator je `http://10.0.2.2:8080`.

### Backoffice — Windows

U novom terminalu, iz korena repozitorijuma:

```powershell
Push-Location apps/backoffice
flutter run -d windows
Pop-Location
```

### Backoffice — Chrome

U novom terminalu, iz korena repozitorijuma:

```powershell
Push-Location apps/backoffice
flutter run -d chrome --web-hostname=127.0.0.1 --web-port=5173
Pop-Location
```

Windows i Chrome backoffice podrazumevano koriste API na `http://127.0.0.1:8080`.

Za web koristiti tačno `http://127.0.0.1:5173`, u skladu sa `BACKOFFICE_ORIGIN`.

Ako je port 5173 zauzet prethodnim `flutter run` procesom, prvo zaustaviti taj proces tasterom `q` u njegovom terminalu.

Druga API adresa može da se prosledi pri pokretanju:

```text
--dart-define=API_URL=http://ADRESA_SERVERA:8080
```

### Demo nalozi

| Uloga | Aplikacija | Email | Lozinka |
| --- | --- | --- | --- |
| Zakupac 1 | Mobilna | `zakupac1@demo.test` | `RentDemo2026!` |
| Zakupac 2 | Mobilna | `zakupac2@demo.test` | `RentDemo2026!` |
| Osoblje | Backoffice | `osoblje@demo.test` | `RentDemo2026!` |

Javni katalog može da se pregleda bez prijave.

### Prijava i sesije

Server izdaje JWT potpisan algoritmom HS256. Proverava potpis, rok važenja i aktivnu sesiju u bazi.

U bazi se čuva SHA-256 heš tokena. To omogućava da odjava odmah poništi sesiju, čak i ako JWT još nije istekao.

Prenos i čuvanje sesije zavise od platforme:

- **Chrome:** JWT se prenosi kroz HttpOnly kolačić sa `SameSite=Lax`. Aplikacioni JavaScript ne čita JWT i ne čuva ga u lokalnom skladištu. HTTP klijent šalje zahteve sa kredencijalima.
- **Android i Windows:** JWT se šalje kroz `Authorization: Bearer ...` i čuva preko paketa `flutter_secure_storage`.
- **Obnova sesije:** prijava može da se obnovi posle ponovnog pokretanja aplikacije ili osvežavanja web stranice.
- **Odjava:** server poništava sesiju, a klijent uklanja lokalno sačuvane podatke ili serverski kolačić.
- **Istek:** zaštićeni zahtev dobija `401`, a korisnik se vraća na prijavu.

CORS dozvoljava podešeni backoffice origin i slanje kredencijala.

### Poslovna pravila

- Zakup traje od 1 do 14 dana.
- Početni i krajnji datum uključeni su u period zakupa.
- Statusi zahtev, odobren, plaćen i preuzet zauzimaju termin.
- Prvi uspešno upisani zahtev rezerviše period.
- Server u transakciji zaključava red predmeta, proverava domensko pravilo i upisuje zakup.
- PostgreSQL ograničenje `zakupi_bez_preklapanja` dodatno sprečava preklapanje aktivnih zakupa.
- Pri dva paralelna zahteva za isti period uspeva jedan; drugi dobija `409 termin_zauzet`.
- Zakupac vidi i menja samo svoje zakupe.
- Osoblje vidi sve zakupe i može da odobri ili odbije zahtev.
- Odbijanje zahteva obavezan razlog.
- Zakupac može da plati odobren zakup ili otkaže svoj zakup kada pravila to dozvoljavaju.
- Otkazivanje je besplatno ako do preuzimanja ima najmanje dva dana.
- Plaćanje koristi simulirani serverski servis; stvarna naplata nije povezana.
- Pri rešavanju spora osoblje bira vraćanje ili naplatu depozita. Odluka se čuva uz završeni status i prikazuje u oba klijenta.
- Ranije završeni zakupi bez zabeležene odluke nemaju prikaz odluke o depozitu.

### Prikaz i osvežavanje

- Mobilna forma koristi BLoC za dostupnost, izbor perioda i slanje zahteva.
- Backoffice koristi serversku paginaciju sa pet zakupa po stranici.
- Oznaka zakupa u backoffice-u prikazuje zakupca i predmet, dok tehnički ID ostaje identifikator zapisa.
- Široki prozor prikazuje tabelu i detalj sa strane.
- Uži prozor prikazuje listu i detalj ispod nje.
- Promene se vide u drugom klijentu nakon osvežavanja; automatsko obaveštavanje u realnom vremenu nije uvedeno.
- Status i istorija preuzimaju se sa servera.

Tastaturne prečice u backoffice-u:

| Taster | Akcija |
| --- | --- |
| Strelice gore/dole | Izbor zakupa |
| Enter | Odobravanje zahteva kada je dozvoljeno |
| Delete / Backspace | Odbijanje zahteva uz unos razloga |

### Automatske provere

Iz korena repozitorijuma:

```powershell
dart analyze apps packages
```

Domenski testovi:

```powershell
Push-Location packages/domain
dart test
Pop-Location
```

Testovi mobilne aplikacije:

```powershell
Push-Location apps/mobile
flutter test
Pop-Location
```

Testovi backoffice-a:

```powershell
Push-Location apps/backoffice
flutter test
Pop-Location
```

Integraciona provera uz pokrenutu bazu:

```powershell
docker compose exec -T server dart run apps/server/bin/provera_zakupa.dart
```

Integraciona skripta proverava razdvajanje zakupa demo korisnika, odbijanje predugog perioda, paralelne zahteve za isti termin i broj upisanih probnih zakupa. Kreira poseban probni predmet i uklanja svoje probne podatke po završetku.

### Ručna provera za odbranu

1. Otvoriti javni katalog i detalj predmeta.
2. Prijaviti zakupca 1 i poslati zahtev za slobodan period.
3. U backoffice-u osvežiti listu i odobriti zahtev.
4. Na telefonu osvežiti zakupe i platiti odobren zakup.
5. U backoffice-u proveriti status plaćen nakon osvežavanja.
6. Pokušati novi zahtev za zauzet period i proveriti poruku.
7. Prijaviti zakupca 2 i proveriti da nema pristup zakupima zakupca 1.
8. Proveriti odbijanje zahteva uz razlog i otkazivanje sopstvenog zakupa.
9. Proveriti prethodnu i sledeću stranicu backoffice-a.
10. Promeniti širinu prozora i proveriti listu, statuse i detalj.
11. Ponovo pokrenuti aplikacije i proveriti obnovu sesije.
12. Odjaviti se i proveriti da naredno pokretanje traži prijavu.
13. U Chrome DevTools proveriti HttpOnly kolačić i njegovo uklanjanje pri odjavi.
14. Na raspoloživom spornom demo zakupu proveriti odluku o depozitu i njen prikaz posle osvežavanja.

Za demonstraciju isteka sesije privremeno postaviti `SESSION_TTL_MINUTES=1`, ponovo kreirati server i prijaviti se novom sesijom. Nakon isteka osvežiti zakupe i proveriti zahtev za ponovnom prijavom. Posle provere vratiti vrednost na `480` i ponovo kreirati server.

Za demonstraciju mrežne greške:

```powershell
docker compose stop server
```

Osvežiti podatke u aplikaciji i proveriti poruku o nedostupnom serveru. Zatim ponovo pokrenuti server:

```powershell
docker compose up -d server
```

Sačekati uspešan `/health`, pa ponoviti učitavanje.

### Zaustavljanje

Zaustavljanje kontejnera uz zadržavanje podataka:

```powershell
docker compose stop
```

Ponovno pokretanje:

```powershell
docker compose up -d
```