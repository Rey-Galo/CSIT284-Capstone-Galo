import 'package:flutter/material.dart';

import '../../models/food_item.dart';
import '../../theme/tokens.dart';
import '../../widgets/cart_bar.dart';
import '../../widgets/menu_item_card.dart';
import '../../widgets/motion.dart';
import 'cart_screen.dart';

/// One dish: big picture, name, price, quantity and description.
class FoodDetailsScreen extends StatelessWidget {
  const FoodDetailsScreen({super.key, required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Details Menu'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Hero(
                tag: 'food-${item.id}',
                child: FoodThumbnail(
                  item.imageUrl,
                  size: 220,
                  category: item.category,
                  greyedOut: !item.available,
                  circle: true,
                ),
              ),
            ),
          ),
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.category,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: PriceText(
                          item.price,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      ItemQtyControl(item: item, size: 32),
                    ],
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Divider(color: colors.outlineVariant),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      item.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CartBar(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
      ),
    );
  }
}
