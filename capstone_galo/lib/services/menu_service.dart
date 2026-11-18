import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_item.dart';

class MenuService {
  MenuService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('menu_items');

  /// Live menu, sorted by category then name (sorted on the client so no
  /// composite Firestore index is needed).
  Stream<List<FoodItem>> watchMenu() => _items.snapshots().map((snap) {
    final items = snap.docs
        .map((d) => FoodItem.fromMap(d.id, d.data()))
        .toList();
    items.sort((a, b) {
      final byCategory = a.category.compareTo(b.category);
      return byCategory != 0
          ? byCategory
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return items;
  });

  Future<void> addItem(FoodItem item) =>
      _items.add({...item.toMap(), 'createdAt': FieldValue.serverTimestamp()});

  Future<void> updateItem(FoodItem item) =>
      _items.doc(item.id).update(item.toMap());

  Future<void> setAvailable(String id, bool available) =>
      _items.doc(id).update({'available': available});

  Future<void> deleteItem(String id) => _items.doc(id).delete();

  /// Fills an empty menu with sample items so the app can be demoed right away.
  Future<void> seedSampleMenu() async {
    const samples = [
      ('Chicken Adobo with Rice', 75.0, 'Meals'),
      ('Pork Sinigang with Rice', 85.0, 'Meals'),
      ('Fried Chicken with Rice', 80.0, 'Meals'),
      ('Pancit Canton', 50.0, 'Snacks'),
      ('Siopao Asado', 35.0, 'Snacks'),
      ('Turon', 20.0, 'Snacks'),
      ('Iced Tea', 25.0, 'Drinks'),
      ('Bottled Water', 15.0, 'Drinks'),
    ];
    final batch = _db.batch();
    for (final (name, price, category) in samples) {
      batch.set(_items.doc(), {
        ...FoodItem(
          id: '',
          name: name,
          price: price,
          category: category,
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
