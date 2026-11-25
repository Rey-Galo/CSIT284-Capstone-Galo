import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food_item.dart';
import '../../services/menu_service.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../widgets/menu_item_card.dart';
import '../../widgets/motion.dart';
import '../../widgets/state_views.dart';
import 'menu_item_form_screen.dart';
import 'staff_home_screen.dart';

/// Staff list of all menu items with an availability (sold-out) switch.
class MenuManageScreen extends StatefulWidget {
  const MenuManageScreen({super.key});

  @override
  State<MenuManageScreen> createState() => _MenuManageScreenState();
}

class _MenuManageScreenState extends State<MenuManageScreen> {
  late final MenuService _service = context.read<MenuService>();
  late Stream<List<FoodItem>> _menu = _service.watchMenu();
  bool _seeding = false;

  void _openForm([FoodItem? item]) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => MenuItemFormScreen(item: item)));

  Future<void> _toggle(FoodItem item, bool available) async {
    try {
      await _service.setAvailable(item.id, available);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update. Please try again.")),
      );
    }
  }

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await _service.seedSampleMenu();
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _addPhotos() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await _service.addSamplePhotos();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'No items needed a sample photo.'
                : 'Added photos to $count item${count == 1 ? '' : 's'}.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't add photos. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
        actions: [
          IconButton(
            tooltip: 'Add sample photos',
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: _addPhotos,
          ),
          const ExitStaffButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add item'),
      ),
      body: StreamBuilder<List<FoodItem>>(
        stream: _menu,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorState(
              title: "Couldn't load the menu",
              onRetry: () => setState(() => _menu = _service.watchMenu()),
            );
          }
          if (!snap.hasData) return const SkeletonList();
          final items = snap.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.restaurant_menu_rounded,
              title: 'No menu items yet.',
              message: 'Add your first dish, or start from a sample menu.',
              action: OutlinedButton.icon(
                onPressed: _seeding ? null : _seed,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Load sample menu'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 96),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return FadeSlideIn(
                key: ValueKey(item.id),
                index: i,
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    leading: FoodThumbnail(
                      item.imageUrl,
                      size: 48,
                      category: item.category,
                      greyedOut: !item.available,
                    ),
                    title: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${item.category} • ${formatPeso(item.price)}${item.available ? '' : ' • SOLD OUT'}',
                      style: TextStyle(
                        color: item.available ? null : colors.error,
                      ),
                    ),
                    trailing: Switch(
                      value: item.available,
                      onChanged: (v) => _toggle(item, v),
                    ),
                    onTap: () => _openForm(item),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
