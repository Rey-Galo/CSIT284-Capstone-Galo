import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/order_service.dart';
import '../../state/cart_provider.dart';
import '../../state/student_provider.dart';
import '../../utils/format.dart';
import 'order_status_screen.dart';

/// Bottom sheet that asks for the student ID and name, then places the order.
class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({super.key});

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idCtrl;
  late final TextEditingController _nameCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final student = context.read<StudentProvider>();
    _idCtrl = TextEditingController(text: student.studentId ?? '');
    _nameCtrl = TextEditingController(text: student.studentName ?? '');
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final cart = context.read<CartProvider>();
    final student = context.read<StudentProvider>();
    final orders = context.read<OrderService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final studentId = _idCtrl.text.trim();
    final studentName = _nameCtrl.text.trim();

    setState(() => _submitting = true);
    try {
      final orderId = await orders.placeOrder(
        studentId: studentId,
        studentName: studentName,
        lines: cart.toOrderLines(),
      );
      await student.save(studentId, studentName);
      cart.clear();
      // Close the sheet and cart, then show the live order status.
      navigator.popUntil((route) => route.isFirst);
      navigator.push(
        MaterialPageRoute(builder: (_) => OrderStatusScreen(orderId: orderId)),
      );
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not place order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = context.watch<CartProvider>().total;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Checkout', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _idCtrl,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              maxLength: 20,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter your student ID'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 40,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Cash on pickup'),
                subtitle: Text(
                  'Pay ${formatPeso(total)} at the counter when you claim your order.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text('Confirm Order • ${formatPeso(total)}'),
            ),
          ],
        ),
      ),
    );
  }
}
