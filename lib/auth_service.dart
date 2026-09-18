// lib/auth_service.dart
import 'models.dart';

class AuthService {
  static Map<String, Object?>? currentStaff;

  static bool get isManager =>
      (currentStaff?['role'] as String?) == StaffRole.manager.name;

  static int? get staffId => currentStaff?['id'] as int?;

  static void login(Map<String, Object?> staff) => currentStaff = staff;
  static void logout() => currentStaff = null;
}