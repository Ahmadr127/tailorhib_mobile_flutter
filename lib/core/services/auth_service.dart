import 'package:shared_preferences/shared_preferences.dart';
import '../routes/routes.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';
  static const String _userIdKey = 'user_id';

  static Future<void> saveAuthData(
      String token, String role, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);
    await prefs.setInt(_userIdKey, userId);
  }

  static Future<Map<String, dynamic>?> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final role = prefs.getString(_roleKey);
    final userId = prefs.getInt(_userIdKey);

    if (token != null && role != null && userId != null) {
      return {
        'token': token,
        'role': role,
        'userId': userId,
      };
    }
    return null;
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
  }

  static Future<String?> getInitialRoute() async {
    final authData = await getAuthData();
    if (authData != null) {
      return authData['role'] == 'pelanggan'
          ? AppRoutes.customerHome
          : AppRoutes.tailorHome;
    }
    return AppRoutes.login;
  }
}
