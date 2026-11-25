import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/canteen_order.dart';
import '../../services/order_service.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../widgets/motion.dart';
import '../../widgets/state_views.dart';
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
              Tab(icon: Icon(Icons.hourglass_top_rounded), text: 'Pending'),
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
  late Stream<List<CanteenOrder>> _orders = _watch();

  Stream<List<CanteenOrder>> _watch() =>
      context.read<OrderService>().watchOrdersByStatus(widget.status);

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final pending = widget.status == OrderStatus.pending;
    return StreamBuilder<List<CanteenOrder>>(
      stream: _orders,
      builder: (context, snap) {
        if (snap.hasError) {
          return ErrorState(
            title: "Couldn't load orders",
            onRetry: () => setState(() => _orders = _watch()),
          );
        }
        if (!snap.hasData) return const SkeletonList(height: 140);
        final orders = snap.data!;
        if (orders.isEmpty) {
          return EmptyState(
            icon: pending ? Icons.coffee_rounded : Icons.shopping_bag_outlined,
            title: pending ? 'No pending orders.' : 'No ready orders yet.',
            message: pending
                ? 'New orders pop in here automatically.'
                : 'Orders you mark ready wait here for pickup.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: orders.length,
          itemBuilder: (context, i) => FadeSlideIn(
            // Keyed by id: a newly arrived order animates in on its own.
            key: ValueKey(orders[i].id),
            index: i,
            child: _StaffOrderCard(order: orders[i]),
          ),
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

  /// Runs a status change; the card then leaves this tab via the live query.
  Future<void> _advance(
    Future<void> Function(OrderService, String id) change,
    String doneText,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<OrderService>();
    HapticFeedback.lightImpact();
    setState(() => _saving = true);
    try {
      await change(service, widget.order.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Order ${formatOrderNo(widget.order.orderNo)} $doneText',
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't update. It may have changed already."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AnimatedOpacity(
      opacity: _saving ? .5 : 1,
      duration: motionDuration(context, AppDurations.medium),
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs + 2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      formatOrderNo(order.orderNo),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    formatTime(order.isReady ? order.readyAt : order.createdAt),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${order.studentName} • ${order.studentId}',
                style: theme.textTheme.titleSmall,
              ),
              const Divider(height: AppSpacing.xl),
              for (final line in order.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${line.qty}× ${line.name}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Collect ${formatPeso(order.total)} cash',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (order.status == OrderStatus.pending)
                    FilledButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _advance(
                              (s, id) => s.markReady(id),
                              'marked ready',
                            ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Mark Ready'),
                    )
                  else if (order.status == OrderStatus.ready)
                    FilledButton.tonalIcon(
                      onPressed: _saving
                          ? null
                          : () => _advance(
                              (s, id) => s.markPickedUp(id),
                              'picked up',
                            ),
                      icon: const Icon(Icons.done_all_rounded),
                      label: const Text('Picked up'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
