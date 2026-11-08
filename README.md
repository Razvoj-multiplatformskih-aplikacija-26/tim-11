# Rent a Luxury

## Opšti deo

Rent a Luxury povezuje ljude koji žele da iznajme dizajnerske torbe, satove, nakit, odeću i naočare sa vlasnicima tih predmeta. Zakupac bira predmet i termin, šalje zahtev i plaća zakup uz depozit. Osoblje koristi backoffice za obradu zahteva i sporova.

### Članovi tima

| Ime i prezime | Indeks | GitHub |
| --- | --- | --- |
| Ana Nikolić | 135/24si | `AnaNikolic13524si` |
| Balša Raičević | 123/24si | `braicevic12324si` |

### Zahtevi teme

1. **Uloge.** Zakupac pretražuje katalog, šalje zahteve i upravlja svojim zakupima. U punom sistemu vlasnik oglašava predmete, a osoblje proverava autentičnost i rešava sporove. KT2 demo koristi uloge zakupca i osoblja.
2. **Stanja.** Glavni tok zakupa je zahtev → odobren → plaćen → preuzet → vraćen → završen. Zakup može biti i odbijen, otkazan ili sporan.
3. **Pravila.** Zakup traje od 1 do 14 dana, a isti predmet ne može biti zakupljen u preklapajućim terminima. Vreme do preuzimanja određuje da li je otkazivanje besplatno. Plan teme obuhvata i verifikaciju predmeta pre objavljivanja.
4. **Rad bez mreže.** Planirana funkcionalnost je zapisnik o primopredaji sa fotografijama i potvrdom obe strane, uz lokalno čuvanje do ponovnog povezivanja.
5. **Posao za osoblje.** Backoffice prikazuje zakupe i omogućava obradu zahteva i sporova. Tema predviđa i red predmeta za verifikaciju i poređenje fotografija kod spora.
6. **Javni sadržaj.** Katalog sa fotografijama, cenama, depozitom i dostupnošću može da se pregleda bez prijave.

### Struktura repozitorijuma

| Putanja | Namena |
| --- | --- |
| `apps/mobile` | Flutter aplikacija za zakupce |
| `apps/backoffice` | Flutter aplikacija za osoblje na Windowsu i u pregledaču |
| `apps/server` | Dart server na Relic-u 1.2.0 |
| `packages/domain` | Modeli, pravila, prava nad zakupom i port repozitorijuma |
| `packages/blocs` | Zajednički Bloc za učitavanje i izmene zakupa |
| `packages/api_contract` | API putanje i DTO klase |
| `packages/api_mapping` | Prevod između API ugovora i domena |
| `packages/api_client` | Zajednički HTTP klijent i repozitorijum zakupa |
| `packages/session_storage` | Port i platformsko skladište sesije |
| `packages/ui_text` | Poruke na srpskom za oba klijenta |
| `db` | Šema PostgreSQL-a, demo podaci, zaštita termina i sesije |

## KT1 — Dva klijenta nad istim domenom

U KT1 su napravljeni mobilna aplikacija, backoffice i zajednički Dart domen. Klijenti su koristili odvojene demo podatke u memoriji.

- **Mobilna aplikacija.** Katalog sa pretragom i filterima, detalj predmeta sa fotografijom, izbor termina i validacija, pregled sopstvenih zakupa i akcije nad njima.
- **Backoffice.** Tabela zakupa sa bočnim panelom, uži raspored, tastaturna navigacija i prečice, potvrda ili otkazivanje demo zakupa i simulacija greške pri učitavanju.
- **Domen i stanje.** Tipizovani identifikatori, stanja i dozvoljeni prelazi, pravila perioda i otkazivanja, port repozitorijuma i `ZakupiBloc` za učitavanje i izmene u backoffice-u.

## KT2 — Server i korisnici

Relic server i PostgreSQL dele podatke između klijenata. Ugovor i mapiranje su u zajedničkim Dart paketima, a klijenti koriste isti HTTP sloj. Server proverava domenska pravila, vlasništvo i ulogu pre izmene zakupa.

### Pokretanje iz čistog klona

Za razvoj na Windowsu potrebni su Flutter, Docker Desktop, Android emulator i Chrome. Za Windows desktop build potreban je i Visual Studio sa paketom **Desktop development with C++**, kao i Windows **Developer Mode** za Flutter dodatke.

