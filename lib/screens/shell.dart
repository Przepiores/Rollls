import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Każda zakładka podświetla się kolorem innej rolki z logo.
const _tabColors = [RollColors.lime, RollColors.pink, RollColors.yellow, RollColors.sky];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RainbowStripe(height: 4),
          NavigationBar(
            indicatorColor: _tabColors[shell.currentIndex],
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
        ],
      ),
    );
  }
}
