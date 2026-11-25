import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/food_item.dart';
import '../../services/menu_service.dart';
import '../../state/student_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/cart_bar.dart';
import '../../widgets/menu_item_card.dart';
import '../../widgets/motion.dart';
import '../../widgets/state_views.dart';
import '../staff/staff_pin_screen.dart';
import 'cart_screen.dart';
import 'food_details_screen.dart';
import 'my_orders_screen.dart';
import 'student_home.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Stream<List<FoodItem>> _menu = context.read<MenuService>().watchMenu();

  final _searchController = TextEditingController();
  String _query = '';

  /// Selected category filter; null means "All".
  String? _category;

  /// Filter button: hide sold-out dishes.
  bool _availableOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() =>
      setState(() => _menu = context.read<MenuService>().watchMenu());

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  /// Switches to [tab] when inside [StudentHome], otherwise pushes [page].
  void _openTab(int tab, Widget page) {
    final home = StudentHome.maybeOf(context);
    home == null ? _push(page) : home.select(tab);
  }

  void _openCart() => _openTab(StudentHomeState.cartTab, const CartScreen());
  void _openStaff() => _push(const StaffPinScreen());
  void _openOrders() =>
      _openTab(StudentHomeState.ordersTab, const MyOrdersScreen());

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = null;
      _availableOnly = false;
    });
  }

  List<FoodItem> _filter(List<FoodItem> items, String? category) {
    final q = _query.trim().toLowerCase();
    return [
      for (final item in items)
        if ((category == null || item.category == category) &&
            (!_availableOnly || item.available) &&
            (q.isEmpty || item.name.toLowerCase().contains(q)))
          item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Status bar icons that stay readable over the orange header.
      value:
          ThemeData.estimateBrightnessForColor(
                Theme.of(context).colorScheme.primary,
              ) ==
              Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          drawer: _MenuDrawer(
            onOpenOrders: _openOrders,
            onOpenStaff: _openStaff,
          ),
          body: StreamBuilder<List<FoodItem>>(
            stream: _menu,
            builder: (context, snap) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    onOpenOrders: _openOrders,
                    onOpenStaff: _openStaff,
                  ),
                ),
                SliverToBoxAdapter(child: _buildSearch(context)),
                ..._buildBody(context, snap),
              ],
            ),
          ),
          bottomNavigationBar: CartBar(onPressed: _openCart),
        ),
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // White panel with rounded top corners sitting on the orange header.
    return ColoredBox(
      color: colors.primary,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search for "Adobo"',
                textInputAction: TextInputAction.search,
                constraints: const BoxConstraints(minHeight: 48),
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  if (_query.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
                ],
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _availableOnly
                ? IconButton.filled(
                    tooltip: 'Show sold-out dishes',
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll,
                      ),
                    ),
                    onPressed: () => setState(() => _availableOnly = false),
                    icon: const Icon(Icons.filter_alt_rounded),
                  )
                : IconButton.outlined(
                    tooltip: 'Hide sold-out dishes',
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(48),
                      side: BorderSide(color: colors.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll,
                      ),
                    ),
                    onPressed: () => setState(() => _availableOnly = true),
                    icon: const Icon(Icons.filter_alt_outlined),
                  ),
          ],
        ),
      ),
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
          child: ErrorState(title: "Couldn't load the menu", onRetry: _retry),
        ),
      ];
    }
    if (!snap.hasData) {
      return const [SliverToBoxAdapter(child: SkeletonList(count: 6))];
    }
    final items = snap.data!;
    if (items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.no_food_rounded,
            title: 'The menu is empty',
            message: 'The canteen hasn\'t added dishes yet. Check back later.',
          ),
        ),
      ];
    }

    // Categories in menu order (the service already sorts by category).
    final categories = <String>{for (final i in items) i.category}.toList();
    // A selected category that left the menu falls back to "All".
    final selected = categories.contains(_category) ? _category : null;
    final visible = _filter(items, selected);

    return [
      SliverToBoxAdapter(
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            children: [
              for (final c in [null, ...categories])
                _CategoryTile(
                  key: ValueKey('cat-${c ?? 'All'}'),
                  label: c ?? 'All',
                  icon: c == null
                      ? Icons.restaurant_menu_rounded
                      : categoryIcon(c),
                  selected: selected == c,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _category = c);
                  },
                ),
            ],
          ),
        ),
      ),
      if (visible.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No dishes match your search.',
            message: 'Try another word or category.',
            action: TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear filters'),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverGrid.builder(
            // New key per filter so the grid replays its entrance on change.
            key: ValueKey('$selected|$_query|$_availableOnly'),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              mainAxisExtent: 208,
            ),
            itemCount: visible.length,
            itemBuilder: (context, i) {
              final item = visible[i];
              return MenuItemCard(
                key: ValueKey(item.id),
                item: item,
                index: i,
                onTap: () => _push(FoodDetailsScreen(item: item)),
              );
            },
          ),
        ),
    ];
  }
}

/// Orange header: who is ordering, where, and a shortcut to My Orders.
class _Header extends StatelessWidget {
  const _Header({required this.onOpenOrders, required this.onOpenStaff});

  final VoidCallback onOpenOrders;
  final VoidCallback onOpenStaff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final student = context.watch<StudentProvider>();
    final name = student.studentName?.trim() ?? '';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final onHeader = colors.onPrimary;

    return ColoredBox(
      color: colors.primary,
      child: SafeArea(
        bottom: false,
        child: FadeSlideIn(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar opens the drawer (My Orders, Staff Mode).
                    Semantics(
                      button: true,
                      label: 'Open menu',
                      child: GestureDetector(
                        onTap: () => Scaffold.of(context).openDrawer(),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: colors.surfaceContainerLowest,
                          foregroundColor: colors.primary,
                          child: initials.isEmpty
                              ? const Icon(Icons.person_rounded)
                              : Text(
                                  initials,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'Hi there!' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: onHeader,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            student.hasStudent
                                ? 'Student ${student.studentId}'
                                : 'Student',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onHeader.withValues(alpha: .9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'My Orders',
                      onPressed: onOpenOrders,
                      style: IconButton.styleFrom(
                        backgroundColor: onHeader.withValues(alpha: .2),
                        foregroundColor: onHeader,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smAll,
                        ),
                      ),
                      icon: const Icon(Icons.notifications_rounded),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Long-pressing the canteen name is a hidden shortcut to staff mode.
                GestureDetector(
                  onLongPress: onOpenStaff,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront_rounded, size: 18, color: onHeader),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Text(
                        'School Canteen',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: onHeader,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              AnimatedContainer(
                duration: motionDuration(context, AppDurations.fast),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? colors.primary : colors.surfaceContainer,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  icon,
                  color: selected ? colors.onPrimary : colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? colors.onSurface : colors.onSurfaceVariant,
                ),
              ),
            ],
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
    final colors = theme.colorScheme;
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
          padding: const EdgeInsets.fromLTRB(
            28,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.mdAll,
                  color: colors.primary,
                ),
                child: Icon(
                  Icons.lunch_dining_rounded,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Canteen Pre-Order',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
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
          padding: EdgeInsets.symmetric(
            horizontal: 28,
            vertical: AppSpacing.sm,
          ),
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
