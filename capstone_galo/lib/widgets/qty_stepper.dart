import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Small orange circle button: filled (e.g. +) or outlined (e.g. −).
/// The visible circle is [size], the tap target stays 40 px or more.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = true,
    this.size = 26,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tap = size < 40 ? 40.0 : size;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onPressed,
          radius: tap / 2,
          child: SizedBox.square(
            dimension: tap,
            child: Center(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? colors.primary : null,
                  border: filled
                      ? null
                      : Border.all(color: colors.primary, width: 1.5),
                ),
                child: Icon(
                  icon,
                  size: size * 0.65,
                  color: filled ? colors.onPrimary : colors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// − qty + control. The number pops when it changes.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    this.size = 26,
  });

  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  /// Diameter of the visible circles.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoundIconButton(
          icon: qty <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
          tooltip: qty <= 1 ? 'Remove' : 'Decrease',
          onPressed: onRemove,
          filled: false,
          size: size,
        ),
        SizedBox(
          width: 18,
          child: AnimatedSwitcher(
            duration: motionDuration(context, AppDurations.fast),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: Text(
              '$qty',
              key: ValueKey(qty),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        RoundIconButton(
          icon: Icons.add_rounded,
          tooltip: 'Increase',
          onPressed: onAdd,
          size: size,
        ),
      ],
    );
  }
}
