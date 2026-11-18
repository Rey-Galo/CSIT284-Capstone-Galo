import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/food_item.dart';
import '../state/cart_provider.dart';
import '../utils/format.dart';
import 'qty_stepper.dart';

/// Menu photo from `imageUrl`, or a placeholder icon when there is none or it
/// fails to load.
class FoodThumbnail extends StatelessWidget {
  const FoodThumbnail(this.imageUrl, {super.key, this.size = 56});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Icon(
        Icons.restaurant,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl == null
          ? placeholder
          : Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({super.key, required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.qtyOf(item.id);
    final theme = Theme.of(context);

    final Widget trailing;
    if (!item.available) {
      trailing = Text(
        'Sold out',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    } else if (qty > 0) {
      trailing = QtyStepper(
        qty: qty,
        onAdd: () => cart.add(item),
        onRemove: () => cart.decrement(item.id),
      );
    } else {
      trailing = FilledButton.tonalIcon(
        onPressed: () => cart.add(item),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      );
    }

    return Opacity(
      opacity: item.available ? 1 : 0.5,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FoodThumbnail(item.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      formatPeso(item.price),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
