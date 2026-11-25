import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/canteen_order.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';
import '../../widgets/motion.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

/// Hero tag for an order's pickup number (shared with My Orders).
String orderHeroTag(String orderId) => 'order-no-$orderId';

/// Live status of one order. Updates by itself when staff mark it Ready.
class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  late Stream<CanteenOrder?> _order = _watch();

  bool _cancelling = false;
  OrderStatus? _lastStatus;

  Stream<CanteenOrder?> _watch() =>
      context.read<OrderService>().watchOrder(widget.orderId);

  Future<void> _cancel() async {
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<OrderService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cancel_outlined),
        title: const Text('Cancel this order?'),
        content: const Text('The canteen will stop preparing it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
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
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't cancel. It may already be ready."),
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  /// Buzz once when the order turns ready while this screen is open.
  void _onStatus(OrderStatus status) {
    if (_lastStatus != null &&
        _lastStatus != status &&
        status == OrderStatus.ready) {
      HapticFeedback.mediumImpact();
    }
    _lastStatus = status;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Order Status')),
      body: StreamBuilder<CanteenOrder?>(
        stream: _order,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorState(
              title: "Couldn't load your order",
              onRetry: () => setState(() => _order = _watch()),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const SkeletonList(count: 3, height: 120);
          }
          final order = snap.data;
          if (order == null) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Order not found.',
            );
          }
          _onStatus(order.status);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg + 4),
            children: [
              FadeSlideIn(child: _Ticket(order: order)),
              const SizedBox(height: AppSpacing.lg),
              FadeSlideIn(index: 1, child: _StatusBanner(order: order)),
              const SizedBox(height: AppSpacing.lg),
              FadeSlideIn(
                index: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        for (final line in order.items)
                          ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: colors.primaryContainer,
                              child: Text(
                                '${line.qty}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(
                              '${line.qty}× ${line.name}',
                              style: theme.textTheme.bodyLarge,
                            ),
                            trailing: Text(formatPeso(line.subtotal)),
                          ),
                        const Divider(indent: 16, endIndent: 16),
                        ListTile(
                          title: Text(
                            'Total (cash on pickup)',
                            style: theme.textTheme.titleMedium,
                          ),
                          trailing: Text(
                            formatPeso(order.total),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${order.studentName} • ${order.studentId}\nOrdered ${formatTime(order.createdAt)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonal(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Back to menu'),
              ),
              AnimatedSize(
                duration: motionDuration(context, AppDurations.medium),
                child: order.status == OrderStatus.pending
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: TextButton.icon(
                          onPressed: _cancelling ? null : _cancel,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel order'),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.error,
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Ticket-style card with the big pickup number, status and progress.
class _Ticket extends StatelessWidget {
  const _Ticket({required this.order});

  final CanteenOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            'Your pickup number',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: motionDuration(
              context,
              const Duration(milliseconds: 450),
            ),
            curve: AppCurves.pop,
            builder: (_, s, child) => Transform.scale(scale: s, child: child),
            child: Hero(
              tag: orderHeroTag(order.id),
              child: Material(
                type: MaterialType.transparency,
                child: FittedBox(
                  child: Text(
                    formatOrderNo(order.orderNo),
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StatusChip(order.status),
          if (order.status != OrderStatus.cancelled) ...[
            const SizedBox(height: AppSpacing.xl),
            _Tracker(status: order.status),
          ],
        ],
      ),
    );
  }
}

/// Placed → Preparing → Ready to claim, with an animated fill.
class _Tracker extends StatelessWidget {
  const _Tracker({required this.status});

  final OrderStatus status;

  static const _steps = [
    (Icons.receipt_rounded, 'Placed'),
    (Icons.soup_kitchen_rounded, 'Preparing'),
    (Icons.shopping_bag_rounded, 'Ready to claim'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final reached = switch (status) {
      OrderStatus.pending => 1,
      OrderStatus.ready || OrderStatus.pickedUp => 2,
      OrderStatus.cancelled => 0,
    };
    final d = motionDuration(context, const Duration(milliseconds: 500));

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: reached / 2),
          duration: d,
          curve: AppCurves.enter,
          builder: (_, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (final (i, (icon, label)) in _steps.indexed)
              Expanded(
                child: AnimatedOpacity(
                  opacity: i <= reached ? 1 : .45,
                  duration: d,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: d,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= reached
                              ? colors.primary
                              : colors.surfaceContainerHighest,
                        ),
                        child: Icon(
                          icon,
                          size: 18,
                          color: i <= reached
                              ? colors.onPrimary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusBanner extends StatefulWidget {
  const _StatusBanner({required this.order});

  final CanteenOrder order;

  @override
  State<_StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<_StatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(_StatusBanner old) {
    super.didUpdateWidget(old);
    final turnedReady =
        old.order.status != widget.order.status &&
        widget.order.status == OrderStatus.ready;
    if (turnedReady &&
        motionDuration(context, AppDurations.slow) != Duration.zero) {
      _pulseThreeTimes();
    }
  }

  /// A fixed number of pulses, never an endless loop.
  Future<void> _pulseThreeTimes() async {
    for (var i = 0; i < 3 && mounted; i++) {
      await _pulse.forward(from: 0);
      if (!mounted) return;
      await _pulse.reverse();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final (fg, bg) = StatusColors.read(context).of(order.status);
    final message = switch (order.status) {
      OrderStatus.pending =>
        'The canteen is preparing your order. This screen updates automatically when it is ready.',
      OrderStatus.ready =>
        'Your order is ready for pickup! Show your pickup number and pay ${formatPeso(order.total)} in cash at the counter.',
      OrderStatus.pickedUp => 'You picked up this order. Enjoy your meal!',
      OrderStatus.cancelled => 'This order was cancelled.',
    };
    final icon = switch (order.status) {
      OrderStatus.pending => Icons.soup_kitchen_rounded,
      OrderStatus.ready => Icons.notifications_active_rounded,
      OrderStatus.pickedUp => Icons.done_all_rounded,
      OrderStatus.cancelled => Icons.cancel_rounded,
    };
    final d = motionDuration(context, AppDurations.slow);

    return ScaleTransition(
      scale: Tween(
        begin: 1.0,
        end: 1.04,
      ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
      child: AnimatedContainer(
        duration: d,
        curve: AppCurves.enter,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.lgAll),
        child: AnimatedSwitcher(
          duration: d,
          child: Row(
            key: ValueKey(order.status),
            children: [
              Icon(icon, size: 36, color: fg),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
