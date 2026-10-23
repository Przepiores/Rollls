// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get tabHome => 'Start';

  @override
  String get tabMenu => 'Menu';

  @override
  String get tabStamps => 'Pieczątki';

  @override
  String get tabMore => 'Więcej';

  @override
  String greeting(String name) {
    return 'Cześć$name!';
  }

  @override
  String get tagline => 'Happy calories don\'t count';

  @override
  String openUntil(String time) {
    return 'Otwarte do $time';
  }

  @override
  String closedOpensAt(String day, String time) {
    return 'Zamknięte · otwieramy $day o $time';
  }

  @override
  String get today => 'dziś';

  @override
  String get tomorrow => 'jutro';

  @override
  String get promotions => 'Promocje';

  @override
  String get news => 'Nowości';

  @override
  String get seeMenu => 'Zobacz menu';

  @override
  String get yourCard => 'Twoja karta';

  @override
  String stampsProgress(int count, int total) {
    return '$count z $total pieczątek';
  }

  @override
  String stampsToReward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jeszcze $count pieczątki do darmowego loda',
      many: 'Jeszcze $count pieczątek do darmowego loda',
      few: 'Jeszcze $count pieczątki do darmowego loda',
      one: 'Jeszcze 1 pieczątka do darmowego loda',
    );
    return '$_temp0';
  }

  @override
  String get rewardReady => 'Darmowy lód czeka na Ciebie!';

  @override
  String get rewardHint => 'Pokaż kod przy ladzie, a obsługa wyda nagrodę.';

  @override
  String get showCode => 'Pokaż ten kod przy ladzie po zakupie';

  @override
  String get loginForStamps => 'Zaloguj się, żeby zbierać pieczątki';

  @override
  String get loginForStampsBody => 'Za każdego loda lub gofra dostajesz pieczątkę. Dziesiąta to lód gratis.';

  @override
  String get loginGoogle => 'Kontynuuj z Google';

  @override
  String get loginApple => 'Kontynuuj z Apple';

  @override
  String get loginEmail => 'Wyślij link na e-mail';

  @override
  String get demoLoginNote => 'Prototyp: logowanie jest symulowane.';

  @override
  String get rewardsHistory => 'Odebrane nagrody';

  @override
  String get noRewardsYet => 'Jeszcze żadnej. Pierwsza już niedługo!';

  @override
  String get badgeNew => 'Nowość';

  @override
  String get badgeBestseller => 'Bestseller';

  @override
  String get sampleData => 'Przykładowe pozycje i ceny, prawdziwe menu dodamy później.';

  @override
  String get aboutShop => 'O lokalu';

  @override
  String get address => 'Adres';

  @override
  String get navigate => 'Nawiguj';

  @override
  String get openingHours => 'Godziny otwarcia';

  @override
  String get followUs => 'Obserwuj nas';

  @override
  String get settings => 'Ustawienia';

  @override
  String get language => 'Język';

  @override
  String get theme => 'Motyw';

  @override
  String get themeSystem => 'Jak w telefonie';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get account => 'Konto';

  @override
  String get logout => 'Wyloguj';

  @override
  String get marketingConsent => 'Chcę dostawać powiadomienia o promocjach i nowych smakach';

  @override
  String get shopPanel => 'Panel sklepu';

  @override
  String get shopPanelHint => 'Widoczne tylko dla właściciela i obsługi';

  @override
  String get scanCustomer => 'Zeskanuj kod klienta';

  @override
  String get simulateScan => 'Symuluj skan (prototyp)';

  @override
  String get addStamps => 'Dodaj pieczątki';

  @override
  String stampsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dodano $count pieczątki',
      many: 'Dodano $count pieczątek',
      few: 'Dodano $count pieczątki',
      one: 'Dodano 1 pieczątkę',
    );
    return '$_temp0';
  }

  @override
  String get redeemReward => 'Wydaj darmowego loda';

  @override
  String get rewardRedeemed => 'Nagroda wydana, karta zaczyna się od nowa';

  @override
  String get panelMenu => 'Menu i ceny';

  @override
  String get panelPromos => 'Promocje';

  @override
  String get panelPush => 'Powiadomienia push';

  @override
  String get panelHours => 'Godziny otwarcia';

  @override
  String get panelStats => 'Statystyki';

  @override
  String get comingSoon => 'W prototypie tylko podgląd';

  @override
  String get freeIceCream => '1 × lód gratis';

  @override
  String get days => 'Poniedziałek,Wtorek,Środa,Czwartek,Piątek,Sobota,Niedziela';
}
