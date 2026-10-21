# Rent a Luxury

## Članovi tima
Ana Nikolić - 135/24si - AnaNikolic13524si
Balša Raičević - 123/24si - braicevic12324si

## Opis sistema

Rent a Luxury je platforma za iznajmljivanje skupih i prestižnih predmeta između korisnika: dizajnerskih torbi, satova, nakita, odeće i naočara.
Mnogi žele da za venčanje, maturu ili poslovni događaj nose originalnu dizajnersku torbu ili sat, ali ne mogu ili ne žele da ih kupe. Sa druge strane, vlasnici takvih predmeta ih većinu vremena ne koriste. Rent a Luxury ih povezuje: vlasnik oglašava predmet i zarađuje od zakupa, a zakupac ga koristi nekoliko dana za deo cene, uz depozit kao garanciju.
Poverenje je ključno, jer se radi o predmetima velike vrednosti. Zato osoblje platforme pre objave proverava autentičnost svakog predmeta. Pri preuzimanju i vraćanju obe strane prave zapisnik sa fotografijama stanja predmeta, a ako dođe do oštećenja, osoblje rešava spor i odlučuje o depozitu.

## Zahtevi
### 1. Uloge
Zakupac pretražuje predmete, šalje zahteve i plaća zakup, a vlasnik oglašava predmete i odobrava ili odbija zahteve. 
Osoblje verifikuje autentičnost predmeta, rešava sporove i odlučuje o depozitu, pa svaka uloga ima različita ovlašćenja nad istim zakupom.

### 2. Stanja
Zakup prolazi kroz stanja
**zahtev → odobren → plaćen → preuzet → vraćen → završen**, uz sporedna stanja **odbijen**, **otkazan** i **sporan**. I predmet ima sopstvena stanja: na proveri, aktivan, pauziran i povučen.

### 3. Pravila
Isti predmet ne može biti iznajmljen u preklapajućim terminima, pa kad dva zakupca istovremeno traže iste datume, server odlučuje ko dobija termin. Pored toga, zakup traje od 1 do 14 dana, besplatno otkazivanje je moguće najkasnije 48h pre preuzimanja, a predmet se ne pojavljuje u katalogu dok ga osoblje ne verifikuje.

### 4. Rad bez mreže
Zapisnik o primopredaji, sa fotografijama stanja predmeta i potvrdom obe strane, pravi se u mobilnoj aplikaciji i bez signala, na primer u garaži ili podzemnom prolazu. Zapisnik se čuva lokalno i šalje serveru čim se mreža vrati.

### 5. Posao za osoblje
Osoblje u backoffice-u pregleda red predmeta koji čekaju verifikaciju i listu otvorenih sporova, gde upoređuje fotografije sa preuzimanja i vraćanja. Za taj rad sa većim brojem zapisa i fotografija potreban je veći ekran.

### 6. Javni sadržaj
Katalog predmeta sa fotografijama, cenom po danu, depozitom i kalendarom dostupnosti vidljiv je bez prijave. Ima smisla za pretraživače, jer ljudi traže upravo ovakve upite, na primer „iznajmljivanje Dior torbe Beograd“.
