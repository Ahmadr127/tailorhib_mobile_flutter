import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class BookingService {
  // Mendapatkan daftar booking pelanggan
  static Future<Map<String, dynamic>> getCustomerBookings() async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      // Gunakan endpoint API untuk mendapatkan booking pelanggan
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/bookings/customer'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Customer bookings response status: ${response.statusCode}');
      print('DEBUG: Customer bookings response body: ${response.body.substring(0, min(200, response.body.length))}...');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Tampilkan debug untuk data booking
        if (data['data'] != null && data['data'] is List && data['data'].isNotEmpty) {
          print('DEBUG: First booking sample data:');
          print('DEBUG: ID: ${data['data'][0]['id']}');
          print('DEBUG: Status: ${data['data'][0]['status']}');
          print('DEBUG: Transaction Code: ${data['data'][0]['transaction_code']}');
          print('DEBUG: Payment Method: ${data['data'][0]['payment_method']}');
        }

        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Data booking berhasil diambil',
        };
      }

      final decodedResponse = jsonDecode(response.body);
      return {
        'success': false,
        'message': decodedResponse['message'] ?? 'Gagal memuat data booking',
      };
    } catch (e) {
      print('ERROR: Gagal memuat data booking pelanggan: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> createBooking({
    required int tailorId,
    required String appointmentDate,
    required String appointmentTime,
    required String serviceType,
    required String category,
    String notes = '',
    String paymentMethod = 'transfer_bank',
    File? image,
  }) async {
    try {
      print('DEBUG: Membuat booking baru melalui BookingService');
      print('DEBUG: Tailor ID: $tailorId');
      print('DEBUG: Tanggal: $appointmentDate');
      print('DEBUG: Waktu: $appointmentTime');
      print('DEBUG: Layanan: $serviceType');
      print('DEBUG: Kategori: $category');
      print('DEBUG: Catatan: $notes');
      print('DEBUG: Metode Pembayaran: $paymentMethod');
      print('DEBUG: Gambar: ${image != null ? 'Ada' : 'Tidak ada'}');

      final token = await ApiService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan',
        };
      }

      // Gunakan MultipartRequest untuk upload file
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/bookings'),
      );

      // Tambahkan headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Tambahkan fields
      request.fields['tailor_id'] = tailorId.toString();
      request.fields['appointment_date'] = appointmentDate;
      request.fields['appointment_time'] = appointmentTime;
      request.fields['service_type'] = serviceType;
      request.fields['category'] = category;
      request.fields['notes'] = notes;
      request.fields['payment_method'] = paymentMethod;

      // Tambahkan file foto jika ada
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'design_photo',
            image.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      final data = json.decode(response.body);

      // Menangani respons sukses
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Booking berhasil dibuat',
          'data': data['data'],
        };
      } 
      // Menangani respons gagal (termasuk jadwal tidak tersedia)
      else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal membuat booking',
          'data': data['data'],
          'status_code': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      print('ERROR: Gagal membuat booking: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> rateBooking(
      int bookingId, int rating, String review) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Unauthenticated: Token tidak ditemukan. Silakan login kembali.',
          'error_type': 'auth_error'
        };
      }

      print('DEBUG: Sending rating $rating for booking #$bookingId');
      print('DEBUG: Review text: $review');
      print(
          'DEBUG: API URL: ${ApiService.baseUrl}/bookings/$bookingId/rate');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/bookings/$bookingId/rate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rating': rating,
          'review': review,
        }),
      );

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      final data = json.decode(response.body);
      
      // Handle authentication errors
      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthenticated: Sesi login Anda telah berakhir. Silakan login kembali.',
          'error_type': 'auth_error'
        };
      }
      
      // Handle validation errors
      if (response.statusCode == 422) {
        return {
          'success': false,
          'message': data['message'] ?? 'Validasi gagal. Pastikan rating dan ulasan sudah benar.',
          'error_type': 'validation_error',
          'errors': data['errors']
        };
      }

      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message':
            data['message'] ?? 'Terjadi kesalahan saat memberikan rating',
        'data': data['data'],
      };
    } catch (e, stackTrace) {
      print('ERROR: Gagal memberikan rating: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> completeBooking(
    int bookingId,
    String completionNotes,
    String? completionPhoto,
    String? pickupDate,
  ) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan',
        };
      }

      print('DEBUG: Menyelesaikan booking #$bookingId');
      print('DEBUG: Completion notes: $completionNotes');
      print('DEBUG: Completion photo: $completionPhoto');
      print('DEBUG: Pickup date: $pickupDate');

      // Gunakan MultipartRequest untuk upload file
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/bookings/$bookingId/complete'),
      );

      // Tambahkan headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Tambahkan fields
      request.fields['completion_notes'] = completionNotes;
      if (pickupDate != null) {
        request.fields['pickup_date'] = pickupDate;
      }

      // Tambahkan file foto jika ada
      if (completionPhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'completion_photo',
            completionPhoto,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      final data = json.decode(response.body);

      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message':
            data['message'] ?? 'Terjadi kesalahan saat menyelesaikan pesanan',
        'data': data['data'],
      };
    } catch (e, stackTrace) {
      print('ERROR: Gagal menyelesaikan pesanan: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
