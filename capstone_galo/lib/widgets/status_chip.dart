import 'package:flutter/material.dart';

import '../models/canteen_order.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, fg, bg) = switch (status) {
      OrderStatus.pending => (
        Icons.hourglass_top,
        Colors.orange.shade900,
        Colors.amber.shade100,
      ),
      OrderStatus.ready => (
        Icons.check_circle,
        Colors.green.shade800,
        Colors.green.shade100,
      ),
      OrderStatus.pickedUp => (
        Icons.done_all,
        Colors.blueGrey.shade700,
        Colors.blueGrey.shade50,
      ),
      OrderStatus.cancelled => (
        Icons.cancel,
        Colors.red.shade800,
        Colors.red.shade50,
      ),
    };
    return Chip(
      avatar: Icon(icon, size: 18, color: fg),
      label: Text(status.label),
      labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
      backgroundColor: bg,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
