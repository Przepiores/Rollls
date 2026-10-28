# Rollls

Aplikacja mobilna **Ice Rolls** (lody tajskie rolowane i gofry, Kuźnicza 10, Wrocław), napisana we Flutterze na Androida, iOS i przeglądarkę.

## Co jest w prototypie

- **Start:** powitanie, status „Otwarte do…”, promocje, skrót do karty pieczątek, nowości.
- **Menu:** kategorie w kolorach rolek z logo, rozwijane kafelki ze zdjęciem, opisem i ceną, etykiety „Nowość” i „Bestseller”.
- **Pieczątki:** karta 10 pieczątek (10. lód gratis), osobisty kod QR do zeskanowania przy ladzie, logowanie Google / Apple / link e-mail.
- **Więcej:** adres z nawigacją, godziny otwarcia, Instagram i Facebook, język PL/EN, motyw jasny/ciemny, zgoda marketingowa.
- **Panel sklepu** (po zalogowaniu): nabijanie pieczątek i wydawanie nagrody. Edycja menu, promocji, push, godzin i statystyki są na razie tylko podglądem.

Prototyp działa na danych w pamięci. Menu, ceny i promocje są prawdziwe (lib/data/menu_data.dart, lib/data/shop_data.dart). Logowanie jest symulowane, każde konto ma dostęp do panelu sklepu. Kolejny etap to podłączenie Firebase (Auth, Firestore, Cloud Functions, Cloud Messaging).

## Uruchomienie

Wymaga Fluttera 3.47 lub nowszego.

```bash
flutter pub get
flutter run -d chrome     # w przeglądarce
flutter run               # na podłączonym telefonie lub emulatorze
flutter test              # testy
```

## Struktura

```
lib/
  app.dart              router i motyw
  theme.dart            kolory marki (6 rolek z logo), czcionki Fredoka i Nunito
  state.dart            stan: język, motyw, sesja, karta pieczątek
  data/                 modele, menu, dane sklepu, logika godzin otwarcia
  screens/              ekrany: start, menu, pieczątki, więcej, panel sklepu
  widgets/              szachownica, spiralka-pieczątka, karta pieczątek
  l10n/                 tłumaczenia PL i EN (pliki .arb)
```
