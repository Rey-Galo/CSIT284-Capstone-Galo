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
    this.description,
    this.available = true,
  });

  final String id;
  final String name;
  final double price;
  final String category;
  final String? imageUrl;

  /// Optional short text shown on the details page.
  final String? description;

  /// False means "sold out": shown greyed out and cannot be added to the cart.
  final bool available;

  factory FoodItem.fromMap(String id, Map<String, dynamic> map) {
    String? optional(String key) {
      final v = (map[key] as String?)?.trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    return FoodItem(
      id: id,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num? ?? 0).toDouble(),
      category: map['category'] as String? ?? 'Others',
      imageUrl: optional('imageUrl'),
      description: optional('description'),
      available: map['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'category': category,
    'imageUrl': imageUrl,
    'description': description,
    'available': available,
  };
}
