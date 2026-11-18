import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the student ID and name on this device. There are no accounts:
/// the student ID is how a student finds their own orders.
class StudentProvider extends ChangeNotifier {
  static const _idKey = 'student_id';
  static const _nameKey = 'student_name';

  String? _studentId;
  String? _studentName;

  String? get studentId => _studentId;
  String? get studentName => _studentName;
  bool get hasStudent => _studentId != null && _studentId!.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _studentId = prefs.getString(_idKey);
    _studentName = prefs.getString(_nameKey);
    notifyListeners();
  }

  Future<void> save(String studentId, String studentName) async {
    _studentId = studentId;
    _studentName = studentName;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey, studentId);
    await prefs.setString(_nameKey, studentName);
  }
}
