import 'package:capstone_galo/models/food_item.dart';
import 'package:capstone_galo/state/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const adobo = FoodItem(id: 'a', name: 'Adobo', price: 75, category: 'Meals');
  const tea = FoodItem(
    id: 't',
    name: 'Iced Tea',
    price: 25,
    category: 'Drinks',
  );
  const soldOut = FoodItem(
    id: 's',
    name: 'Turon',
    price: 20,
    category: 'Snacks',
    available: false,
  );

  late CartProvider cart;
  setUp(() => cart = CartProvider());

  test('adding the same item increases its quantity', () {
    cart.add(adobo);
    cart.add(adobo);
    cart.add(tea);
    expect(cart.items, hasLength(2));
    expect(cart.qtyOf('a'), 2);
    expect(cart.totalQty, 3);
    expect(cart.total, 175);
  });

  test('sold-out items cannot be added', () {
    cart.add(soldOut);
    expect(cart.isEmpty, isTrue);
  });

  test('decrement removes the item at zero', () {
    cart.add(adobo);
    cart.add(adobo);
    cart.decrement('a');
    expect(cart.qtyOf('a'), 1);
    cart.decrement('a');
    expect(cart.isEmpty, isTrue);
  });

  test('remove and clear', () {
    cart.add(adobo);
    cart.add(tea);
    cart.remove('a');
    expect(cart.qtyOf('a'), 0);
    cart.clear();
    expect(cart.isEmpty, isTrue);
    expect(cart.total, 0);
  });

  test('toOrderLines copies name, price and quantity', () {
    cart.add(tea);
    cart.add(tea);
    final line = cart.toOrderLines().single;
    expect(line.menuItemId, 't');
    expect(line.name, 'Iced Tea');
    expect(line.price, 25);
    expect(line.qty, 2);
    expect(line.subtotal, 50);
  });
}
