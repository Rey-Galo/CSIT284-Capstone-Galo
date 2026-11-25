import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/config_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/motion.dart';
import 'staff_home_screen.dart';

class StaffPinScreen extends StatefulWidget {
  const StaffPinScreen({super.key});

  @override
  State<StaffPinScreen> createState() => _StaffPinScreenState();
}

class _StaffPinScreenState extends State<StaffPinScreen>
    with SingleTickerProviderStateMixin {
  final _pinCtrl = TextEditingController();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _wrong(String message) {
    HapticFeedback.heavyImpact();
    if (motionDuration(context, AppDurations.slow) != Duration.zero) {
      _shake.forward(from: 0);
    }
    setState(() {
      _checking = false;
      _error = message;
    });
  }

  Future<void> _submit() async {
    final config = context.read<ConfigService>();
    final navigator = Navigator.of(context);
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final ok = await config.verifyStaffPin(_pinCtrl.text);
      if (!mounted) return;
      if (ok) {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const StaffHomeScreen()),
        );
      } else {
        _wrong('Wrong PIN');
        _pinCtrl.clear();
      }
    } catch (_) {
      if (!mounted) return;
      _wrong("Couldn't check the PIN. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Mode')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: FadeSlideIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primaryContainer,
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 40,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Staff only', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter the staff PIN to manage orders and the menu.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AnimatedBuilder(
                  animation: _shake,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                      math.sin(_shake.value * math.pi * 6) *
                          12 *
                          (1 - _shake.value),
                      0,
                    ),
                    child: child,
                  ),
                  child: TextField(
                    controller: _pinCtrl,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    maxLength: 8,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _checking ? null : _submit(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: _checking ? null : _submit,
                  child: AnimatedSwitcher(
                    duration: motionDuration(context, AppDurations.fast),
                    child: _checking
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Enter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
