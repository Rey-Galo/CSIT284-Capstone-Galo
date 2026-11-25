import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/cart_provider.dart';
import '../theme/tokens.dart';
import 'motion.dart';

/// Dark "N items selected" bar that slides up once the cart has something in
/// it. The orange total on the right opens the cart.
class CartBar extends StatelessWidget {
  const CartBar({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final d = motionDuration(context, AppDurations.slow);
    final qty = cart.totalQty;

    return AnimatedSize(
      duration: d,
      curve: AppCurves.enter,
      child: AnimatedSwitcher(
        duration: d,
        switchInCurve: AppCurves.enter,
        switchOutCurve: AppCurves.exit,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: cart.isEmpty
            ? const SizedBox(key: ValueKey('empty'), width: double.infinity)
            : SafeArea(
                key: const ValueKey('bar'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Semantics(
                    button: true,
                    label: 'View cart',
                    child: Material(
                      color: colors.inverseSurface,
                      borderRadius: AppRadius.smAll,
                      child: InkWell(
                        onTap: onPressed,
                        borderRadius: AppRadius.smAll,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.sm,
                            AppSpacing.sm,
                            AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      qty == 1
                                          ? '1 item selected'
                                          : '$qty items selected',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: colors.onInverseSurface,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cart.items
                                          .map((l) => l.item.name)
                                          .join(', '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colors.onInverseSurface
                                                .withValues(alpha: .7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: AppRadius.smAll,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    BumpOnChange(
                                      value: qty,
                                      child: AnimatedPeso(
                                        cart.total,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color: colors.onPrimary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                      color: colors.onPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
