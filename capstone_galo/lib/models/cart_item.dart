import 'canteen_order.dart';
import 'food_item.dart';

/// An item in the in-memory cart (not stored in Firestore).
class CartItem {
  CartItem({required this.item, this.qty = 1});

  final FoodItem item;
  int qty;

  double get subtotal => item.price * qty;

  OrderLine toOrderLine() => OrderLine(
    menuItemId: item.id,
    name: item.name,
    price: item.price,
    qty: qty,
  );
}
