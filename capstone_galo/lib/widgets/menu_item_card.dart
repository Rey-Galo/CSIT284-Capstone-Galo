import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/food_item.dart';
import '../state/cart_provider.dart';
import '../theme/tokens.dart';
import '../utils/format.dart';
import 'motion.dart';
import 'qty_stepper.dart';

/// Icon for a menu category, used for category tiles and photo placeholders.
IconData categoryIcon(String? category) {
  final c = category?.toLowerCase() ?? '';
  if (c.contains('meal') || c.contains('rice')) return Icons.rice_bowl;
  if (c.contains('snack')) return Icons.bakery_dining;
  if (c.contains('drink') || c.contains('beverage')) return Icons.local_drink;
  if (c.contains('dessert') || c.contains('sweet')) return Icons.icecream;
  return Icons.restaurant;
}

/// Menu photo from `imageUrl`, or a placeholder icon when there is none or it
/// fails to load. Pass [category] to get a matching placeholder icon.
class FoodThumbnail extends StatelessWidget {
  const FoodThumbnail(
    this.imageUrl, {
    super.key,
    this.size = 56,
    this.category,
    this.greyedOut = false,
    this.circle = false,
  });

  final String? imageUrl;
  final double size;
  final String? category;

  /// Desaturates the image, e.g. for sold-out items.
  final bool greyedOut;

  /// Round crop instead of a rounded square.
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: size,
      height: size,
      color: colors.surfaceContainer,
      child: Icon(
        categoryIcon(category),
        size: size * 0.45,
        color: colors.primary,
      ),
    );
    Widget image = imageUrl == null
        ? placeholder
        : Image.network(
            imageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            frameBuilder: (_, child, frame, sync) => sync
                ? child
                : AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: motionDuration(context, AppDurations.medium),
                    child: child,
                  ),
            errorBuilder: (_, _, _) => placeholder,
          );
    if (greyedOut) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0, 0, 0, 0.6, 0,
        ]),
        child: image,
      );
    }
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(circle ? size / 2 : size * 0.26),
        child: image,
      ),
    );
  }
}

/// A peso amount with the centavos drawn smaller, e.g. "₱75" + ".00".
class PriceText extends StatelessWidget {
  const PriceText(this.amount, {super.key, this.style});

  final double amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base =
        style ??
        Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);
    final text = formatPeso(amount);
    final dot = text.lastIndexOf('.');
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: dot < 0 ? text : text.substring(0, dot)),
          if (dot >= 0)
            TextSpan(
              text: text.substring(dot),
              style: TextStyle(fontSize: (base?.fontSize ?? 16) * 0.6),
            ),
        ],
      ),
      style: base,
      semanticsLabel: text,
    );
  }
}

/// Add button, − qty + stepper or "Sold out" pill for one menu item.
class ItemQtyControl extends StatelessWidget {
  const ItemQtyControl({super.key, required this.item, this.size = 26});

  final FoodItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Only this item's quantity: other cards don't rebuild on every cart change.
    final qty = context.select<CartProvider, int>((c) => c.qtyOf(item.id));
    final cart = context.read<CartProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    void add() {
      HapticFeedback.lightImpact();
      cart.add(item);
    }

    final Widget child;
    if (!item.available) {
      child = Container(
        key: const ValueKey('soldout'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          'Sold out',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onErrorContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else if (qty > 0) {
      child = QtyStepper(
        key: const ValueKey('stepper'),
        qty: qty,
        size: size,
        onAdd: add,
        onRemove: () => cart.decrement(item.id),
      );
    } else {
      child = RoundIconButton(
        key: const ValueKey('add'),
        icon: Icons.add_rounded,
        tooltip: 'Add to cart',
        size: size,
        onPressed: add,
      );
    }

    return AnimatedSwitcher(
      duration: motionDuration(context, AppDurations.medium),
      switchInCurve: AppCurves.pop,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: child,
    );
  }
}

/// Grid card: round photo, name, category, price and the add control.
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.index = 0,
  });

  final FoodItem item;
  final VoidCallback onTap;

  /// Position in the grid, used to stagger the entrance animation.
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = colors.onSurfaceVariant;

    return FadeSlideIn(
      index: index,
      child: Pressable(
        child: Material(
          color: colors.surfaceContainerLowest,
          borderRadius: AppRadius.mdAll,
          shadowColor: Colors.black.withValues(alpha: .25),
          elevation: 1,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.mdAll,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Hero(
                        tag: 'food-${item.id}',
                        child: FoodThumbnail(
                          item.imageUrl,
                          size: 84,
                          category: item.category,
                          greyedOut: !item.available,
                          circle: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: item.available ? colors.onSurface : muted,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Text(
                      item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: PriceText(
                              item.price,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: item.available
                                    ? colors.onSurface
                                    : muted,
                              ),
                            ),
                          ),
                        ),
                        ItemQtyControl(item: item),
                      ],
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
