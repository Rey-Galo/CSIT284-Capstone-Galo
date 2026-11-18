import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food_item.dart';
import '../../services/menu_service.dart';
import '../../utils/format.dart';
import '../../widgets/menu_item_card.dart';
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
  late final Stream<List<FoodItem>> _menu = _service.watchMenu();
  bool _seeding = false;

  void _openForm([FoodItem? item]) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => MenuItemFormScreen(item: item)));

  Future<void> _toggle(FoodItem item, bool available) async {
    try {
      await _service.setAvailable(item.id, available);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
        actions: const [ExitStaffButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: StreamBuilder<List<FoodItem>>(
        stream: _menu,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load menu.\n${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No menu items yet.'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _seeding ? null : _seed,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Load sample menu'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                leading: FoodThumbnail(item.imageUrl, size: 44),
                title: Text(item.name),
                subtitle: Text(
                  '${item.category} • ${formatPeso(item.price)}${item.available ? '' : ' • SOLD OUT'}',
                ),
                trailing: Switch(
                  value: item.available,
                  onChanged: (v) => _toggle(item, v),
                ),
                onTap: () => _openForm(item),
              );
            },
          );
        },
      ),
    );
  }
}
