import 'package:flutter/foundation.dart';

import '../models/canteen_order.dart';
import '../models/cart_item.dart';
import '../models/food_item.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => List.unmodifiable(_items.values);
  bool get isEmpty => _items.isEmpty;
  int get totalQty => _items.values.fold(0, (acc, c) => acc + c.qty);
  double get total => _items.values.fold(0, (acc, c) => acc + c.subtotal);

  int qtyOf(String itemId) => _items[itemId]?.qty ?? 0;

  void add(FoodItem item) {
    if (!item.available) return;
    final existing = _items[item.id];
    if (existing == null) {
      _items[item.id] = CartItem(item: item);
    } else {
      existing.qty++;
    }
    notifyListeners();
  }

  /// Lowers the quantity by one, removing the item when it reaches zero.
  void decrement(String itemId) {
    final existing = _items[itemId];
    if (existing == null) return;
    if (existing.qty <= 1) {
      _items.remove(itemId);
    } else {
      existing.qty--;
    }
    notifyListeners();
  }

  void remove(String itemId) {
    if (_items.remove(itemId) != null) notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<OrderLine> toOrderLines() =>
      _items.values.map((c) => c.toOrderLine()).toList();
}
