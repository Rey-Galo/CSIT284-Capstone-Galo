import 'package:capstone_galo/models/canteen_order.dart';
import 'package:capstone_galo/models/food_item.dart';
import 'package:capstone_galo/services/config_service.dart';
import 'package:capstone_galo/services/menu_service.dart';
import 'package:capstone_galo/services/order_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  setUp(() => db = FakeFirebaseFirestore());

  const lines = [
    OrderLine(menuItemId: 'a', name: 'Adobo', price: 75, qty: 2),
    OrderLine(menuItemId: 't', name: 'Iced Tea', price: 25, qty: 1),
  ];

  group('OrderService', () {
    test(
      'placeOrder creates a pending cash order with incrementing numbers',
      () async {
        final service = OrderService(db);
        final id1 = await service.placeOrder(
          studentId: 'S1',
          studentName: 'Ana',
          lines: lines,
        );
        final id2 = await service.placeOrder(
          studentId: 'S2',
          studentName: 'Ben',
          lines: lines.sublist(1),
        );

        final o1 = await service.watchOrder(id1).first;
        final o2 = await service.watchOrder(id2).first;
        expect(o1!.orderNo, 1);
        expect(o2!.orderNo, 2);
        expect(o1.status, OrderStatus.pending);
        expect(o1.total, 175);
        expect(o1.paymentMethod, CanteenOrder.cashOnPickup);
        expect(o1.items.map((l) => l.name), ['Adobo', 'Iced Tea']);
        expect(o1.createdAt, isNotNull);
      },
    );

    test('placeOrder rejects an empty cart', () {
      expect(
        () => OrderService(
          db,
        ).placeOrder(studentId: 'S1', studentName: 'Ana', lines: const []),
        throwsArgumentError,
      );
    });

    test(
      'markReady moves an order from the pending to the ready queue',
      () async {
        final service = OrderService(db);
        final id = await service.placeOrder(
          studentId: 'S1',
          studentName: 'Ana',
          lines: lines,
        );
        expect(
          await service.watchOrdersByStatus(OrderStatus.pending).first,
          hasLength(1),
        );

        await service.markReady(id);

        expect(
          await service.watchOrdersByStatus(OrderStatus.pending).first,
          isEmpty,
        );
        final ready = await service
            .watchOrdersByStatus(OrderStatus.ready)
            .first;
        expect(ready.single.id, id);
        expect(ready.single.readyAt, isNotNull);
      },
    );

    test('watchStudentOrders only returns that student\'s orders', () async {
      final service = OrderService(db);
      await service.placeOrder(
        studentId: 'S1',
        studentName: 'Ana',
        lines: lines,
      );
      await service.placeOrder(
        studentId: 'S2',
        studentName: 'Ben',
        lines: lines,
      );
      final mine = await service.watchStudentOrders('S1').first;
      expect(mine.single.studentName, 'Ana');
    });
  });

  group('MenuService', () {
    test('add, toggle availability and sort by category then name', () async {
      final service = MenuService(db);
      await service.addItem(
        const FoodItem(id: '', name: 'Water', price: 15, category: 'Drinks'),
      );
      await service.addItem(
        const FoodItem(id: '', name: 'Adobo', price: 75, category: 'Meals'),
      );
      await service.addItem(
        const FoodItem(id: '', name: 'Iced Tea', price: 25, category: 'Drinks'),
      );

      var menu = await service.watchMenu().first;
      expect(menu.map((i) => i.name), ['Iced Tea', 'Water', 'Adobo']);

      await service.setAvailable(menu.first.id, false);
      menu = await service.watchMenu().first;
      expect(menu.first.available, isFalse);
    });

    test('seedSampleMenu fills the menu', () async {
      await MenuService(db).seedSampleMenu();
      expect(await MenuService(db).watchMenu().first, isNotEmpty);
    });
  });

  group('ConfigService', () {
    test('uses the default PIN until one is configured', () async {
      final service = ConfigService(db);
      expect(
        await service.verifyStaffPin(ConfigService.defaultStaffPin),
        isTrue,
      );
      await db.collection('config').doc('app').set({'staffPin': '9876'});
      expect(await service.verifyStaffPin('1234'), isFalse);
      expect(await service.verifyStaffPin('9876'), isTrue);
    });
  });

  group('Models', () {
    test('FoodItem map round-trip and blank image URL', () {
      const item = FoodItem(
        id: 'x',
        name: 'Siopao',
        price: 35,
        category: 'Snacks',
      );
      final back = FoodItem.fromMap('x', {...item.toMap(), 'imageUrl': '  '});
      expect(back.name, 'Siopao');
      expect(back.price, 35);
      expect(back.imageUrl, isNull);
      expect(back.available, isTrue);
    });

    test('CanteenOrder map round-trip', () {
      const order = CanteenOrder(
        id: 'o',
        orderNo: 7,
        studentId: 'S1',
        studentName: 'Ana',
        items: lines,
        total: 175,
        status: OrderStatus.ready,
      );
      final back = CanteenOrder.fromMap('o', order.toMap());
      expect(back.orderNo, 7);
      expect(back.status, OrderStatus.ready);
      expect(back.items.first.qty, 2);
      expect(back.total, 175);
    });
  });
}
