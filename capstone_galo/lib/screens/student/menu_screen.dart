import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food_item.dart';
import '../../services/menu_service.dart';
import '../../state/cart_provider.dart';
import '../../utils/format.dart';
import '../../widgets/menu_item_card.dart';
import '../staff/staff_pin_screen.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final Stream<List<FoodItem>> _menu = context
      .read<MenuService>()
      .watchMenu();

  void _openCart() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const CartScreen()));

  void _openStaff() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const StaffPinScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Long-pressing the title is a hidden shortcut to staff mode.
        title: GestureDetector(
          onLongPress: _openStaff,
          child: const Text('Canteen Menu'),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) => IconButton(
              tooltip: 'Cart',
              onPressed: _openCart,
              icon: Badge(
                isLabelVisible: cart.totalQty > 0,
                label: Text('${cart.totalQty}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Canteen Pre-Order',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Menu'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('My Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('Staff Mode'),
              onTap: () {
                Navigator.pop(context);
                _openStaff();
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<FoodItem>>(
        stream: _menu,
        builder: (context, snap) {
          if (snap.hasError) {
            return _Message(
              icon: Icons.cloud_off,
              text: 'Could not load the menu.\n${snap.error}',
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const _Message(
              icon: Icons.no_food,
              text: 'The menu is empty.\nPlease check back later.',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              for (final (i, item) in items.indexed) ...[
                if (i == 0 || items[i - 1].category != item.category)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      item.category,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                MenuItemCard(item: item),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, _) => cart.isEmpty
            ? const SizedBox.shrink()
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _openCart,
                    icon: const Icon(Icons.shopping_cart),
                    label: Text(
                      'View cart (${cart.totalQty}) • ${formatPeso(cart.total)}',
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
