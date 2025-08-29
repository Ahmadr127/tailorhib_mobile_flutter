import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ForgotPasswordService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  // Service untuk forgot password customer
  Future<Map<String, dynamic>> forgotPasswordCustomer(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pelanggan/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final result = jsonDecode(response.body);
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Terjadi kesalahan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Service untuk reset password customer
  Future<Map<String, dynamic>> resetPasswordCustomer({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String pin,
  }) async {
    try {
      print(
          'DEBUG: Sending reset password request to: $baseUrl/pelanggan/reset-password');
      print('DEBUG: Request payload:');
      print(jsonEncode({
        'email': email,
        'password': '[HIDDEN]',
        'password_confirmation': '[HIDDEN]',
        'pin': pin,
      }));

      final response = await http.post(
        Uri.parse('$baseUrl/pelanggan/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'pin': pin,
        }),
      );

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      final result = jsonDecode(response.body);

      // Return semua informasi yang mungkin berguna
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Terjadi kesalahan',
        'data': result['data'],
        'errors': result['errors'],
        'status_code': response.statusCode,
        'raw_response': response.body,
      };
    } catch (e, stackTrace) {
      print('ERROR: Exception during reset password request: $e');
      print('ERROR: Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
        'errors': {'exception': e.toString()},
        'status_code': 500,
      };
    }
  }

  // Service untuk forgot password tailor
  Future<Map<String, dynamic>> forgotPasswordTailor(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/penjahit/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final result = jsonDecode(response.body);
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Terjadi kesalahan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Service untuk reset password tailor
  Future<Map<String, dynamic>> resetPasswordTailor({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/penjahit/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'pin': pin,
        }),
      );

      final result = jsonDecode(response.body);
      return {
        'success': result['success'] ?? false,
        'message': result['message'] ?? 'Terjadi kesalahan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
