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
    final batch = _db.batch();
    for (final (name, price, category, description, imageUrl) in _samples) {
      batch.set(_items.doc(), {
        ...FoodItem(
          id: '',
          name: name,
          price: price,
          category: category,
          description: description,
          imageUrl: imageUrl,
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Gives existing items without a photo the sample photo with the same name
  /// (for menus seeded before photos existed). Returns how many were updated.
  Future<int> addSamplePhotos() async {
    final photos = {for (final s in _samples) s.$1.toLowerCase(): s.$5};
    final batch = _db.batch();
    var count = 0;
    for (final doc in (await _items.get()).docs) {
      final item = FoodItem.fromMap(doc.id, doc.data());
      final url = photos[item.name.trim().toLowerCase()];
      if (item.imageUrl == null && url != null) {
        batch.update(doc.reference, {'imageUrl': url});
        count++;
      }
    }
    await batch.commit();
    return count;
  }
}

// Free-licensed photos from Wikimedia Commons (500px thumbnails).
const _img = 'https://upload.wikimedia.org/wikipedia/commons/thumb';
const _samples = [
  (
    'Chicken Adobo with Rice',
    75.0,
    'Meals',
    'Chicken simmered in soy sauce, vinegar and garlic, served with steamed rice.',
    '$_img/8/8f/Lomo_en_adobo-2009.jpg/500px-Lomo_en_adobo-2009.jpg',
  ),
  (
    'Pork Sinigang with Rice',
    85.0,
    'Meals',
    'Sour tamarind soup with pork and vegetables, plus a cup of rice.',
    '$_img/c/c3/The_Best_Sinigang_Cuisine.jpg/500px-The_Best_Sinigang_Cuisine.jpg',
  ),
  (
    'Fried Chicken with Rice',
    80.0,
    'Meals',
    'Crispy golden fried chicken with rice and gravy.',
    '$_img/2/2c/Fried-Chicken-Set.jpg/500px-Fried-Chicken-Set.jpg',
  ),
  (
    'Tapsilog',
    75.0,
    'Meals',
    'Beef tapa, garlic fried rice and a sunny-side-up egg.',
    '$_img/b/b9/Beef_tapa_with_steamed_rice_and_sliced_tomato_and_cucumber.jpg/500px-Beef_tapa_with_steamed_rice_and_sliced_tomato_and_cucumber.jpg',
  ),
  (
    'Longsilog',
    70.0,
    'Meals',
    'Sweet longganisa, garlic fried rice and a fried egg.',
    '$_img/1/1b/Longaniza.jpg/500px-Longaniza.jpg',
  ),
  (
    'Pancit Canton',
    50.0,
    'Snacks',
    'Stir-fried egg noodles with vegetables and a squeeze of calamansi.',
    '$_img/e/ef/Pancit_Ilonggo_Style_-_12110747826.jpg/500px-Pancit_Ilonggo_Style_-_12110747826.jpg',
  ),
  (
    'Siopao Asado',
    35.0,
    'Snacks',
    'Soft steamed bun filled with sweet pork asado.',
    '$_img/8/84/Steamed-Pork-Buns-BBQ_Siopao-Asado-Recipe.webp/500px-Steamed-Pork-Buns-BBQ_Siopao-Asado-Recipe.webp',
  ),
  (
    'Turon',
    20.0,
    'Snacks',
    'Banana and jackfruit in a crispy caramelised wrapper.',
    '$_img/2/28/Turon_na_Saging.jpg/500px-Turon_na_Saging.jpg',
  ),
  (
    'Lumpiang Shanghai',
    40.0,
    'Snacks',
    'Crispy pork spring rolls with sweet chili dip.',
    '$_img/4/43/Loenpia_Semarang.JPG/500px-Loenpia_Semarang.JPG',
  ),
  (
    'Iced Tea',
    25.0,
    'Drinks',
    'House-brewed iced tea, lightly sweet.',
    '$_img/e/ef/Iced_Tea_from_flickr.jpg/500px-Iced_Tea_from_flickr.jpg',
  ),
  (
    'Gulaman',
    20.0,
    'Drinks',
    'Cold brown-sugar drink with jelly cubes.',
    '$_img/e/e7/JfBuffetsinthe9025PhilippinesBaliuagfvf_06.JPG/500px-JfBuffetsinthe9025PhilippinesBaliuagfvf_06.JPG',
  ),
  (
    'Bottled Water',
    15.0,
    'Drinks',
    '500 ml bottled water.',
    '$_img/c/ce/Water_Bottle_%2851308317077%29.jpg/500px-Water_Bottle_%2851308317077%29.jpg',
  ),
  (
    'Coke',
    30.0,
    'Drinks',
    'Ice-cold Coke in a can.',
    '$_img/2/27/Coca_Cola_Flasche_-_Original_Taste.jpg/500px-Coca_Cola_Flasche_-_Original_Taste.jpg',
  ),
  (
    'Mango Float',
    40.0,
    'Desserts',
    'Layers of graham, cream and sweet ripe mango.',
    '$_img/d/d7/Mango_float_%28Crema_de_Mangga%29_-_Philippines.jpg/500px-Mango_float_%28Crema_de_Mangga%29_-_Philippines.jpg',
  ),
  (
    'Leche Flan',
    35.0,
    'Desserts',
    'Smooth egg custard with caramel syrup.',
    '$_img/5/58/Cremecaramel.jpg/500px-Cremecaramel.jpg',
  ),
  (
    'Halo-Halo',
    50.0,
    'Desserts',
    'Shaved ice with milk, sweet beans, jellies and leche flan.',
    '$_img/7/79/Halo-Halo.jpg/500px-Halo-Halo.jpg',
  ),
];
