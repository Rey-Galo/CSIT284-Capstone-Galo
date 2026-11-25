import 'package:capstone_galo/models/cart_item.dart';
import 'package:capstone_galo/models/food_item.dart';
import 'package:capstone_galo/state/cart_provider.dart';
import 'package:capstone_galo/theme/tokens.dart';
import 'package:capstone_galo/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FadeSlideIn ends fully visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FadeSlideIn(index: 3, child: Text('hi'))),
    );
    await tester.pumpAndSettle();
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(of: find.text('hi'), matching: find.byType(FadeTransition))
          .first,
    );
    expect(fade.opacity.value, 1);
  });

  testWidgets('reduced motion gives zero durations', (tester) async {
    late Duration d;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            d = motionDuration(context, AppDurations.slow);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(d, Duration.zero);
  });

  test('restore puts a removed cart line back with its quantity', () {
    final cart = CartProvider();
    const item = FoodItem(
      id: 'a',
      name: 'Turon',
      price: 20,
      category: 'Snacks',
      available: true,
    );
    cart
      ..add(item)
      ..add(item);
    final line = CartItem(item: item, qty: cart.qtyOf('a'));
    cart.remove('a');
    cart.restore(line);
    expect(cart.qtyOf('a'), 2);
  });
}
