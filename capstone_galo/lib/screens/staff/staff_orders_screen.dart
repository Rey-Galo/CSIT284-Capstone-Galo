import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/canteen_order.dart';
import '../../services/order_service.dart';
import '../../utils/format.dart';
import 'staff_home_screen.dart';

/// Live order queue with Pending and Ready tabs.
class StaffOrdersScreen extends StatelessWidget {
  const StaffOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          actions: const [ExitStaffButton()],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.hourglass_top), text: 'Pending'),
              Tab(icon: Icon(Icons.check_circle_outline), text: 'Ready'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OrderList(status: OrderStatus.pending),
            _OrderList(status: OrderStatus.ready),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatefulWidget {
  const _OrderList({required this.status});

  final OrderStatus status;

  @override
  State<_OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<_OrderList>
    with AutomaticKeepAliveClientMixin {
  late final Stream<List<CanteenOrder>> _orders = context
      .read<OrderService>()
      .watchOrdersByStatus(widget.status);

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<CanteenOrder>>(
      stream: _orders,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Could not load orders.\n${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data!;
        if (orders.isEmpty) {
          return Center(
            child: Text(
              widget.status == OrderStatus.pending
                  ? 'No pending orders.'
                  : 'No ready orders yet.',
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: orders.length,
          itemBuilder: (context, i) => _StaffOrderCard(order: orders[i]),
        );
      },
    );
  }
}

class _StaffOrderCard extends StatefulWidget {
  const _StaffOrderCard({required this.order});

  final CanteenOrder order;

  @override
  State<_StaffOrderCard> createState() => _StaffOrderCardState();
}

class _StaffOrderCardState extends State<_StaffOrderCard> {
  bool _saving = false;

  Future<void> _markReady() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await context.read<OrderService>().markReady(widget.order.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Order ${formatOrderNo(widget.order.orderNo)} marked ready',
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  formatOrderNo(order.orderNo),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  formatTime(order.isReady ? order.readyAt : order.createdAt),
                ),
              ],
            ),
            Text(
              '${order.studentName} • ${order.studentId}',
              style: theme.textTheme.titleSmall,
            ),
            const Divider(),
            for (final line in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${line.qty}× ${line.name}',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Collect ${formatPeso(order.total)} cash',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!order.isReady)
                  FilledButton.icon(
                    onPressed: _saving ? null : _markReady,
                    icon: const Icon(Icons.check),
                    label: const Text('Mark Ready'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
