import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food_item.dart';
import '../../services/menu_service.dart';

/// Add a new menu item (when [item] is null) or edit an existing one.
class MenuItemFormScreen extends StatefulWidget {
  const MenuItemFormScreen({super.key, this.item});

  final FoodItem? item;

  @override
  State<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends State<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _price = TextEditingController(
    text: widget.item == null ? '' : widget.item!.price.toStringAsFixed(2),
  );
  late final _category = TextEditingController(
    text: widget.item?.category ?? 'Meals',
  );
  late final _imageUrl = TextEditingController(text: widget.item?.imageUrl);
  late bool _available = widget.item?.available ?? true;
  bool _saving = false;

  bool get _isEdit => widget.item != null;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _category.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<MenuService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final url = _imageUrl.text.trim();
    final item = FoodItem(
      id: widget.item?.id ?? '',
      name: _name.text.trim(),
      price: double.parse(_price.text.trim()),
      category: _category.text.trim(),
      imageUrl: url.isEmpty ? null : url,
      available: _available,
    );
    setState(() => _saving = true);
    try {
      _isEdit ? await service.updateItem(item) : await service.addItem(item);
      navigator.pop();
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _delete() async {
    final service = context.read<MenuService>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text(
          '"${widget.item!.name}" will be removed from the menu. '
          'Past orders are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await service.deleteItem(widget.item!.id);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Item' : 'Add Item'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _price,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final price = double.tryParse(v?.trim() ?? '');
                if (price == null || price <= 0) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                helperText: 'e.g. Meals, Snacks, Drinks',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrl,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Available'),
              subtitle: const Text('Turn off to show as sold out'),
              value: _available,
              onChanged: (v) => setState(() => _available = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _saving ? null : _save,
              child: Text(_isEdit ? 'Save changes' : 'Add to menu'),
            ),
          ],
        ),
      ),
    );
  }
}
