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
    // "Meals" appears as a category tile and under the dish name.
    expect(find.byKey(const ValueKey('cat-Meals')), findsOneWidget);
    expect(find.text('Meals'), findsNWidgets(2));
    expect(find.text('Sold out'), findsOneWidget); // Turon is unavailable
    expect(find.textContaining('selected'), findsNothing);

    await tester.tap(find.byTooltip('Add to cart'));
    await tester.pumpAndSettle();

    expect(find.text('1 item selected'), findsOneWidget);
    expect(find.textContaining('₱75.00'), findsWidgets);
  });

  testWidgets('tapping a dish opens its details page', (tester) async {
    await tester.pumpWidget(CanteenApp(firestore: db, student: student));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chicken Adobo with Rice'));
    await tester.pumpAndSettle();

    expect(find.text('Details Menu'), findsOneWidget);
    expect(find.text('Chicken Adobo with Rice'), findsOneWidget);

    await tester.tap(find.byTooltip('Add to cart'));
    await tester.pumpAndSettle();
    expect(find.text('1 item selected'), findsOneWidget);
  });

  testWidgets('navbar switches between Menu, Orders and Cart', (tester) async {
    await tester.pumpWidget(CanteenApp(firestore: db, student: student));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('No orders yet.'), findsOneWidget);

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add to cart'));
    await tester.pumpAndSettle();
    // Cart badge on the navbar.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsOneWidget,
    );

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Payout'), findsOneWidget);
    expect(find.text('Place Order'), findsOneWidget);
  });

  testWidgets('category tiles and search filter the menu', (tester) async {
    await tester.pumpWidget(CanteenApp(firestore: db, student: student));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cat-Snacks')));
    await tester.pumpAndSettle();
    expect(find.text('Turon'), findsOneWidget);
    expect(find.text('Chicken Adobo with Rice'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('cat-All')));
    await tester.enterText(find.byType(SearchBar), 'adobo');
    await tester.pumpAndSettle();
    expect(find.text('Chicken Adobo with Rice'), findsOneWidget);
    expect(find.text('Turon'), findsNothing);

    await tester.enterText(find.byType(SearchBar), 'pizza');
    await tester.pumpAndSettle();
    expect(find.text('No dishes match your search.'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Turon'), findsOneWidget);
    expect(find.text('Chicken Adobo with Rice'), findsOneWidget);
  });

  testWidgets('placing an order shows the live status screen', (tester) async {
    await tester.pumpWidget(CanteenApp(firestore: db, student: student));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add to cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 item selected'));
    await tester.pumpAndSettle();
    expect(find.text('Payout'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Student ID'),
      '2021-00123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Juan Dela Cruz',
    );
    await tester.tap(find.text('Place Order'));
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
