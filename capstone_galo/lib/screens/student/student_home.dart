import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/cart_provider.dart';
import 'cart_screen.dart';
import 'menu_screen.dart';
import 'my_orders_screen.dart';

/// Student side: Menu, Orders and Cart tabs with a bottom navbar.
class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  /// The surrounding tab host, or null when a screen is shown on its own.
  static StudentHomeState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<StudentHomeState>();

  @override
  State<StudentHome> createState() => StudentHomeState();
}

class StudentHomeState extends State<StudentHome> {
  static const menuTab = 0, ordersTab = 1, cartTab = 2;

  int _index = menuTab;

  void select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final qty = context.select<CartProvider, int>((c) => c.totalQty);
    return Scaffold(
      // IndexedStack keeps each tab's scroll, search and form state.
      body: IndexedStack(
        index: _index,
        children: const [MenuScreen(), MyOrdersScreen(), CartScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: select,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: qty > 0,
              label: Text(qty > 99 ? '99+' : '$qty'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: qty > 0,
              label: Text(qty > 99 ? '99+' : '$qty'),
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}
