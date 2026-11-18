import 'package:capstone_galo/app.dart';
import 'package:capstone_galo/state/student_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeFirebaseFirestore db;
  late StudentProvider student;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = FakeFirebaseFirestore();
    await db.collection('menu_items').add({
      'name': 'Chicken Adobo with Rice',
      'price': 75,
      'category': 'Meals',
      'available': true,
    });
    await db.collection('menu_items').add({
      'name': 'Turon',
      'price': 20,
      'category': 'Snacks',
      'available': false,
    });
    student = StudentProvider();
    await student.load();
  });

  testWidgets('menu shows items and Add updates the cart', (tester) async {
    await tester.pumpWidget(CanteenApp(firestore: db, student: student));
    await tester.pumpAndSettle();

    expect(find.text('Chicken Adobo with Rice'), findsOneWidget);
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Sold out'), findsOneWidget); // Turon is unavailable
    expect(find.textContaining('View cart'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.textContaining('View cart (1)'), findsOneWidget);
    expect(find.textContaining('₱75.00'), findsWidgets);
  });

  testWidgets('placing an order shows the live status screen', (tester) async {
    await tester.pumpWidget(CanteenApp(firestore: db, student: student));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('View cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Student ID'),
      '2021-00123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Juan Dela Cruz',
    );
    await tester.tap(find.textContaining('Confirm Order'));
    await tester.pumpAndSettle();

    expect(find.text('#0001'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(student.studentId, '2021-00123');

    // Staff marks it ready -> the student's screen updates by itself.
    final order = (await db.collection('orders').get()).docs.single;
    await order.reference.update({'status': 'ready'});
    await tester.pumpAndSettle();

    expect(find.text('Ready'), findsOneWidget);
    expect(find.textContaining('ready for pickup'), findsOneWidget);
  });
}
