import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_frame/device_frame.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/menu_service.dart';
import 'state/student_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final student = StudentProvider();
  await student.load();
  final app = CanteenApp(firestore: await _openDatabase(), student: student);
  // In the browser, show the app inside a phone frame (temporary, for demos).
  runApp(kIsWeb ? PhonePreview(child: app) : app);
}

/// Uses the real Firestore once `flutterfire configure` has generated
/// lib/firebase_options.dart. Until then (week 1) it falls back to an
/// in-memory database with the sample menu, so the app runs without Firebase.
/// Demo data is lost when the app restarts.
Future<FirebaseFirestore> _openDatabase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return FirebaseFirestore.instance;
  } on UnsupportedError {
    debugPrint('Firebase not configured: running with in-memory demo data.');
    final demo = FakeFirebaseFirestore();
    await MenuService(demo).seedSampleMenu();
    return demo;
  }
}

/// TEMPORARY: wraps the app in an Android phone frame so `flutter run -d chrome`
/// looks like an emulator. Remove this (and the device_frame dependency) when
/// it's no longer needed.
class PhonePreview extends StatelessWidget {
  const PhonePreview({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 29, 30, 31),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DeviceFrame(
              device: Devices.ios.iPhone16Pro,
              isFrameVisible: true,
              orientation: Orientation.portrait,
              screen: child,
            ),
          ),
        ),
      ),
    );
  }
}
