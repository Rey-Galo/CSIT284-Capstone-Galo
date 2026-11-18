import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/cart_provider.dart';
import '../../utils/format.dart';
import '../../widgets/menu_item_card.dart';
import '../../widgets/qty_stepper.dart';
import 'checkout_sheet.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 56,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  const Text('Your cart is empty.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Browse menu'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: cart.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final line = cart.items[i];
                return ListTile(
                  leading: FoodThumbnail(line.item.imageUrl, size: 44),
                  title: Text(line.item.name),
                  subtitle: Text(
                    '${formatPeso(line.item.price)} each • ${formatPeso(line.subtotal)}',
                  ),
                  trailing: QtyStepper(
                    qty: line.qty,
                    onAdd: () => cart.add(line.item),
                    onRemove: () => cart.decrement(line.item.id),
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('Total', style: theme.textTheme.titleLarge),
                        const Spacer(),
                        Text(
                          formatPeso(cart.total),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => const CheckoutSheet(),
                      ),
                      child: const Text('Place Order'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
