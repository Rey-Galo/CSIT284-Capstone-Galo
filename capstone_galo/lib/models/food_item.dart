/// A dish or drink on the canteen menu (Firestore collection `menu_items`).
///
/// Named `FoodItem` rather than `MenuItem` to avoid clashing with Flutter's
/// own `MenuItem` class.
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl,
    this.available = true,
  });

  final String id;
  final String name;
  final double price;
  final String category;
  final String? imageUrl;

  /// False means "sold out": shown greyed out and cannot be added to the cart.
  final bool available;

  factory FoodItem.fromMap(String id, Map<String, dynamic> map) {
    final rawUrl = (map['imageUrl'] as String?)?.trim();
    return FoodItem(
      id: id,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num? ?? 0).toDouble(),
      category: map['category'] as String? ?? 'Others',
      imageUrl: (rawUrl == null || rawUrl.isEmpty) ? null : rawUrl,
      available: map['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'category': category,
    'imageUrl': imageUrl,
    'available': available,
  };
}
