import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('pl')];

  /// No description provided for @tabHome.
  ///
  /// In pl, this message translates to:
  /// **'Start'**
  String get tabHome;

  /// No description provided for @tabMenu.
  ///
  /// In pl, this message translates to:
  /// **'Menu'**
  String get tabMenu;

  /// No description provided for @tabStamps.
  ///
  /// In pl, this message translates to:
  /// **'Pieczątki'**
  String get tabStamps;

  /// No description provided for @tabMore.
  ///
  /// In pl, this message translates to:
  /// **'Więcej'**
  String get tabMore;

  /// No description provided for @greeting.
  ///
  /// In pl, this message translates to:
  /// **'Cześć{name}!'**
  String greeting(String name);

  /// No description provided for @tagline.
  ///
  /// In pl, this message translates to:
  /// **'Happy calories don\'t count'**
  String get tagline;

  /// No description provided for @openUntil.
  ///
  /// In pl, this message translates to:
  /// **'Otwarte do {time}'**
  String openUntil(String time);

  /// No description provided for @closedOpensAt.
  ///
  /// In pl, this message translates to:
  /// **'Zamknięte · otwieramy {day} o {time}'**
  String closedOpensAt(String day, String time);

  /// No description provided for @today.
  ///
  /// In pl, this message translates to:
  /// **'dziś'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In pl, this message translates to:
  /// **'jutro'**
  String get tomorrow;

  /// No description provided for @promotions.
  ///
  /// In pl, this message translates to:
  /// **'Promocje'**
  String get promotions;

  /// No description provided for @news.
  ///
  /// In pl, this message translates to:
  /// **'Nowości'**
  String get news;

  /// No description provided for @seeMenu.
  ///
  /// In pl, this message translates to:
  /// **'Zobacz menu'**
  String get seeMenu;

  /// No description provided for @yourCard.
  ///
  /// In pl, this message translates to:
  /// **'Twoja karta'**
  String get yourCard;

  /// No description provided for @stampsProgress.
  ///
  /// In pl, this message translates to:
  /// **'{count} z {total} pieczątek'**
  String stampsProgress(int count, int total);

  /// No description provided for @stampsToReward.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{Jeszcze 1 pieczątka do darmowego loda} few{Jeszcze {count} pieczątki do darmowego loda} many{Jeszcze {count} pieczątek do darmowego loda} other{Jeszcze {count} pieczątki do darmowego loda}}'**
  String stampsToReward(int count);

  /// No description provided for @rewardReady.
  ///
  /// In pl, this message translates to:
  /// **'Darmowy lód czeka na Ciebie!'**
  String get rewardReady;

  /// No description provided for @rewardHint.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż kod przy ladzie, a obsługa wyda nagrodę.'**
  String get rewardHint;

  /// No description provided for @showCode.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż ten kod przy ladzie po zakupie'**
  String get showCode;

  /// No description provided for @loginForStamps.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się, żeby zbierać pieczątki'**
  String get loginForStamps;

  /// No description provided for @loginForStampsBody.
  ///
  /// In pl, this message translates to:
  /// **'Za każdego loda lub gofra dostajesz pieczątkę. Dziesiąta to lód gratis.'**
  String get loginForStampsBody;

  /// No description provided for @loginGoogle.
  ///
  /// In pl, this message translates to:
  /// **'Kontynuuj z Google'**
  String get loginGoogle;

  /// No description provided for @loginApple.
  ///
  /// In pl, this message translates to:
  /// **'Kontynuuj z Apple'**
  String get loginApple;

  /// No description provided for @loginEmail.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij link na e-mail'**
  String get loginEmail;

  /// No description provided for @demoLoginNote.
  ///
  /// In pl, this message translates to:
  /// **'Prototyp: logowanie jest symulowane.'**
  String get demoLoginNote;

  /// No description provided for @rewardsHistory.
  ///
  /// In pl, this message translates to:
  /// **'Odebrane nagrody'**
  String get rewardsHistory;

  /// No description provided for @noRewardsYet.
  ///
  /// In pl, this message translates to:
  /// **'Jeszcze żadnej. Pierwsza już niedługo!'**
  String get noRewardsYet;

  /// No description provided for @badgeNew.
  ///
  /// In pl, this message translates to:
  /// **'Nowość'**
  String get badgeNew;

  /// No description provided for @badgeBestseller.
  ///
  /// In pl, this message translates to:
  /// **'Bestseller'**
  String get badgeBestseller;

  /// No description provided for @sampleData.
  ///
  /// In pl, this message translates to:
  /// **'Przykładowe pozycje i ceny, prawdziwe menu dodamy później.'**
  String get sampleData;

  /// No description provided for @aboutShop.
  ///
  /// In pl, this message translates to:
  /// **'O lokalu'**
  String get aboutShop;

  /// No description provided for @address.
  ///
  /// In pl, this message translates to:
  /// **'Adres'**
  String get address;

  /// No description provided for @navigate.
  ///
  /// In pl, this message translates to:
  /// **'Nawiguj'**
  String get navigate;

  /// No description provided for @openingHours.
  ///
  /// In pl, this message translates to:
  /// **'Godziny otwarcia'**
  String get openingHours;

  /// No description provided for @followUs.
  ///
  /// In pl, this message translates to:
  /// **'Obserwuj nas'**
  String get followUs;

  /// No description provided for @settings.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In pl, this message translates to:
  /// **'Język'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In pl, this message translates to:
  /// **'Motyw'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In pl, this message translates to:
  /// **'Jak w telefonie'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In pl, this message translates to:
  /// **'Jasny'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In pl, this message translates to:
  /// **'Ciemny'**
  String get themeDark;

  /// No description provided for @account.
  ///
  /// In pl, this message translates to:
  /// **'Konto'**
  String get account;

  /// No description provided for @logout.
  ///
  /// In pl, this message translates to:
  /// **'Wyloguj'**
  String get logout;

  /// No description provided for @marketingConsent.
  ///
  /// In pl, this message translates to:
  /// **'Chcę dostawać powiadomienia o promocjach i nowych smakach'**
  String get marketingConsent;

  /// No description provided for @shopPanel.
  ///
  /// In pl, this message translates to:
  /// **'Panel sklepu'**
  String get shopPanel;

  /// No description provided for @shopPanelHint.
  ///
  /// In pl, this message translates to:
  /// **'Widoczne tylko dla właściciela i obsługi'**
  String get shopPanelHint;

  /// No description provided for @scanCustomer.
  ///
  /// In pl, this message translates to:
  /// **'Zeskanuj kod klienta'**
  String get scanCustomer;

  /// No description provided for @simulateScan.
  ///
  /// In pl, this message translates to:
  /// **'Symuluj skan (prototyp)'**
  String get simulateScan;

  /// No description provided for @addStamps.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj pieczątki'**
  String get addStamps;

  /// No description provided for @stampsAdded.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{Dodano 1 pieczątkę} few{Dodano {count} pieczątki} many{Dodano {count} pieczątek} other{Dodano {count} pieczątki}}'**
  String stampsAdded(int count);

  /// No description provided for @redeemReward.
  ///
  /// In pl, this message translates to:
  /// **'Wydaj darmowego loda'**
  String get redeemReward;

  /// No description provided for @rewardRedeemed.
  ///
  /// In pl, this message translates to:
  /// **'Nagroda wydana, karta zaczyna się od nowa'**
  String get rewardRedeemed;

  /// No description provided for @panelMenu.
  ///
  /// In pl, this message translates to:
  /// **'Menu i ceny'**
  String get panelMenu;

  /// No description provided for @panelPromos.
  ///
  /// In pl, this message translates to:
  /// **'Promocje'**
  String get panelPromos;

  /// No description provided for @panelPush.
  ///
  /// In pl, this message translates to:
  /// **'Powiadomienia push'**
  String get panelPush;

  /// No description provided for @panelHours.
  ///
  /// In pl, this message translates to:
  /// **'Godziny otwarcia'**
  String get panelHours;

  /// No description provided for @panelStats.
  ///
  /// In pl, this message translates to:
  /// **'Statystyki'**
  String get panelStats;

  /// No description provided for @comingSoon.
  ///
  /// In pl, this message translates to:
  /// **'W prototypie tylko podgląd'**
  String get comingSoon;

  /// No description provided for @freeIceCream.
  ///
  /// In pl, this message translates to:
  /// **'1 × lód gratis'**
  String get freeIceCream;

  /// No description provided for @days.
  ///
  /// In pl, this message translates to:
  /// **'Poniedziałek,Wtorek,Środa,Czwartek,Piątek,Sobota,Niedziela'**
  String get days;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
