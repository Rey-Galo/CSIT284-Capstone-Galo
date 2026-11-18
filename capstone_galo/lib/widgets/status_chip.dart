import 'package:flutter/material.dart';

import '../models/canteen_order.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final ready = status == OrderStatus.ready;
    final fg = ready ? Colors.green.shade800 : Colors.orange.shade900;
    return Chip(
      avatar: Icon(
        ready ? Icons.check_circle : Icons.hourglass_top,
        size: 18,
        color: fg,
      ),
      label: Text(status.label),
      labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
      backgroundColor: ready ? Colors.green.shade100 : Colors.amber.shade100,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
