import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.icecream_outlined),
            selectedIcon: const Icon(Icons.icecream),
            label: l.tabMenu,
          ),
          NavigationDestination(
            icon: const Icon(Icons.loyalty_outlined),
            selectedIcon: const Icon(Icons.loyalty),
            label: l.tabStamps,
          ),
          NavigationDestination(icon: const Icon(Icons.more_horiz), label: l.tabMore),
        ],
      ),
    );
  }
}
