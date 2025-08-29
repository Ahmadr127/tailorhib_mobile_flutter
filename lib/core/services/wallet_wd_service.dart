import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class WalletWDService {
  static final String baseUrl = ApiService.baseUrl;

  // Mendapatkan informasi wallet
  static Future<Map<String, dynamic>> getWalletInfo() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/wallet'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mendapatkan informasi wallet',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Mendapatkan daftar akun bank
  static Future<Map<String, dynamic>> getBankAccounts() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/bank-accounts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mendapatkan daftar akun bank',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Mendaftarkan akun bank baru
  static Future<Map<String, dynamic>> registerBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bank-accounts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'bank_name': bankName,
          'account_number': accountNumber,
          'account_holder_name': accountHolderName,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mendaftarkan akun bank',
        'errors': data['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Meminta penarikan dana
  static Future<Map<String, dynamic>> requestWithdrawal({
    required int bankAccountId,
    required double amount,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/withdrawals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'bank_account_id': bankAccountId,
          'amount': amount,
        }),
      );

      final data = json.decode(response.body);

      // Log respons untuk debugging
      print('requestWithdrawal response: ${response.body}');

      if (response.statusCode == 200) {
        // Pastikan kita mengembalikan data lengkap termasuk info wallet yang diperbarui
        return {
          'success': true,
          'data': data['data'], // Berisi 'withdrawal' dan 'wallet'
          'message': data['message'],
        };
      }

      // Handle untuk insufficient balance error
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal meminta penarikan dana',
        'errors': data['data'],
        'wallet_info': data['data'], // Mungkin berisi info wallet saat gagal
      };
    } catch (e) {
      print('requestWithdrawal error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Mendapatkan riwayat penarikan dana
  static Future<Map<String, dynamic>> getWithdrawalHistory({String? status}) async {
    try {
      print('Start getWithdrawalHistory - Status filter: $status');
      
      final token = await ApiService.getToken();
      if (token == null) {
        print('getWithdrawalHistory: Token tidak ditemukan');
        return {
          'success': false,
          'message': 'Token tidak ditemukan',
        };
      }

      // Build URL with query parameter if status is provided
      String url = '$baseUrl/withdrawals';
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }
      
      print('getWithdrawalHistory: URL request: $url');
      print('getWithdrawalHistory: Token: ${token.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('getWithdrawalHistory: Status code: ${response.statusCode}');
      print('getWithdrawalHistory: Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final result = {
          'success': true,
          'data': data['data'],
          'message': data['message'],
          'raw_response': response.body,  // Include raw response for debugging
        };
        
        print('getWithdrawalHistory: Success, data count: ${(data['data'] as List?)?.length ?? 0}');
        return result;
      }

      print('getWithdrawalHistory: Failed with message: ${data['message']}');
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mendapatkan riwayat penarikan',
        'raw_response': response.body,  // Include raw response for debugging
      };
    } catch (e, stackTrace) {
      print('getWithdrawalHistory: Exception: $e');
      print('getWithdrawalHistory: Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
        'error': e.toString(),
        'stack_trace': stackTrace.toString(),
      };
    }
  }
}
