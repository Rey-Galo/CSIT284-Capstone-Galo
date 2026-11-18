import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/menu_service.dart';
import 'state/student_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final student = StudentProvider();
  await student.load();
  runApp(CanteenApp(firestore: await _openDatabase(), student: student));
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