U PowerShell-u iz korena repozitorijuma:

```powershell
Copy-Item .env.example .env
docker compose up --build -d
```

Compose pri prvom pokretanju inicijalizuje PostgreSQL sa šemom, 10 predmeta, 12 zakupa u svih devet statusa i tri demo naloga. Sačekati da server bude spreman, pa proveriti:

```powershell
curl.exe --max-time 10 -i http://127.0.0.1:8080/health
flutter pub get
```

Očekivani odgovor je `200 OK` i `Server i baza rade.` Lokalni `.env` je isključen iz Gita.

#### Android emulator

Pokrenuti emulator u Android Studio Device Manager-u. Iz korena repozitorijuma:

```powershell
flutter devices
cd apps/mobile
flutter run -d emulator-5554
```

Ako emulator ima drugi ID, koristiti ID iz `flutter devices`. Podrazumevana adresa servera u emulatoru je `http://10.0.2.2:8080`.

#### Windows backoffice

U novom terminalu iz korena repozitorijuma:

```powershell
cd apps/backoffice
flutter run -d windows
```

#### Backoffice u Chrome-u

U novom terminalu iz korena repozitorijuma:

```powershell
cd apps/backoffice
flutter run -d chrome --web-hostname=127.0.0.1 --web-port=5173
```

Obe verzije backoffice-a koriste `http://127.0.0.1:8080`. Server dozvoljava web origin `http://127.0.0.1:5173` prema `BACKOFFICE_ORIGIN` iz `.env`. Adresa API-ja može da se zada i preko `--dart-define=API_URL=...`.

### Demo nalozi

| Aplikacija | Email | Razvojna lozinka |
| --- | --- | --- |
| Mobilna | `zakupac1@demo.test` | `RentDemo2026!` |
| Mobilna | `zakupac2@demo.test` | `RentDemo2026!` |
| Backoffice | `osoblje@demo.test` | `RentDemo2026!` |

### Pravila i tokovi

- Javni katalog prikazuje predmete i zauzete periode. Mobilni korisnik se prijavljuje za slanje zahteva i pregled svojih zakupa. Osoblje vidi zakupe svih zakupaca, po pet na stranici.
- Prvi upisani zahtev zauzima termin. Početni i krajnji datum su uključeni. Server u transakciji zaključava predmet, proverava zajednička Dart pravila i upisuje zahtev. PostgreSQL ograničenje dodatno čuva pravilo od duplog upisa. Odbijeni poziv dobija `409 termin_zauzet`, a mobilna forma osvežava dostupnost.
- Osoblje odobrava ili odbija zahtev. Zakupac može da plati ili otkaže svoj zakup ako status i pravila to dozvoljavaju. Plaćanje u KT2 koristi simulirani serverski servis. Zapis prikazuje status i istoriju koju je server sačuvao.
- Promene se vide u drugom klijentu nakon osvežavanja. Zakupac ne može da se prijavi u backoffice, izvrši akciju osoblja ili otkaže tuđ zakup.
- Prijava ostaje posle ponovnog pokretanja aplikacije i osvežavanja web stranice. Odjava poništava sesiju. Trajanje novih sesija podešava `SESSION_TTL_MINUTES`. Za demo isteka postaviti `1`, ponovo pokrenuti server, prijaviti se novom sesijom i osvežiti zakupe posle isteka.

### Provere za odbranu

Komande se pokreću iz korena repozitorijuma, sa podignutom bazom:

```powershell
dart analyze apps/server packages/domain packages/blocs packages/api_contract packages/api_mapping packages/api_client packages/session_storage packages/ui_text apps/mobile/lib apps/backoffice/lib
docker compose exec -T server dart run apps/server/bin/provera_zakupa.dart

Push-Location packages/domain
dart test
Pop-Location

Push-Location apps/mobile
flutter test test/poruke_test.dart
Pop-Location
```

Za demonstraciju pokrenuti mobilnu aplikaciju i backoffice. Na telefonu poslati zahtev za slobodan termin, u backoffice-u osvežiti listu i odobriti zahtev. Na telefonu osvežiti **Moji zakupi**, platiti zakup i proveriti novi status u backoffice-u. Za proveru mrežne greške zaustaviti samo server sa `docker compose stop server`, osvežiti listu i ponovo ga pokrenuti sa `docker compose up -d server`.
