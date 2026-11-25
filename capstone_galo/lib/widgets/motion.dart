import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../utils/format.dart';

/// Fades and slides its child up once, when first built.
///
/// [index] staggers items in a list; the delay is capped so long lists
/// never make the user wait.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _stepMs = 40;

  late final int _delayMs = _stepMs * widget.index.clamp(0, 6);
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDurations.slow + Duration(milliseconds: _delayMs),
  );
  // The stagger delay is the start of an Interval, so no timers are needed.
  late final Animation<double> _curve = CurvedAnimation(
    parent: _c,
    curve: Interval(
      _delayMs / (AppDurations.slow.inMilliseconds + _delayMs),
      1,
      curve: AppCurves.enter,
    ),
  );
  late final Animation<Offset> _offset = Tween(
    begin: const Offset(0, 0.15),
    end: Offset.zero,
  ).animate(_curve);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status != AnimationStatus.dismissed) return;
    if (motionDuration(context, AppDurations.slow) == Duration.zero) {
      _c.value = 1;
      return;
    }
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(position: _offset, child: widget.child),
  );
}

/// Shrinks slightly while pressed, for tappable cards.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child});

  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: motionDuration(context, AppDurations.fast),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Pops its child with a quick scale bump whenever [value] changes.
class BumpOnChange extends StatefulWidget {
  const BumpOnChange({super.key, required this.value, required this.child});

  final Object value;
  final Widget child;

  @override
  State<BumpOnChange> createState() => _BumpOnChangeState();
}

class _BumpOnChangeState extends State<BumpOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppDurations.medium,
  );
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));

  @override
  void didUpdateWidget(BumpOnChange old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value &&
        motionDuration(context, AppDurations.medium) != Duration.zero) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// A peso amount that counts smoothly to its new value.
class AnimatedPeso extends StatelessWidget {
  const AnimatedPeso(this.amount, {super.key, this.style});

  final double amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: amount),
    duration: motionDuration(context, AppDurations.slow),
    curve: AppCurves.enter,
    builder: (_, v, _) => Text(formatPeso(v), style: style),
  );
}
