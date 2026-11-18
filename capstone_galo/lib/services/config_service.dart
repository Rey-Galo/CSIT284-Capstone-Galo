import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigService {
  ConfigService(this._db);

  final FirebaseFirestore _db;

  /// Used until `config/app.staffPin` is set in the Firebase console.
  static const defaultStaffPin = '1234';

  /// Checks the staff PIN against `config/app.staffPin`.
  ///
  /// This is a client-side check meant for a demo: it keeps students out of the
  /// staff screens, but it is not real security.
  Future<bool> verifyStaffPin(String pin) async {
    final snap = await _db.collection('config').doc('app').get();
    final stored = snap.data()?['staffPin']?.toString() ?? defaultStaffPin;
    return pin.trim() == stored;
  }
}
