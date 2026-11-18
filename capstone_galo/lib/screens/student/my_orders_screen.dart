import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/canteen_order.dart';
import '../../services/order_service.dart';
import '../../state/student_provider.dart';
import '../../utils/format.dart';
import '../../widgets/status_chip.dart';
import 'order_status_screen.dart';

/// Orders placed with the student ID saved on this device.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  Stream<List<CanteenOrder>>? _orders;
  String? _forStudentId;

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>();
    if (student.studentId != _forStudentId) {
      _forStudentId = student.studentId;
      _orders = student.hasStudent
          ? context.read<OrderService>().watchStudentOrders(student.studentId!)
          : null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: _orders == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No orders yet.\nPlace an order and your student ID will be remembered on this phone.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : StreamBuilder<List<CanteenOrder>>(
              stream: _orders,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('Could not load orders.\n${snap.error}'),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snap.data!;
                if (orders.isEmpty) {
                  return Center(
                    child: Text('No orders for ${student.studentId}.'),
                  );
                }
                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final o = orders[i];
                    return ListTile(
                      title: Text('Order ${formatOrderNo(o.orderNo)}'),
                      subtitle: Text(
                        '${formatTime(o.createdAt)} • ${formatPeso(o.total)}',
                      ),
                      trailing: StatusChip(o.status),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderStatusScreen(orderId: o.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
