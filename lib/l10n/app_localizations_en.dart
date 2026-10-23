// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabHome => 'Home';

  @override
  String get tabMenu => 'Menu';

  @override
  String get tabStamps => 'Stamps';

  @override
  String get tabMore => 'More';

  @override
  String greeting(String name) {
    return 'Hi$name!';
  }

  @override
  String get tagline => 'Happy calories don\'t count';

  @override
  String openUntil(String time) {
    return 'Open until $time';
  }

  @override
  String closedOpensAt(String day, String time) {
    return 'Closed · opens $day at $time';
  }

  @override
  String get today => 'today';

  @override
  String get tomorrow => 'tomorrow';

  @override
  String get promotions => 'Deals';

  @override
  String get news => 'New in';

  @override
  String get seeMenu => 'See the menu';

  @override
  String get yourCard => 'Your card';

  @override
  String stampsProgress(int count, int total) {
    return '$count of $total stamps';
  }

  @override
  String stampsToReward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more stamps to a free ice cream',
      one: '1 more stamp to a free ice cream',
    );
    return '$_temp0';
  }

  @override
  String get rewardReady => 'Your free ice cream is waiting!';

  @override
  String get rewardHint => 'Show the code at the counter to get your reward.';

  @override
  String get showCode => 'Show this code at the counter after you pay';

  @override
  String get loginForStamps => 'Sign in to collect stamps';

  @override
  String get loginForStampsBody => 'Every ice cream or waffle earns a stamp. The tenth one is a free ice cream.';

  @override
  String get loginGoogle => 'Continue with Google';

  @override
  String get loginApple => 'Continue with Apple';

  @override
  String get loginEmail => 'Email me a sign-in link';

  @override
  String get demoLoginNote => 'Prototype: sign-in is simulated.';

  @override
  String get rewardsHistory => 'Rewards collected';

  @override
  String get noRewardsYet => 'None yet. Your first one is close!';

  @override
  String get badgeNew => 'New';

  @override
  String get badgeBestseller => 'Bestseller';

  @override
  String get sampleData => 'Sample items and prices, the real menu comes later.';

  @override
  String get aboutShop => 'About us';

  @override
  String get address => 'Address';

  @override
  String get navigate => 'Directions';

  @override
  String get openingHours => 'Opening hours';

  @override
  String get followUs => 'Follow us';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'Same as phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get account => 'Account';

  @override
  String get logout => 'Sign out';

  @override
  String get marketingConsent => 'Send me news about deals and new flavours';

  @override
  String get shopPanel => 'Shop panel';

  @override
  String get shopPanelHint => 'Visible only to the owner and staff';

  @override
  String get scanCustomer => 'Scan customer code';

  @override
  String get simulateScan => 'Simulate scan (prototype)';

  @override
  String get addStamps => 'Add stamps';

  @override
  String stampsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count stamps',
      one: 'Added 1 stamp',
    );
    return '$_temp0';
  }

  @override
  String get redeemReward => 'Give free ice cream';

  @override
  String get rewardRedeemed => 'Reward given, the card starts over';

  @override
  String get panelMenu => 'Menu and prices';

  @override
  String get panelPromos => 'Deals';

  @override
  String get panelPush => 'Push notifications';

  @override
  String get panelHours => 'Opening hours';

  @override
  String get panelStats => 'Statistics';

  @override
  String get comingSoon => 'Preview only in the prototype';

  @override
  String get freeIceCream => '1 × free ice cream';

  @override
  String get days => 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';
}
