import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import 'api_service.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      AppLogger.info('Memuat data profil dari API', tag: 'Profile');

      // Gunakan ApiResponse untuk respons terstruktur
      final apiResponse = await ApiService.get('/profile');

      if (apiResponse.isSuccess) {
        AppLogger.info('Data profil berhasil dimuat', tag: 'Profile');
        return {
          'success': true,
          'data': apiResponse.data,
          'message': apiResponse.message,
        };
      } else {
        AppLogger.error('Gagal memuat profil: ${apiResponse.message}',
            tag: 'Profile');
        return {
          'success': false,
          'message': apiResponse.message,
        };
      }
    } catch (e) {
      AppLogger.error('Exception saat memuat profil', error: e, tag: 'Profile');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat memuat profil: $e',
      };
    }
  }

  /// Upload foto profil untuk user (pelanggan atau penjahit)
  /// Menggunakan endpoint: POST /profile/photo
  static Future<Map<String, dynamic>> uploadProfilePhoto(File photo) async {
    try {
      AppLogger.info('Mulai upload foto profil', tag: 'ProfilePhoto');
      AppLogger.debug('File path: ${photo.path}', tag: 'ProfilePhoto');

      // Pastikan file ada
      if (!photo.existsSync()) {
        AppLogger.error('File foto tidak ditemukan di path: ${photo.path}',
            tag: 'ProfilePhoto');
        return {
          'success': false,
          'message': 'File foto tidak ditemukan',
        };
      }

      // Dapatkan token untuk otorisasi
      final token = await ApiService.getToken();
      if (token == null) {
        AppLogger.error('Token tidak ditemukan, tidak dapat upload foto',
            tag: 'ProfilePhoto');
        return {
          'success': false,
          'message': 'Anda perlu login untuk mengupload foto profil',
        };
      }

      // Buat request multipart
      final uri = Uri.parse('${ApiService.baseUrl}/profile/photo');
      final request = http.MultipartRequest('POST', uri);

      // Tambahkan header otorisasi
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      AppLogger.debug('URL endpoint: $uri', tag: 'ProfilePhoto');
      AppLogger.debug('Headers: ${request.headers}', tag: 'ProfilePhoto');

      // Tambahkan file foto
      final fileName = photo.path.split('/').last;
      final fileStream = http.ByteStream(photo.openRead());
      final fileLength = await photo.length();

      AppLogger.debug('Nama file: $fileName', tag: 'ProfilePhoto');
      AppLogger.debug('Ukuran file: $fileLength bytes', tag: 'ProfilePhoto');

      final multipartFile = http.MultipartFile(
        'profile_photo', // nama field yang diharapkan oleh API
        fileStream,
        fileLength,
        filename: fileName,
      );

      request.files.add(multipartFile);

      // Kirim request
      AppLogger.info('Mengirim request upload foto profil',
          tag: 'ProfilePhoto');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      AppLogger.api(
          'Response status upload foto profil: ${response.statusCode}',
          tag: 'ProfilePhoto');
      AppLogger.api('Response body upload foto profil: ${response.body}',
          tag: 'ProfilePhoto');

      // Parse response
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        AppLogger.info('Foto profil berhasil diupload', tag: 'ProfilePhoto');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Foto profil berhasil diupload',
          'data': responseData['data'],
        };
      } else {
        AppLogger.error(
            'Gagal mengupload foto profil: ${responseData['message']}',
            tag: 'ProfilePhoto');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengupload foto profil',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      AppLogger.error('Exception saat upload foto profil',
          error: e, tag: 'ProfilePhoto');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Method helper untuk mendapatkan URL lengkap foto profil
  static String getFullProfilePhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return '';
    }

    return ApiService.getFullImageUrl(photoUrl);
  }

  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> userData) async {
    try {
      AppLogger.info('Memulai update profil', tag: 'ProfileService');
      AppLogger.debug('Data yang akan diupdate: $userData',
          tag: 'ProfileService');

      final token = await ApiService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      // Gunakan ApiService.baseUrl yang sudah terkonfigurasi
      final uri = Uri.parse('${ApiService.baseUrl}/profile');
      AppLogger.debug('URL: $uri', tag: 'ProfileService');
      AppLogger.debug('Token: $token', tag: 'ProfileService');

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(userData),
      );

      AppLogger.debug('Response status: ${response.statusCode}',
          tag: 'ProfileService');
      AppLogger.debug('Response body: ${response.body}', tag: 'ProfileService');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        AppLogger.info('Profil berhasil diperbarui', tag: 'ProfileService');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Profil berhasil diperbarui',
          'data': responseData['data'],
        };
      } else {
        final errorMessage =
            responseData['message'] ?? 'Gagal memperbarui profil';
        AppLogger.error('Gagal memperbarui profil: $errorMessage',
            tag: 'ProfileService');
        return {
          'success': false,
          'message': errorMessage,
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      AppLogger.error('Exception saat update profil',
          error: e, tag: 'ProfileService');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
