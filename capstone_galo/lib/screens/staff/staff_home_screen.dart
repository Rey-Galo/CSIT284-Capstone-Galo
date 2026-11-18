import 'package:flutter/material.dart';

import 'menu_manage_screen.dart';
import 'staff_orders_screen.dart';

/// Staff mode shell: bottom navigation between the order queue and the menu.
/// Pressing back (or the exit button) returns to the student menu.
class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [StaffOrdersScreen(), MenuManageScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}

/// App bar action that leaves staff mode.
class ExitStaffButton extends StatelessWidget {
  const ExitStaffButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Exit staff mode',
    icon: const Icon(Icons.logout),
    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
  );
}
