import 'package:flutter/material.dart';

import '../models/canteen_order.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

IconData statusIcon(OrderStatus s) => switch (s) {
  OrderStatus.pending => Icons.hourglass_top_rounded,
  OrderStatus.ready => Icons.check_circle_rounded,
  OrderStatus.pickedUp => Icons.done_all_rounded,
  OrderStatus.cancelled => Icons.cancel_rounded,
};

/// Status pill. Colors animate when the status changes.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = StatusColors.read(context).of(status);
    final d = motionDuration(context, AppDurations.medium);
    return AnimatedContainer(
      duration: d,
      curve: AppCurves.enter,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: AnimatedSwitcher(
        duration: d,
        child: Row(
          key: ValueKey(status),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon(status), size: 16, color: fg),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              status.label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
