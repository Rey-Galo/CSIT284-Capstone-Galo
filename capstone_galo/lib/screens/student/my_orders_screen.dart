import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/canteen_order.dart';
import '../../services/order_service.dart';
import '../../state/student_provider.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../widgets/motion.dart';
import '../../widgets/state_views.dart';
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

  void _subscribe(StudentProvider student) {
    _orders = student.hasStudent
        ? context.read<OrderService>().watchStudentOrders(student.studentId!)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>();
    if (student.studentId != _forStudentId) {
      _forStudentId = student.studentId;
      _subscribe(student);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: _orders == null
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet.',
              message:
                  'Place an order and your student ID will be remembered on this phone.',
            )
          : StreamBuilder<List<CanteenOrder>>(
              stream: _orders,
              builder: (context, snap) {
                if (snap.hasError) {
                  return ErrorState(
                    title: "Couldn't load your orders",
                    onRetry: () => setState(() => _subscribe(student)),
                  );
                }
                if (!snap.hasData) return const SkeletonList();
                final orders = snap.data!;
                if (orders.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders for ${student.studentId}.',
                    message: 'Your orders will show up here.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: orders.length,
                  itemBuilder: (context, i) => FadeSlideIn(
                    key: ValueKey(orders[i].id),
                    index: i,
                    child: _OrderCard(order: orders[i]),
                  ),
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final CanteenOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final itemCount = order.items.fold<int>(0, (a, l) => a + l.qty);
    return Pressable(
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs + 2,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderStatusScreen(orderId: order.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Hero(
                  tag: orderHeroTag(order.id),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      formatOrderNo(order.orderNo),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatPeso(order.total)} • $itemCount item${itemCount == 1 ? '' : 's'}',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        formatTime(order.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(order.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
