import 'package:flutter/material.dart';

class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: onRemove,
          icon: Icon(qty <= 1 ? Icons.delete_outline : Icons.remove),
          tooltip: qty <= 1 ? 'Remove' : 'Decrease',
          visualDensity: VisualDensity.compact,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton.filledTonal(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          tooltip: 'Increase',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
