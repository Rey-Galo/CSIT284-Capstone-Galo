import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/canteen_order.dart';
import '../../services/order_service.dart';
import '../../utils/format.dart';
import '../../widgets/status_chip.dart';

/// Live status of one order. Updates by itself when staff mark it Ready.
class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  late final Stream<CanteenOrder?> _order = context
      .read<OrderService>()
      .watchOrder(widget.orderId);

  bool _cancelling = false;

  Future<void> _cancel() async {
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<OrderService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text('The canteen will stop preparing it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _cancelling = true);
    try {
      await service.cancelOrder(widget.orderId);
      messenger.showSnackBar(const SnackBar(content: Text('Order cancelled.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not cancel: $e')));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Order Status')),
      body: StreamBuilder<CanteenOrder?>(
        stream: _order,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load order.\n${snap.error}'));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snap.data;
          if (order == null) {
            return const Center(child: Text('Order not found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Your pickup number',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                formatOrderNo(order.orderNo),
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Center(child: StatusChip(order.status)),
              const SizedBox(height: 16),
              _StatusBanner(order: order),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    for (final line in order.items)
                      ListTile(
                        dense: true,
                        title: Text('${line.qty}× ${line.name}'),
                        trailing: Text(formatPeso(line.subtotal)),
                      ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text(
                        'Total (cash on pickup)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        formatPeso(order.total),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.studentName} • ${order.studentId}\nOrdered ${formatTime(order.createdAt)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              if (order.status == OrderStatus.pending) ...[
                TextButton.icon(
                  onPressed: _cancelling ? null : _cancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel order'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Back to menu'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.order});

  final CanteenOrder order;

  @override
  Widget build(BuildContext context) {
    final (icon, fg, bg, message) = switch (order.status) {
      OrderStatus.pending => (
        Icons.soup_kitchen,
        Colors.orange.shade800,
        Colors.amber.shade50,
        'The canteen is preparing your order. This screen updates automatically when it is ready.',
      ),
      OrderStatus.ready => (
        Icons.notifications_active,
        Colors.green.shade800,
        Colors.green.shade100,
        'Your order is ready for pickup! Show your pickup number and pay ${formatPeso(order.total)} in cash at the counter.',
      ),
      OrderStatus.pickedUp => (
        Icons.done_all,
        Colors.blueGrey.shade700,
        Colors.blueGrey.shade50,
        'You picked up this order. Enjoy your meal!',
      ),
      OrderStatus.cancelled => (
        Icons.cancel,
        Colors.red.shade800,
        Colors.red.shade50,
        'This order was cancelled.',
      ),
    };
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 36, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
