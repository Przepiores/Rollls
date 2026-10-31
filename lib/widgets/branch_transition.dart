import 'package:flutter/material.dart';

/// Płynne przejście między zakładkami: stara zakładka znika i lekko odjeżdża,
/// nowa pojawia się z kierunku, w którym leży na dolnym pasku.
/// Wszystkie zakładki zostają w drzewie, więc zachowują przewinięcie i stan.
class BranchTransition extends StatefulWidget {
  const BranchTransition({super.key, required this.currentIndex, required this.children});
  final int currentIndex;
  final List<Widget> children;

  @override
  State<BranchTransition> createState() => _BranchTransitionState();
}

class _BranchTransitionState extends State<BranchTransition> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1);
  int? _previous;

  @override
  void didUpdateWidget(BranchTransition old) {
    super.didUpdateWidget(old);
    if (old.currentIndex == widget.currentIndex) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _previous = null;
      _controller.value = 1;
      return;
    }
    _previous = old.currentIndex;
    _controller.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted) setState(() => _previous = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.currentIndex;
    final previous = _previous;
    final dir = previous == null || current > previous ? 1.0 : -1.0;
    const shift = 0.06;

    Animation<double> curve(double begin, double end, Curve c) => CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: c),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _branch(
            visible: i == current || i == previous,
            active: i == current,
            opacity: switch (i) {
              _ when i == current => curve(0.25, 1, Curves.easeOut),
              _ when i == previous => ReverseAnimation(curve(0, 0.4, Curves.easeIn)),
              _ => kAlwaysDismissedAnimation,
            },
            position: switch (i) {
              _ when i == current => Tween(
                begin: Offset(shift * dir, 0),
                end: Offset.zero,
              ).animate(curve(0, 1, Curves.easeOutCubic)),
              _ when i == previous => Tween(
                begin: Offset.zero,
                end: Offset(-shift * dir, 0),
              ).animate(curve(0, 0.4, Curves.easeIn)),
              _ => const AlwaysStoppedAnimation(Offset.zero),
            },
            child: widget.children[i],
          ),
      ],
    );
  }

  // Ta sama struktura dla każdej zakładki, żeby przy przełączaniu nie tracić ich stanu.
  Widget _branch({
    required bool visible,
    required bool active,
    required Animation<double> opacity,
    required Animation<Offset> position,
    required Widget child,
  }) => Offstage(
    offstage: !visible,
    child: IgnorePointer(
      ignoring: !active,
      child: TickerMode(
        enabled: visible,
        child: FadeTransition(
          opacity: opacity,
          child: SlideTransition(position: position, child: child),
        ),
      ),
    ),
  );
}
