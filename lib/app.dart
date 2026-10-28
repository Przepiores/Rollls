import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations.dart';
import 'screens/admin_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/more_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/shell.dart';
import 'screens/stamps_screen.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets/branch_transition.dart';
import 'widgets/intro_splash.dart';

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute(
      builder: (_, _, shell) => AppShell(shell: shell),
      navigatorContainerBuilder: (_, shell, children) =>
          BranchTransition(currentIndex: shell.currentIndex, children: children),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/menu', builder: (_, _) => const MenuScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/stamps', builder: (_, _) => const StampsScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/more', builder: (_, _) => const MoreScreen())],
        ),
      ],
    ),
    GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
    GoRoute(path: '/scan', builder: (_, _) => const ScanScreen()),
  ],
);

class IceRollsApp extends ConsumerStatefulWidget {
  const IceRollsApp({super.key});

  @override
  ConsumerState<IceRollsApp> createState() => _IceRollsAppState();
}

class _IceRollsAppState extends ConsumerState<IceRollsApp> {
  final _router = _buildRouter();
  var _introDone = false;

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ice Rolls',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
      builder: (context, child) => Stack(
        children: [
          ?child,
          if (!_introDone) Positioned.fill(child: IntroSplash(onDone: () => setState(() => _introDone = true))),
        ],
      ),
    );
  }
}
