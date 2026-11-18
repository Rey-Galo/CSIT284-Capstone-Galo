import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/config_service.dart';
import 'staff_home_screen.dart';

class StaffPinScreen extends StatefulWidget {
  const StaffPinScreen({super.key});

  @override
  State<StaffPinScreen> createState() => _StaffPinScreenState();
}

class _StaffPinScreenState extends State<StaffPinScreen> {
  final _pinCtrl = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
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
        setState(() {
          _checking = false;
          _error = 'Wrong PIN';
        });
        _pinCtrl.clear();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = 'Could not check PIN: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Mode')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter the staff PIN to manage orders and the menu.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pinCtrl,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 8,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'PIN',
                  errorText: _error,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _checking ? null : _submit,
                child: _checking
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Enter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
