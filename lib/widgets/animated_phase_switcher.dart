import 'package:flutter/material.dart';

/// Cross-fades between the phases of an async view (loading / error / empty /
/// content) instead of swapping abruptly.
///
/// Give each phase child a distinct [KeyedSubtree] key so the switcher knows
/// when to animate; children sharing a key update in place without motion.
class AnimatedPhaseSwitcher extends StatelessWidget {
  final Duration duration;
  final Widget child;

  const AnimatedPhaseSwitcher({
    super.key,
    this.duration = const Duration(milliseconds: 250),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: child,
    );
  }
}
