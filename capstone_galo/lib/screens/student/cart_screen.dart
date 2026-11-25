import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../services/order_service.dart';
import '../../state/cart_provider.dart';
import '../../state/student_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/menu_item_card.dart';
import '../../widgets/motion.dart';
import '../../widgets/qty_stepper.dart';
import '../../widgets/state_views.dart';
import 'order_status_screen.dart';
import 'student_home.dart';

/// "Payout": pickup info, who is ordering, the ordered dishes, the summary and
/// the Place Order button.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
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

  void _removeWithUndo(CartItem line) {
    final cart = context.read<CartProvider>();
    cart.remove(line.item.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed ${line.item.name}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cart.restore(line),
          ),
        ),
      );
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
      // Close the cart, then show the live order status.
      navigator.popUntil((route) => route.isFirst);
      navigator.push(
        MaterialPageRoute(builder: (_) => OrderStatusScreen(orderId: orderId)),
      );
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't place your order. Please try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final heading = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Payout'), centerTitle: true),
        body: AnimatedSwitcher(
          duration: motionDuration(context, AppDurations.medium),
          child: cart.isEmpty
              ? EmptyState(
                  key: const ValueKey('empty'),
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your cart is empty.',
                  message: 'Add a dish from the menu to get started.',
                  action: FilledButton.tonal(
                    onPressed: () {
                      // In the Cart tab there is no route to pop.
                      final home = StudentHome.maybeOf(context);
                      home == null
                          ? Navigator.pop(context)
                          : home.select(StudentHomeState.menuTab);
                    },
                    child: const Text('Browse menu'),
                  ),
                )
              : KeyedSubtree(
                  key: const ValueKey('list'),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      children: [
                        _Section(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainer,
                                  borderRadius: AppRadius.smAll,
                                ),
                                child: Icon(
                                  Icons.storefront_rounded,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pickup at the counter',
                                      style: heading,
                                    ),
                                    Text(
                                      'Pay cash when you claim your order.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Section(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Orderer', style: heading),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _idCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Student ID',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                maxLength: 20,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Enter your student ID'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                keyboardType: TextInputType.name,
                                autofillHints: const [AutofillHints.name],
                                maxLength: 40,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Enter your name'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        _Section(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: Text('Ordered menu', style: heading),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              for (final line in cart.items)
                                Dismissible(
                                  key: ValueKey('d-${line.item.id}'),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) => _removeWithUndo(line),
                                  background: Container(
                                    padding: const EdgeInsets.only(
                                      right: AppSpacing.xl,
                                    ),
                                    alignment: Alignment.centerRight,
                                    color: colors.errorContainer,
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      color: colors.onErrorContainer,
                                    ),
                                  ),
                                  child: _CartLine(line: line),
                                ),
                            ],
                          ),
                        ),
                        _Section(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Order Summary', style: heading),
                              const SizedBox(height: AppSpacing.md),
                              _SummaryRow(
                                label: 'Item total',
                                value: AnimatedPeso(
                                  cart.total,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _SummaryRow(
                                label: 'Payment',
                                value: Text(
                                  'Cash on pickup',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const Divider(height: 1),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Text('Total', style: heading),
                                  const Spacer(),
                                  PriceText(
                                    cart.total,
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: cart.isEmpty
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: AnimatedSwitcher(
                      duration: motionDuration(context, AppDurations.fast),
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Place Order'),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// White block on the grey page, one per Payout section.
class _Section extends StatelessWidget {
  const _Section({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    padding: padding,
    color: Theme.of(context).colorScheme.surfaceContainerLowest,
    child: child,
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        value,
      ],
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.line});

  final CartItem line;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          FoodThumbnail(
            line.item.imageUrl,
            size: 52,
            category: line.item.category,
            circle: true,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  line.item.category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: PriceText(line.subtotal),
              ),
              QtyStepper(
                qty: line.qty,
                onAdd: () => cart.add(line.item),
                onRemove: () => cart.decrement(line.item.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
