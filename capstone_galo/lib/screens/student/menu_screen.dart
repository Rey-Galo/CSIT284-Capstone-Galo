import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food_item.dart';
import '../../services/menu_service.dart';
import '../../state/cart_provider.dart';
import '../../state/student_provider.dart';
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

  final _searchController = TextEditingController();
  String _query = '';

  /// Selected category filter; null means "All".
  String? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCart() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const CartScreen()));

  void _openStaff() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const StaffPinScreen()));

  void _openOrders() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen()));

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = null;
    });
  }

  List<FoodItem> _filter(List<FoodItem> items, String? category) {
    final q = _query.trim().toLowerCase();
    return [
      for (final item in items)
        if ((category == null || item.category == category) &&
            (q.isEmpty || item.name.toLowerCase().contains(q)))
          item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _MenuDrawer(onOpenOrders: _openOrders, onOpenStaff: _openStaff),
      body: StreamBuilder<List<FoodItem>>(
        stream: _menu,
        builder: (context, snap) => CustomScrollView(
          slivers: [
            SliverAppBar.medium(
              // Long-pressing the title is a hidden shortcut to staff mode.
              title: GestureDetector(
                onLongPress: _openStaff,
                child: const Text('Canteen Menu'),
              ),
              actions: [_CartButton(onPressed: _openCart)],
            ),
            ..._buildBody(context, snap),
          ],
        ),
      ),
      bottomNavigationBar: _CartBar(onPressed: _openCart),
    );
  }

  List<Widget> _buildBody(
    BuildContext context,
    AsyncSnapshot<List<FoodItem>> snap,
  ) {
    if (snap.hasError) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Message(
            icon: Icons.cloud_off,
            text: 'Could not load the menu.\n${snap.error}',
          ),
        ),
      ];
    }
    if (!snap.hasData) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final items = snap.data!;
    if (items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Message(
            icon: Icons.no_food,
            text: 'The menu is empty.\nPlease check back later.',
          ),
        ),
      ];
    }

    // Categories in menu order (the service already sorts by category).
    final categories = <String>{for (final i in items) i.category}.toList();
    // A selected category that left the menu falls back to "All".
    final selected = categories.contains(_category) ? _category : null;

    // Flatten into headers (String) and items (FoodItem) for a lazy list.
    final visible = _filter(items, selected);
    final rows = <Object>[];
    for (final (i, item) in visible.indexed) {
      if (i == 0 || visible[i - 1].category != item.category) {
        rows.add(item.category);
      }
      rows.add(item);
    }

    return [
      SliverToBoxAdapter(child: _Greeting()),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search the menu',
            elevation: const WidgetStatePropertyAll(0),
            leading: const Icon(Icons.search),
            trailing: [
              if (_query.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
            ],
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final c in [null, ...categories])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: c == null ? null : Icon(categoryIcon(c), size: 18),
                    label: Text(c ?? 'All'),
                    selected: selected == c,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (rows.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Message(
            icon: Icons.search_off,
            text: 'No dishes match your search.',
            action: TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear filters'),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 24),
          sliver: SliverList.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final row = rows[i];
              if (row is String) {
                return _SectionHeader(
                  category: row,
                  count: visible.where((it) => it.category == row).length,
                );
              }
              final item = row as FoodItem;
              return MenuItemCard(key: ValueKey(item.id), item: item);
            },
          ),
        ),
    ];
  }
}

/// "Good morning, Juan" style greeting, using the saved student name if any.
class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = context.select<StudentProvider, String?>((s) => s.studentName);
    final first = name?.trim().split(RegExp(r'\s+')).first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            first == null || first.isEmpty
                ? '$greeting!'
                : '$greeting, $first!',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Order ahead, pay cash at pickup. No more lines.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.category, required this.count});

  final String category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          Icon(categoryIcon(category), size: 22, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            category,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count == 1 ? '1 item' : '$count items',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final qty = context.select<CartProvider, int>((c) => c.totalQty);
    return IconButton(
      tooltip: 'Cart',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: qty > 0,
        label: Text('$qty'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}

/// Sticky "View cart" bar that slides in once the cart has something in it.
class _CartBar extends StatelessWidget {
  const _CartBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: cart.isEmpty
          ? const SizedBox(width: double.infinity)
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Material(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(18),
                  elevation: 3,
                  child: InkWell(
                    onTap: onPressed,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shopping_bag, color: colors.onPrimary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'View cart (${cart.totalQty})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            formatPeso(cart.total),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: colors.onPrimary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _MenuDrawer extends StatelessWidget {
  const _MenuDrawer({required this.onOpenOrders, required this.onOpenStaff});

  final VoidCallback onOpenOrders;
  final VoidCallback onOpenStaff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void close(VoidCallback then) {
      Navigator.pop(context);
      then();
    }

    return NavigationDrawer(
      selectedIndex: 0,
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            Navigator.pop(context);
          case 1:
            close(onOpenOrders);
          case 2:
            close(onOpenStaff);
        }
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: const Icon(Icons.lunch_dining),
              ),
              const SizedBox(width: 12),
              Text(
                'Canteen Pre-Order',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: Text('Menu'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: Text('My Orders'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Divider(),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: Text('Staff Mode'),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ),
    );
  }
}
