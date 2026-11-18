import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  ready;

  static OrderStatus fromName(String? name) =>
      name == 'ready' ? OrderStatus.ready : OrderStatus.pending;

  String get label => this == OrderStatus.ready ? 'Ready' : 'Pending';
}

/// One line of an order. Name and price are copied from the menu at order
/// time so later menu edits don't change past orders.
class OrderLine {
  const OrderLine({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.qty,
  });

  final String menuItemId;
  final String name;
  final double price;
  final int qty;

  double get subtotal => price * qty;

  factory OrderLine.fromMap(Map<String, dynamic> map) => OrderLine(
    menuItemId: map['menuItemId'] as String? ?? '',
    name: map['name'] as String? ?? '',
    price: (map['price'] as num? ?? 0).toDouble(),
    qty: (map['qty'] as num? ?? 0).toInt(),
  );

  Map<String, dynamic> toMap() => {
    'menuItemId': menuItemId,
    'name': name,
    'price': price,
    'qty': qty,
  };
}

/// A placed order (Firestore collection `orders`). Payment is always cash on
/// pickup.
class CanteenOrder {
  const CanteenOrder({
    required this.id,
    required this.orderNo,
    required this.studentId,
    required this.studentName,
    required this.items,
    required this.total,
    required this.status,
    this.paymentMethod = cashOnPickup,
    this.createdAt,
    this.readyAt,
  });

  static const cashOnPickup = 'cash_on_pickup';

  final String id;
  final int orderNo;
  final String studentId;
  final String studentName;
  final List<OrderLine> items;
  final double total;
  final OrderStatus status;
  final String paymentMethod;

  /// Null briefly right after placing, until the server timestamp arrives.
  final DateTime? createdAt;
  final DateTime? readyAt;

  bool get isReady => status == OrderStatus.ready;

  factory CanteenOrder.fromMap(String id, Map<String, dynamic> map) =>
      CanteenOrder(
        id: id,
        orderNo: (map['orderNo'] as num? ?? 0).toInt(),
        studentId: map['studentId'] as String? ?? '',
        studentName: map['studentName'] as String? ?? '',
        items: ((map['items'] as List?) ?? const [])
            .map((e) => OrderLine.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        total: (map['total'] as num? ?? 0).toDouble(),
        status: OrderStatus.fromName(map['status'] as String?),
        paymentMethod: map['paymentMethod'] as String? ?? cashOnPickup,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        readyAt: (map['readyAt'] as Timestamp?)?.toDate(),
      );

  /// Fields stored in Firestore, excluding the server-written timestamps.
  Map<String, dynamic> toMap() => {
    'orderNo': orderNo,
    'studentId': studentId,
    'studentName': studentName,
    'items': items.map((e) => e.toMap()).toList(),
    'total': total,
    'status': status.name,
    'paymentMethod': paymentMethod,
  };
}
