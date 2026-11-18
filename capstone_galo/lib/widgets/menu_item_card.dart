import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/food_item.dart';
import '../state/cart_provider.dart';
import '../utils/format.dart';
import 'qty_stepper.dart';

/// Icon for a menu category, used for section headers and photo placeholders.
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
  });

  final String? imageUrl;
  final double size;
  final String? category;

  /// Desaturates the image, e.g. for sold-out items.
  final bool greyedOut;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: size,
      height: size,
      color: colors.secondaryContainer,
      child: Icon(
        categoryIcon(category),
        size: size * 0.45,
        color: colors.onSecondaryContainer,
      ),
    );
    Widget image = imageUrl == null
        ? placeholder
        : Image.network(
            imageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: image,
    );
  }
}

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({super.key, required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    // Only this item's quantity: other cards don't rebuild on every cart change.
    final qty = context.select<CartProvider, int>((c) => c.qtyOf(item.id));
    final cart = context.read<CartProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final inCart = qty > 0;

    final Widget trailing;
    if (!item.available) {
      trailing = Container(
        key: const ValueKey('soldout'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Sold out',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.onErrorContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (inCart) {
      trailing = QtyStepper(
        key: const ValueKey('stepper'),
        qty: qty,
        onAdd: () => cart.add(item),
        onRemove: () => cart.decrement(item.id),
      );
    } else {
      trailing = FilledButton.tonalIcon(
        key: const ValueKey('add'),
        onPressed: () => cart.add(item),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: inCart
            ? colors.primaryContainer.withValues(alpha: 0.35)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: inCart ? colors.primary : colors.outlineVariant,
          width: inCart ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            FoodThumbnail(
              item.imageUrl,
              size: 68,
              category: item.category,
              greyedOut: !item.available,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: item.available
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPeso(item.price),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: item.available
                          ? colors.primary
                          : colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      decoration: item.available
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: trailing,
            ),
          ],
        ),
      ),
    );
  }
}
