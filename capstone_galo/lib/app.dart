import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/student/menu_screen.dart';
import 'services/config_service.dart';
import 'services/menu_service.dart';
import 'services/order_service.dart';
import 'state/cart_provider.dart';
import 'state/student_provider.dart';

/// Root widget. Takes the Firestore instance as a parameter so tests can pass
/// a `FakeFirebaseFirestore`.
class CanteenApp extends StatelessWidget {
  const CanteenApp({
    super.key,
    required this.firestore,
    required this.student,
    this.isDemo = false,
  });

  final FirebaseFirestore firestore;
  final StudentProvider student;

  /// True when running on the in-memory demo database instead of Firebase.
  /// Shows a "DEMO DATA" corner banner so it's obvious which backend is live.
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => MenuService(firestore)),
        Provider(create: (_) => OrderService(firestore)),
        Provider(create: (_) => ConfigService(firestore)),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider.value(value: student),
      ],
      child: MaterialApp(
        title: 'Canteen Pre-Order',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: const MenuScreen(),
        builder: isDemo
            ? (context, child) => Banner(
                message: 'DEMO DATA',
                location: BannerLocation.topEnd,
                child: child!,
              )
            : null,
      ),
    );
  }
}
