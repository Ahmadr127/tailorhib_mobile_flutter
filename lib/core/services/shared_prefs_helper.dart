import 'package:shared_preferences/shared_preferences.dart';

/// Helper class untuk mengelola SharedPreferences dengan debugging yang lebih baik
class SharedPrefsHelper {
  static const String TOKEN_KEY = 'auth_token';

  /// Memeriksa apakah SharedPreferences berfungsi dengan benar
  static Future<bool> checkIfWorking() async {
    try {
      print('DEBUG: Memeriksa apakah SharedPreferences berfungsi...');

      // Coba mendapatkan instance
      final prefs = await SharedPreferences.getInstance();
      print('DEBUG: SharedPreferences instance berhasil dibuat');

      // Coba menyimpan test value
      final testKey = 'test_key_${DateTime.now().millisecondsSinceEpoch}';
      final testValue = 'test_value_${DateTime.now().millisecondsSinceEpoch}';

      final saveResult = await prefs.setString(testKey, testValue);
      print('DEBUG: Hasil menyimpan test key: $saveResult');

      if (!saveResult) {
        print('ERROR: Gagal menyimpan test key');
        return false;
      }

      // Coba membaca test value
      final retrievedValue = prefs.getString(testKey);
      print('DEBUG: Nilai yang dibaca: $retrievedValue');

      if (retrievedValue != testValue) {
        print(
            'ERROR: Nilai yang dibaca tidak sama dengan nilai yang disimpan!');
        return false;
      }

      // Coba menghapus test value
      final removeResult = await prefs.remove(testKey);
      print('DEBUG: Hasil menghapus test key: $removeResult');

      print('DEBUG: SharedPreferences berfungsi dengan baik!');
      return true;
    } catch (e) {
      print('ERROR KRITIS pada SharedPreferences: $e');
      return false;
    }
  }

  /// Mencoba memperbaiki SharedPreferences jika ada masalah
  static Future<bool> tryToFix() async {
    try {
      print('DEBUG: Mencoba memperbaiki SharedPreferences...');

      // Coba clear semua data dalam shared preferences
      final prefs = await SharedPreferences.getInstance();
      final clearResult = await prefs.clear();

      print('DEBUG: Clear SharedPreferences result: $clearResult');

      // Coba test lagi
      return await checkIfWorking();
    } catch (e) {
      print('ERROR: Gagal memperbaiki SharedPreferences: $e');
      return false;
    }
  }

  /// Solusi fallback jika shared preferences bermasalah
  static final Map<String, String> _memoryStorage = {};

  /// Menyimpan token ke memory jika shared preferences bermasalah
  static void saveTokenToMemory(String token) {
    _memoryStorage[TOKEN_KEY] = token;
    print('DEBUG: Token disimpan ke memory: ${token.substring(0, 10)}...');
  }

  /// Mengambil token dari memory jika shared preferences bermasalah
  static String? getTokenFromMemory() {
    final token = _memoryStorage[TOKEN_KEY];
    if (token != null) {
      print('DEBUG: Token diambil dari memory: ${token.substring(0, 10)}...');
    } else {
      print('DEBUG: Token tidak ditemukan di memory');
    }
    return token;
  }

  /// Menghapus token dari memory
  static void removeTokenFromMemory() {
    _memoryStorage.remove(TOKEN_KEY);
    print('DEBUG: Token dihapus dari memory');
  }
}
