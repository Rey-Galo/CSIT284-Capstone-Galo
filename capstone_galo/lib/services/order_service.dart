import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/canteen_order.dart';

class OrderService {
  OrderService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  DocumentReference<Map<String, dynamic>> get _config =>
      _db.collection('config').doc('app');

  /// Creates a pending, cash-on-pickup order and returns its document ID.
  ///
  /// The short pickup number (`orderNo`) comes from the `config/app.nextOrderNo`
  /// counter, incremented in the same transaction so two students never get
  /// the same number.
  Future<String> placeOrder({
    required String studentId,
    required String studentName,
    required List<OrderLine> lines,
  }) async {
    if (lines.isEmpty) throw ArgumentError('Cannot place an empty order.');
    final orderRef = _orders.doc();
    final total = lines.fold<double>(0, (acc, l) => acc + l.subtotal);

    await _db.runTransaction((tx) async {
      final config = await tx.get(_config);
      final orderNo = (config.data()?['nextOrderNo'] as num?)?.toInt() ?? 1;
      tx.set(_config, {'nextOrderNo': orderNo + 1}, SetOptions(merge: true));
      tx.set(orderRef, {
        ...CanteenOrder(
          id: orderRef.id,
          orderNo: orderNo,
          studentId: studentId,
          studentName: studentName,
          items: lines,
          total: total,
          status: OrderStatus.pending,
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'readyAt': null,
      });
    });
    return orderRef.id;
  }

  /// Live updates for one order (null if it was deleted).
  Stream<CanteenOrder?> watchOrder(String id) => _orders
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? CanteenOrder.fromMap(d.id, d.data()!) : null);

  /// A student's orders, newest first.
  Stream<List<CanteenOrder>> watchStudentOrders(String studentId) => _orders
      .where('studentId', isEqualTo: studentId)
      .snapshots()
      .map((snap) => _sorted(snap, newestFirst: true));

  /// Staff queue: pending orders oldest first; ready orders newest first.
  Stream<List<CanteenOrder>> watchOrdersByStatus(OrderStatus status) => _orders
      .where('status', isEqualTo: status.value)
      .snapshots()
      .map((snap) => _sorted(snap, newestFirst: status == OrderStatus.ready));

  Future<void> markReady(String id) => _changeStatus(
    id,
    from: OrderStatus.pending,
    to: OrderStatus.ready,
    timestampField: 'readyAt',
  );

  /// Staff: the student collected and paid. Removes it from the staff queue.
  Future<void> markPickedUp(String id) => _changeStatus(
    id,
    from: OrderStatus.ready,
    to: OrderStatus.pickedUp,
    timestampField: 'closedAt',
  );

  /// Student: cancel an order that the canteen hasn't finished yet.
  Future<void> cancelOrder(String id) => _changeStatus(
    id,
    from: OrderStatus.pending,
    to: OrderStatus.cancelled,
    timestampField: 'closedAt',
  );

  /// Moves an order from [from] to [to] inside a transaction, so two phones
  /// can't race (e.g. a student cancelling while staff mark it ready).
  /// Throws a [StateError] if the order is no longer in [from].
  Future<void> _changeStatus(
    String id, {
    required OrderStatus from,
    required OrderStatus to,
    required String timestampField,
  }) => _db.runTransaction((tx) async {
    final ref = _orders.doc(id);
    final snap = await tx.get(ref);
    final current = OrderStatus.fromName(snap.data()?['status'] as String?);
    if (!snap.exists || current != from) {
      throw StateError('Order is already ${current.label.toLowerCase()}.');
    }
    tx.update(ref, {
      'status': to.value,
      timestampField: FieldValue.serverTimestamp(),
    });
  });

  // Sorting is done on the client so these queries need no composite index.
  List<CanteenOrder> _sorted(
    QuerySnapshot<Map<String, dynamic>> snap, {
    required bool newestFirst,
  }) {
    final orders = snap.docs
        .map((d) => CanteenOrder.fromMap(d.id, d.data()))
        .toList();
    // An order whose server timestamp hasn't arrived yet counts as newest.
    final far = DateTime(9999);
    orders.sort((a, b) {
      final cmp = (a.createdAt ?? far).compareTo(b.createdAt ?? far);
      return newestFirst ? -cmp : cmp;
    });
    return orders;
  }
}
