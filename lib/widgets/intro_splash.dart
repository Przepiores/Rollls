import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'wings.dart';

/// Animacja przy otwieraniu aplikacji: tęczowe skrzydła rozkładają się zza logo,
/// potem ekran znika. Dotknięcie pomija animację.
class IntroSplash extends StatefulWidget {
  const IntroSplash({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<IntroSplash> createState() => _IntroSplashState();
}

class _IntroSplashState extends State<IntroSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });

  static const _logoAsset = 'assets/images/logo.png';
  var _started = false;

  // Logo wskakuje, skrzydła się rozkładają, chwila pauzy, ekran znika.
  late final _logo = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.25, curve: Curves.elasticOut),
  );
  late final _wings = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.12, 0.75, curve: Curves.easeOutCubic),
  );
  late final _title = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.55, 0.75, curve: Curves.easeOut),
  );
  late final _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.85, 1, curve: Curves.easeIn),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
    } else if (!_started) {
      _started = true;
      // Start dopiero po wczytaniu logo, żeby pierwsze klatki nie pokazały pustego koła.
      // Najwyżej półtorej sekundy czekania, gdyby wczytywanie się zacięło.
      Future.any([
        precacheImage(const AssetImage(_logoAsset), context),
        Future<void>.delayed(const Duration(milliseconds: 1500)),
      ]).whenComplete(() {
        if (mounted && !_c.isAnimating) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final wingsWidth = (size.width * 0.92).clamp(0.0, 440.0);
    return GestureDetector(
      onTap: widget.onDone,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Opacity(
          opacity: 1 - _fade.value,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: dark ? const [Color(0xFF3A1F5C), night] : const [Colors.white, lavenderDeep],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: wingsWidth,
                    height: wingsWidth * 0.72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: WingsPainter(open: _wings.value)),
                        ),
                        Transform.scale(
                          scale: 0.4 + 0.6 * _logo.value,
                          child: Container(
                            width: wingsWidth * 0.27,
                            height: wingsWidth * 0.27,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: neonGlow(RollColors.pink, blur: 24),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: ClipOval(child: Image.asset(_logoAsset, semanticLabel: 'Ice Rolls')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Opacity(
                    opacity: _title.value,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - _title.value)),
                      child: Text(
                        AppLocalizations.of(context).tagline,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
