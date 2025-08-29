import 'dart:convert';
import 'dart:math';
import 'dart:async';  // Add this import for TimeoutException
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_prefs_helper.dart';
import 'dart:io';
import '../models/tailor_model.dart';
import '../models/gallery_model.dart';
import '../utils/logger.dart';
import '../utils/url_helper.dart';

class ApiService {
  // Gunakan env variable untuk base URL
  static String get baseUrl => UrlHelper.baseUrl;
  static String get imageBaseUrl => UrlHelper.imageBaseUrl;

  static bool _isInitialized = false;

  /// Initialize API Service and check if shared preferences is working
  static Future<void> init() async {
    if (_isInitialized) return;

    print('Initializing ApiService...');

    // Check if shared preferences is working
    final sharedPrefsWorking = await SharedPrefsHelper.checkIfWorking();

    if (!sharedPrefsWorking) {
      print('WARNING: SharedPreferences tidak berfungsi dengan baik!');
      print('Mencoba memperbaiki SharedPreferences...');

      final fixed = await SharedPrefsHelper.tryToFix();

      if (fixed) {
        print('SharedPreferences berhasil diperbaiki');
      } else {
        print('PERINGATAN PENTING: SharedPreferences masih bermasalah!');
        print('Aplikasi akan menggunakan penyimpanan memory sebagai fallback');
      }
    } else {
      print('SharedPreferences berfungsi dengan baik');
    }

    _isInitialized = true;
  }

  // Mendapatkan token dari shared preferences
  static Future<String?> getToken() async {
    try {
      print('DEBUG: Mencoba mendapatkan token dari SharedPreferences...');

      final prefs = await SharedPreferences.getInstance();
      print('DEBUG: SharedPreferences instance berhasil dibuat');

      final token = prefs.getString('auth_token');
      print(
          'DEBUG: Hasil membaca auth_token: ${token == null ? "null" : "ditemukan"}');

      if (token == null) {
        print('getToken: Token tidak ditemukan di SharedPreferences');

        // Coba ambil dari memory storage sebagai fallback
        print('DEBUG: Mencoba mendapatkan token dari memory storage...');
        final memoryToken = SharedPrefsHelper.getTokenFromMemory();
        if (memoryToken != null) {
          print('DEBUG: Token ditemukan di memory storage');
          return memoryToken;
        }
      } else {
        if (token.length > 10) {
          print('getToken: Token ditemukan: ${token.substring(0, 10)}...');
        } else {
          print('getToken: Token ditemukan terlalu pendek: $token');
        }
      }

      return token;
    } catch (e) {
      print('ERROR KRITIS saat mengambil token: $e');
      print('ERROR STACK TRACE: ${StackTrace.current}');

      // Jika error, coba dapatkan dari memory storage
      return SharedPrefsHelper.getTokenFromMemory();
    }
  }

  // Menyimpan token ke shared preferences
  static Future<void> saveToken(String token) async {
    if (token.isEmpty) {
      print('ERROR: Mencoba menyimpan token kosong! Operasi dibatalkan');
      return;
    }

    // Simpan ke memory storage sebagai backup
    SharedPrefsHelper.saveTokenToMemory(token);

    try {
      print('DEBUG: Mencoba menyimpan token ke SharedPreferences...');

      print(
          'DEBUG: Token yang akan disimpan (10 karakter pertama): ${token.substring(0, min(10, token.length))}');

      final prefs = await SharedPreferences.getInstance();
      print(
          'DEBUG: SharedPreferences instance berhasil dibuat untuk saveToken');

      final result = await prefs.setString('auth_token', token);
      print('DEBUG: Hasil dari setString: $result');

      if (result) {
        print(
            'Token berhasil disimpan: ${token.substring(0, min(10, token.length))}...');
      } else {
        print(
            'WARNING: Token mungkin gagal disimpan, hasil setString: $result');

        // Coba verifikasi penyimpanan token
        final isWorking = await SharedPrefsHelper.checkIfWorking();
        if (!isWorking) {
          print(
              'DEBUG: SharedPreferences tidak berfungsi dengan baik, mencoba memperbaiki...');
          await SharedPrefsHelper.tryToFix();

          // Coba simpan token lagi setelah perbaikan
          final prefs = await SharedPreferences.getInstance();
          final retryResult = await prefs.setString('auth_token', token);
          print('DEBUG: Hasil menyimpan token setelah perbaikan: $retryResult');
        }
      }

      // Verifikasi token setelah disimpan
      final savedToken = prefs.getString('auth_token');
      if (savedToken == null) {
        print(
            'ERROR: Verifikasi gagal - token tidak ditemukan setelah disimpan!');
      } else {
        print('DEBUG: Verifikasi berhasil - token ditemukan setelah disimpan');
      }
    } catch (e) {
      print('ERROR KRITIS saat menyimpan token: $e');
      print('ERROR STACK TRACE: ${StackTrace.current}');
      print(
          'Catatan: Token tetap tersimpan di memory storage sebagai fallback');
    }
  }

  // Menghapus token saat logout
  static Future<void> removeToken() async {
    try {
      // Hapus dari memory storage
      SharedPrefsHelper.removeTokenFromMemory();

      print('DEBUG: Mencoba menghapus token dari SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove('auth_token');

      if (result) {
        print('Token autentikasi berhasil dihapus dari SharedPreferences');
      } else {
        print('WARNING: Gagal menghapus token dari SharedPreferences');
      }

      // Verifikasi penghapusan
      final tokenAfterRemoval = prefs.getString('auth_token');
      if (tokenAfterRemoval != null) {
        print('ERROR: Token masih ada di SharedPreferences setelah dihapus!');
      } else {
        print('DEBUG: Verifikasi penghapusan berhasil');
      }
    } catch (e) {
      print('ERROR KRITIS saat menghapus token: $e');
      print('ERROR STACK TRACE: ${StackTrace.current}');
    }
  }

  // Fungsi untuk logout dari API dan menghapus token lokal
  static Future<Map<String, dynamic>> logout() async {
    try {
      // Remove token from shared preferences
      await removeToken();

      return {'success': true, 'message': 'Berhasil logout'};

      // Uncomment bagian berikut jika endpoint logout API sudah tersedia
      /*
      // Get token from shared preferences
      final token = await getToken();
      
      if (token == null) {
        return {
          'success': true,
          'message': 'Berhasil logout (tanpa API call, tidak ada token)'
        };
      }
      
      // Setup headers
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      
      // Make API call to logout endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: headers,
      );
      
      // Remove token anyway, regardless of API response
      await removeToken();
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Berhasil logout'
        };
      } else {
        return {
          'success': true, // Still return success as we've removed the token locally
          'message': 'Berhasil logout (API error: ${response.statusCode})'
        };
      }
      */
    } catch (e) {
      print('Error during logout: $e');
      // Still try to remove the token even if there's an error
      await removeToken();

      return {
        'success':
            true, // Still return success as we've tried our best to logout
        'message': 'Berhasil logout (dengan error: $e)'
      };
    }
  }

  // Mendapatkan semua spesialisasi
  static Future<List<Map<String, dynamic>>> getSpecializations() async {
    try {
      print('Fetching specializations from $baseUrl/specializations/all');

      final response = await http.get(
        Uri.parse('$baseUrl/specializations/all'),
        headers: {
          'Accept': 'application/json',
        },
      );

      print('Specializations response status: ${response.statusCode}');
      if (response.body.length > 500) {
        print(
            'Specializations response body (truncated): ${response.body.substring(0, 500)}...');
      } else {
        print('Specializations response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Handle the actual API response structure which uses 'status' instead of 'success'
        if ((data['status'] == 'success' || data['success'] == true) &&
            data.containsKey('data')) {
          final Map<String, dynamic> categoriesMap = data['data'];
          List<Map<String, dynamic>> allSpecializations = [];

          print('Processing categories: ${categoriesMap.keys.join(", ")}');

          categoriesMap.forEach((category, specializations) {
            if (specializations is List) {
              for (var spec in specializations) {
                if (spec is Map<String, dynamic>) {
                  // Create a mutable copy of the specialization
                  Map<String, dynamic> specCopy =
                      Map<String, dynamic>.from(spec);

                  // Add category to the specialization data
                  specCopy['category'] = category;

                  // Process photo URL
                  if (specCopy.containsKey('photo') &&
                      specCopy['photo'] != null) {
                    String photoPath = specCopy['photo'] as String;
                    print(
                        'Original photo path for ${specCopy['name']}: $photoPath');

                    // Create full URL for photo - Force HTTPS
                    String fullUrl = '';
                    if (photoPath.startsWith('http://') ||
                        photoPath.startsWith('https://')) {
                      // Already a complete URL
                      fullUrl = photoPath;
                    } else {
                      // Need to construct URL
                      if (photoPath.startsWith('/')) {
                        fullUrl = '$imageBaseUrl$photoPath';
                      } else {
                        fullUrl = '$imageBaseUrl/$photoPath';
                      }
                    }

                    specCopy['fullPhotoUrl'] = fullUrl;
                    print('Generated image URL: ${specCopy['fullPhotoUrl']}');
                  } else {
                    print('No photo found for ${specCopy['name']}');
                    // Set a default fallback image URL
                    specCopy['fullPhotoUrl'] = null;
                  }

                  allSpecializations.add(specCopy);
                }
              }
            }
          });

          print(
              'Found ${allSpecializations.length} specializations from all categories');

          if (allSpecializations.isNotEmpty) {
            // Print one example to debug
            if (allSpecializations.isNotEmpty) {
              final example = allSpecializations.first;
              print('Example specialization:');
              print('  Name: ${example['name']}');
              print('  Photo: ${example['photo']}');
              print('  FullPhotoUrl: ${example['fullPhotoUrl']}');
              print('  Category: ${example['category']}');
            }

            return allSpecializations;
          }
        }
      }

      print('No specializations found or invalid response structure');
      // Jika tidak ada data yang valid, kembalikan data dummy untuk testing
      return [
        {
          'id': 1,
          'name': 'Celana',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 2,
          'name': 'Rok',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 3,
          'name': 'Kemeja',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 4,
          'name': 'Seragam',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 5,
          'name': 'Jas Blazer',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 6,
          'name': 'Kebaya',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 7,
          'name': 'Gaun',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 8,
          'name': 'Gamis',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
      ];
    } catch (e) {
      print('Error getting specializations: $e');
      print('Error stack trace: ${StackTrace.current}');
      // Kembalikan data dummy jika terjadi error
      return [
        {
          'id': 1,
          'name': 'Celana',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 2,
          'name': 'Rok',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 3,
          'name': 'Kemeja',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 4,
          'name': 'Seragam',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 5,
          'name': 'Jas Blazer',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 6,
          'name': 'Kebaya',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 7,
          'name': 'Gaun',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
        {
          'id': 8,
          'name': 'Gamis',
          'category': 'Jenis Pakaian',
          'photo': null,
          'fullPhotoUrl': null
        },
      ];
    }
  }

  // Register tailor
  static Future<Map<String, dynamic>> registerTailor({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phoneNumber,
    required String address,
    double? latitude,
    double? longitude,
    String? shopDescription,
    required List<int> specializations,
  }) async {
    try {
      // Pastikan parameter shopDescription tidak null
      final String shopDesc = shopDescription?.trim() ?? '';

      // Pastikan specializations tidak kosong
      if (specializations.isEmpty) {
        print('Tidak ada spesialisasi yang dipilih');
        return {
          'success': false,
          'message': 'Pilih minimal satu spesialisasi',
        };
      }

      // Data untuk dikirim ke API
      final Map<String, dynamic> requestData = {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'phone_number': phoneNumber,
        'address': address,
        'shop_description': shopDesc,
        'specializations': specializations,
      };

      // Tambahkan koordinat lokasi jika ada
      if (latitude != null) {
        requestData['latitude'] = latitude;
      }

      if (longitude != null) {
        requestData['longitude'] = longitude;
      }

      print('Registering tailor with data: ${json.encode(requestData)}');

      // Create HTTP client with timeout
      final client = http.Client();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/penjahit/register'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(requestData),
        ).timeout(
          const Duration(seconds: 30), // Increased timeout to 30 seconds
          onTimeout: () {
            client.close();
            throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
          },
        );

        print('Registration response status code: ${response.statusCode}');
        print('Registration response body: ${response.body}');

        // Parse response body
        Map<String, dynamic> responseData;
        try {
          responseData = json.decode(response.body);
        } catch (e) {
          print('Error decoding response: $e');
          return {
            'success': false,
            'message': 'Gagal membaca respons server',
          };
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Cek lokasi token dalam respons
          String? token;
          if (responseData.containsKey('token')) {
            token = responseData['token'];
          } else if (responseData.containsKey('data') &&
              responseData['data'] is Map) {
            final data = responseData['data'] as Map<String, dynamic>;
            if (data.containsKey('token')) {
              token = data['token'];
            } else if (data.containsKey('access_token')) {
              token = data['access_token'];
            }
          }

          // Simpan token jika ditemukan
          if (token != null && token.isNotEmpty) {
            await saveToken(token);
            print('Token saved: $token');
          } else {
            print('No token found in response');
            print('Response structure: ${responseData.keys.join(', ')}');
          }

          return {
            'success': true,
            'message': responseData['message'] ?? 'Registrasi berhasil',
            'data': responseData['data'],
            'token': token,
          };
        } else {
          print('Registration failed with status code: ${response.statusCode}');

          // Buat pesan error yang lebih informatif
          String errorMessage = responseData['message'] ?? 'Registrasi gagal';
          if (responseData.containsKey('errors')) {
            try {
              final errors = responseData['errors'] as Map<String, dynamic>;
              errorMessage = errors.values
                  .map((e) => e is List ? e.first : e.toString())
                  .join('\n');
            } catch (e) {
              print('Error processing error messages: $e');
            }
          }

          return {
            'success': false,
            'message': errorMessage,
            'errors': responseData['errors'],
          };
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print('Error during registration: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Login tailor
  static Future<Map<String, dynamic>> loginTailor({
    required String email,
    required String password,
  }) async {
    try {
      print('Logging in tailor with email: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/penjahit/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Tailor login response status: ${response.statusCode}');
      print('Tailor login response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      // Log struktur respon untuk debugging
      print('DEBUG API: Login response keys: ${responseData.keys.join(', ')}');

      // Cek apakah ada data user dalam respon
      if (responseData.containsKey('data') && responseData['data'] is Map) {
        final dataMap = responseData['data'] as Map<String, dynamic>;
        print('DEBUG API: Content of data: ${dataMap.keys.join(', ')}');

        if (dataMap.containsKey('user') && dataMap['user'] is Map) {
          final userData = dataMap['user'] as Map<String, dynamic>;
          print('DEBUG API: User data keys: ${userData.keys.join(', ')}');

          // Cek jika ada profile_photo dalam data user
          if (userData.containsKey('profile_photo')) {
            print(
                'DEBUG API: Profile photo in response: ${userData['profile_photo']}');
          } else {
            print('DEBUG API: No profile_photo in user data');
          }
        }
      }

      String? token;

      if (response.statusCode == 200) {
        // Cek berbagai kemungkinan lokasi token dalam respons
        if (responseData.containsKey('token')) {
          token = responseData['token'];
        } else if (responseData.containsKey('data') &&
            responseData['data'] is Map) {
          final data = responseData['data'] as Map<String, dynamic>;
          if (data.containsKey('token')) {
            token = data['token'];
          } else if (data.containsKey('access_token')) {
            token = data['access_token'];
          }

          // Jika masih belum ada token, buat token sementara dari ID pengguna jika tersedia
          if (token == null &&
              data.containsKey('user') &&
              data['user'] is Map) {
            final user = data['user'] as Map<String, dynamic>;
            if (user.containsKey('id')) {
              // Buat pseudo-token berdasarkan ID dan email pengguna sebagai fallback
              print(
                  'Membuat pseudo-token lokal dari ID pengguna karena token tidak ditemukan dalam respons');
              token =
                  'pseudo_token_${user['id']}_${DateTime.now().millisecondsSinceEpoch}';
            }
          }
        }

        // Simpan token jika ditemukan
        if (token != null && token.isNotEmpty) {
          await saveToken(token);
          print('Tailor token saved: $token');
        } else {
          print('WARNING: Tidak ada token dalam respons API login penjahit');
          print('Respons struktur: ${responseData.keys.join(', ')}');
        }

        return {
          'success': true,
          'message': responseData['message'] ?? 'Login berhasil',
          'user': _processUserDataWithCompleteUrls(
              responseData.containsKey('data') && responseData['data'] is Map
                  ? (responseData['data'] as Map).containsKey('user')
                      ? (responseData['data'] as Map)['user']
                      : responseData['data']
                  : responseData['user'] ?? {}),
          'token': token,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      print('Error during tailor login: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Login customer
  static Future<Map<String, dynamic>> loginCustomer({
    required String email,
    required String password,
  }) async {
    try {
      print('Logging in customer with email: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/pelanggan/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Customer login response status: ${response.statusCode}');
      print('Customer login response body: ${response.body}');

      // Pastikan selalu parse respons JSON terlebih dahulu
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      // Simpan respons lengkap untuk debugging
      final fullResponse = {
        'success': response.statusCode == 200,
        'status_code': response.statusCode,
        'message': responseData['message'] ?? 'Login gagal',
        'response_body': response.body,
        'data': responseData.containsKey('data') ? responseData['data'] : null,
      };
      
      print('DEBUG API: Respons login full data: $fullResponse');

      String? token;

      if (response.statusCode == 200) {
        // Cek berbagai kemungkinan lokasi token dalam respons
        if (responseData.containsKey('token')) {
          token = responseData['token'];
        } else if (responseData.containsKey('data') &&
            responseData['data'] is Map) {
          final data = responseData['data'] as Map<String, dynamic>;
          if (data.containsKey('token')) {
            token = data['token'];
          } else if (data.containsKey('access_token')) {
            token = data['access_token'];
          }

          // Jika masih belum ada token, buat token sementara dari ID pengguna jika tersedia
          if (token == null &&
              data.containsKey('user') &&
              data['user'] is Map) {
            final user = data['user'] as Map<String, dynamic>;
            if (user.containsKey('id')) {
              // Buat pseudo-token berdasarkan ID dan email pengguna sebagai fallback
              print(
                  'Membuat pseudo-token lokal dari ID pengguna karena token tidak ditemukan dalam respons');
              token =
                  'pseudo_token_${user['id']}_${DateTime.now().millisecondsSinceEpoch}';
            }
          }
        }

        // Simpan token jika ditemukan
        if (token != null && token.isNotEmpty) {
          await saveToken(token);
          print('Customer token saved: $token');
        } else {
          print('No token found in response for customer registration');
          print('Response structure: ${responseData.keys.join(', ')}');
        }

        return {
          'success': true,
          'message': responseData['message'] ?? 'Login berhasil',
          'user': _processUserDataWithCompleteUrls(
              responseData.containsKey('data') && responseData['data'] is Map
                  ? (responseData['data'] as Map).containsKey('user')
                      ? (responseData['data'] as Map)['user']
                      : responseData['data']
                  : responseData['user'] ?? {}),
          'token': token,
        };
      } else {
        // Untuk respons error, pastikan menyertakan data error dengan lengkap
        return fullResponse;
      }
    } catch (e) {
      print('Error during customer login: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Register customer
  static Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
    double? latitude,
    double? longitude,
    required List<int> preferredSpecializations,
  }) async {
    try {
      // Double-check: log nilai koordinat sebelum mengirim API call
      print('Final koordinat lokasi akan dikirimkan ke server:');
      print('Latitude: $latitude');
      print('Longitude: $longitude');

      // Validasi data dasar
      if (preferredSpecializations.isEmpty) {
        print('Tidak ada spesialisasi yang dipilih');
        return {
          'success': false,
          'message': 'Pilih minimal satu spesialisasi',
        };
      }

      // Validasi latitude dan longitude - keduanya harus ada atau keduanya tidak ada
      if ((latitude == null && longitude != null) ||
          (latitude != null && longitude == null)) {
        print('Latitude dan longitude harus diisi keduanya');
        return {
          'success': false,
          'message': 'Latitude dan longitude harus diisi keduanya',
          'errors': {
            'location': 'Lokasi tidak lengkap, harap isi latitude dan longitude'
          }
        };
      }

      // Data untuk dikirim ke API
      final Map<String, dynamic> requestData = {
        'name': name,
        'email': email,
        'password': password,
        'phone_number': phoneNumber,
        'address': address,
        'preferred_specializations': preferredSpecializations,
      };

      // Tambahkan koordinat lokasi jika ada
      if (latitude != null) {
        requestData['latitude'] = latitude;
      }

      if (longitude != null) {
        requestData['longitude'] = longitude;
      }

      print('Registering customer with data: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/pelanggan/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      );

      print(
          'Customer registration response status code: ${response.statusCode}');
      print('Customer registration response body: ${response.body}');

      // Parse response body
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print('Error decoding response: $e');
        return {
          'success': false,
          'message': 'Gagal membaca respons server',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Cek lokasi token dalam respons
        String? token;
        if (responseData.containsKey('token')) {
          token = responseData['token'];
        } else if (responseData.containsKey('data') &&
            responseData['data'] is Map) {
          final data = responseData['data'] as Map<String, dynamic>;
          if (data.containsKey('token')) {
            token = data['token'];
          } else if (data.containsKey('access_token')) {
            token = data['access_token'];
          }
        }

        // Simpan token jika ditemukan
        if (token != null && token.isNotEmpty) {
          await saveToken(token);
          print('Customer token saved: $token');
        } else {
          print('No token found in response for customer registration');
          print('Response structure: ${responseData.keys.join(', ')}');
        }

        return {
          'success': true,
          'message': responseData['message'] ?? 'Registrasi berhasil',
          'data': responseData['data'],
          'token': token,
        };
      } else {
        print(
            'Customer registration failed with status code: ${response.statusCode}');

        // Buat pesan error yang lebih informatif
        String errorMessage = responseData['message'] ?? 'Registrasi gagal';
        Map<String, dynamic> errorMap = {};

        // Cek format errornya, ada dua kemungkinan:
        // 1. errors ada di level utama: {"success":false, "message":"Error", "errors":{...}}
        // 2. errors ada di dalam data: {"success":false, "message":"Error", "data":{...}}
        if (responseData.containsKey('errors') &&
            responseData['errors'] != null) {
          try {
            // Format 1
            errorMap = responseData['errors'] as Map<String, dynamic>;
          } catch (e) {
            print('Error processing error messages from errors field: $e');
          }
        } else if (responseData.containsKey('data') &&
            responseData['data'] != null) {
          try {
            // Format 2 - server menyimpan error di field 'data'
            errorMap = responseData['data'] as Map<String, dynamic>;
          } catch (e) {
            print('Error processing error messages from data field: $e');
          }
        }

        // Jika berhasil mendapat map error
        if (errorMap.isNotEmpty) {
          return {
            'success': false,
            'message': errorMessage,
            'errors': errorMap,
          };
        } else {
          // Jika tidak bisa mendapatkan detail error
          return {
            'success': false,
            'message': errorMessage,
          };
        }
      }
    } catch (e) {
      print('Error during customer registration: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Metode diagnostik untuk memeriksa status token
  static Future<Map<String, dynamic>> checkTokenStatus() async {
    try {
      final result = <String, dynamic>{
        'sharedPrefsWorking': false,
        'tokenInSharedPrefs': false,
        'tokenInMemory': false,
        'tokenValue': null,
        'memoryTokenValue': null,
        'error': null,
      };

      // Periksa shared preferences
      try {
        final prefs = await SharedPreferences.getInstance();
        result['sharedPrefsWorking'] = true;

        final token = prefs.getString('auth_token');
        result['tokenInSharedPrefs'] = token != null;

        if (token != null && token.isNotEmpty) {
          result['tokenValue'] =
              token.length > 10 ? "${token.substring(0, 10)}..." : token;
        }
      } catch (e) {
        result['error'] = 'Error SharedPreferences: $e';
      }

      // Periksa memory storage
      final memoryToken = SharedPrefsHelper.getTokenFromMemory();
      result['tokenInMemory'] = memoryToken != null;

      if (memoryToken != null && memoryToken.isNotEmpty) {
        result['memoryTokenValue'] = memoryToken.length > 10
            ? "${memoryToken.substring(0, 10)}..."
            : memoryToken;
      }

      print('DEBUG: Token status: $result');
      return result;
    } catch (e) {
      print('ERROR saat memeriksa status token: $e');
      return {
        'sharedPrefsWorking': false,
        'tokenInSharedPrefs': false,
        'tokenInMemory': false,
        'error': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Upload foto profil untuk user (pelanggan atau penjahit)
  static Future<Map<String, dynamic>> uploadProfilePhoto(
    File photo,
  ) async {
    try {
      print('DEBUG: Mencoba upload foto profil...');
      print('DEBUG: File path: ${photo.path}');
      print('DEBUG: File exists: ${photo.existsSync()}');

      // Pastikan file ada
      if (!photo.existsSync()) {
        print('ERROR: File foto tidak ditemukan di: ${photo.path}');
        return {
          'success': false,
          'message': 'File foto tidak ditemukan',
        };
      }

      // Dapatkan token untuk otorisasi
      final token = await getToken();
      if (token == null) {
        print('ERROR: Token tidak ditemukan, tidak dapat upload foto');
        return {
          'success': false,
          'message': 'Anda perlu login untuk mengupload foto profil',
        };
      }

      print('DEBUG: Token ditemukan, panjang: ${token.length}');

      // Buat request multipart
      final uri = Uri.parse('$baseUrl/profile/photo');
      final request = http.MultipartRequest('POST', uri);

      // Tambahkan header otorisasi
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      print('DEBUG: Headers yang dikirim: ${request.headers}');

      // Tambahkan file foto
      final fileName = photo.path.split('/').last;
      final fileStream = http.ByteStream(photo.openRead());
      final fileLength = await photo.length();

      print('DEBUG: Filename yang dikirim: $fileName');
      print('DEBUG: Ukuran file: $fileLength bytes');

      final multipartFile = http.MultipartFile(
        'profile_photo', // nama field di API
        fileStream,
        fileLength,
        filename: fileName,
      );

      request.files.add(multipartFile);
      print('DEBUG: Field name yang digunakan: ${multipartFile.field}');
      print('DEBUG: Total files dalam request: ${request.files.length}');

      // Kirim request
      print('DEBUG: Mengirim request upload foto profil ke $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload foto profil status: ${response.statusCode}');
      print('Upload foto profil response: ${response.body}');

      // Parse response
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Foto profil berhasil diupload',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengupload foto profil',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      print('ERROR saat upload foto profil: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Menambahkan item galeri penjahit
  static Future<Map<String, dynamic>> addTailorGalleryItem({
    required File photo,
    required String title,
    required String description,
    required String category,
  }) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/penjahit/gallery'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add text fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['category'] = category;

      // Add file
      var pic = await http.MultipartFile.fromPath('photo', photo.path);
      request.files.add(pic);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Add Gallery Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Berhasil menambahkan foto ke galeri',
          'data': data['data']
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menambahkan foto ke galeri',
        };
      }
    } catch (e) {
      print('Error addTailorGalleryItem: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Menghapus item galeri penjahit
  static Future<Map<String, dynamic>> deleteTailorGalleryItem(int id) async {
    try {
      final token = await getToken();

      if (token == null) {
        print('ERROR: Token tidak ditemukan saat menghapus galeri');
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      final uri = Uri.parse('$baseUrl/penjahit/gallery/$id');
      print('DEBUG: Mengirim permintaan hapus galeri ke $uri');

      final response = await http.delete(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          'Delete Gallery Response (Status: ${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Berhasil menghapus foto dari galeri',
          'id': id,
        };
      } else {
        // Parse response sebagai JSON jika mungkin
        Map<String, dynamic> data;
        try {
          data = json.decode(response.body);
        } catch (e) {
          data = {
            'message': 'Tidak dapat parse response: ${response.body}',
            'raw_response': response.body,
          };
        }

        final message = data['message'] ?? 'Gagal menghapus foto dari galeri';

        // Cek jika error adalah "Not Found" maka mungkin masalahnya di ID
        if (response.statusCode == 404 ||
            message.toString().contains('No query results')) {
          print('INFO: Item dengan ID $id tidak ditemukan di server');
          return {
            'success': false,
            'message': 'Item dengan ID $id tidak ditemukan',
            'error_type': 'not_found',
            'id': id,
          };
        }

        return {
          'success': false,
          'message': message,
          'status_code': response.statusCode,
          'id': id,
        };
      }
    } catch (e) {
      print('Error deleteTailorGalleryItem untuk ID $id: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
        'id': id,
      };
    }
  }

  /// Mendapatkan daftar galeri penjahit
  static Future<Map<String, dynamic>> getTailorGallery() async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/penjahit/gallery'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get Gallery Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Pastikan URL gambar lengkap dengan base URL
        if (data['data'] != null && data['data'] is List) {
          for (var item in data['data']) {
            if (item is Map<String, dynamic> && item.containsKey('photo')) {
              // Gunakan utility method untuk mendapatkan URL lengkap
              String photoPath = item['photo'] as String;
              item['full_photo_url'] = getFullImageUrl(photoPath);
              print('Generated full photo URL: ${item['full_photo_url']}');
            }
          }
        }

        return {
          'success': true,
          'message': 'Berhasil mendapatkan data galeri',
          'data': data['data']
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mendapatkan data galeri',
        };
      }
    } catch (e) {
      print('Error getTailorGallery: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Mengupdate item galeri penjahit
  static Future<Map<String, dynamic>> updateTailorGalleryItem({
    required int id,
    required String title,
    required String description,
    required String category,
    File? photo,
  }) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      // Create multipart request if photo is provided, otherwise use normal PUT request
      if (photo != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/penjahit/gallery/$id'),
        );

        // Add headers
        request.headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

        // Add method override for PUT
        request.fields['_method'] = 'PUT';

        // Add text fields
        request.fields['title'] = title;
        request.fields['description'] = description;
        request.fields['category'] = category;

        // Add file
        var pic = await http.MultipartFile.fromPath('photo', photo.path);
        request.files.add(pic);

        // Send request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        print('Update Gallery Response: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return {
            'success': true,
            'message': data['message'] ?? 'Berhasil mengupdate foto galeri',
            'data': data['data']
          };
        } else {
          final data = json.decode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengupdate foto galeri',
          };
        }
      } else {
        // Regular PUT request (without photo)
        final response = await http.put(
          Uri.parse('$baseUrl/penjahit/gallery/$id'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'title': title,
            'description': description,
            'category': category,
          }),
        );

        print('Update Gallery Response: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return {
            'success': true,
            'message': data['message'] ?? 'Berhasil mengupdate data galeri',
            'data': data['data']
          };
        } else {
          final data = json.decode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal mengupdate data galeri',
          };
        }
      }
    } catch (e) {
      print('Error updateTailorGalleryItem: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Fungsi pertama yang menggunakan _imageBaseUrl
  static String getFullImageUrl(String? photoPath) {
    return UrlHelper.getFullImageUrl(photoPath);
  }

  /// Fungsi debugging untuk memeriksa ketersediaan URL gambar
  static Future<bool> checkImageUrlAvailability(String url) async {
    try {
      print('DEBUG: Memeriksa ketersediaan gambar: $url');

      // Buat HTTP request untuk memeriksa gambar
      final response = await http.head(Uri.parse(url));

      print('DEBUG: Status respons: ${response.statusCode}');
      print('DEBUG: Headers respons: ${response.headers}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('DEBUG: Error saat memeriksa URL gambar: $e');
      return false;
    }
  }

  /// Fungsi diagnostik untuk request HTTP
  static Future<Map<String, dynamic>> debugHttpRequest(String url,
      {Map<String, String>? headers}) async {
    try {
      print('\n======= DEBUG HTTP REQUEST =======');
      print('URL: $url');
      print('Headers: $headers');

      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse(url), headers: headers);
      stopwatch.stop();

      print('Status code: ${response.statusCode}');
      print('Response time: ${stopwatch.elapsedMilliseconds}ms');
      print('Content-Type: ${response.headers['content-type']}');
      print('Content-Length: ${response.headers['content-length']}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print(
            'Response (truncated): ${response.body.length > 100 ? "${response.body.substring(0, 100)}..." : response.body}');
        print('SUCCESS: Request berhasil');
      } else {
        print('ERROR: Request gagal dengan status ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      print('======= END DEBUG HTTP REQUEST =======\n');

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
        'headers': response.headers,
        'body': response.body,
        'responseTime': stopwatch.elapsedMilliseconds,
      };
    } catch (e) {
      print('ERROR: Exception during HTTP request: $e');
      print('ERROR STACK TRACE: ${StackTrace.current}');
      return {
        'success': false,
        'error': e.toString(),
        'stackTrace': StackTrace.current.toString(),
      };
    }
  }

  // Helper method untuk memproses data user dengan URL lengkap
  static Map<String, dynamic> _processUserDataWithCompleteUrls(
      Map<String, dynamic> userData) {
    // Buat salinan data user agar tidak mengubah data asli
    Map<String, dynamic> processedData = Map<String, dynamic>.from(userData);

    // Proses profile_photo jika ada
    if (processedData.containsKey('profile_photo') &&
        processedData['profile_photo'] != null &&
        processedData['profile_photo'].toString().isNotEmpty) {
      String photoUrl = processedData['profile_photo'];

      // Jika belum berupa URL lengkap, tambahkan base URL
      if (!photoUrl.startsWith('http')) {
        processedData['profile_photo'] = getFullImageUrl(photoUrl);
        print(
            'DEBUG API: Processed profile photo URL to: ${processedData['profile_photo']}');

        // Debug URL ketersediaan foto profil
        checkImageUrlAvailability(processedData['profile_photo'])
            .then((available) {
          print(
              'DEBUG: Foto profil ${available ? "tersedia" : "TIDAK TERSEDIA"}: ${processedData['profile_photo']}');
        });
      }
    }

    // Proses gallery jika ada
    if (processedData.containsKey('gallery') &&
        processedData['gallery'] is List) {
      List<dynamic> gallery = processedData['gallery'] as List;
      List<String> processedGallery = [];

      for (var item in gallery) {
        String photoUrl = item.toString();
        if (!photoUrl.startsWith('http')) {
          processedGallery.add(getFullImageUrl(photoUrl));
        } else {
          processedGallery.add(photoUrl);
        }
      }

      processedData['gallery'] = processedGallery;
      print('DEBUG API: Processed ${processedGallery.length} gallery items');
    }

    return processedData;
  }

  /// Mengambil rekomendasi penjahit dari API
  static Future<Map<String, dynamic>> getRecommendedTailors() async {
    try {
      print('\n===== DEBUG RECOMMENDED TAILORS =====');
      print('Memulai getRecommendedTailors()');
      
      final token = await getToken();

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/tailors/recommended'),
        headers: headers,
      );

      print('Response code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Perbaikan: Akses data['data']['tailors'] karena struktur respons API adalah Map bukan List
          List<dynamic> tailorsData = data['data']['tailors'] as List;
          List<TailorModel> tailors = tailorsData
              .map((tailor) => TailorModel.fromJson(tailor))
              .toList();

          // Debugging untuk tailors
          print('\n===== RECOMMENDED TAILORS DETAILS =====');
          for (var tailor in tailors) {
            print('----------------------------------------');
            print('Tailor ID: ${tailor.id}, Name: ${tailor.name}');
            print('Average Rating: ${tailor.average_rating}');
            print('Completed Orders: ${tailor.completed_orders}');
          }
          print('========================================\n');

          // Parse user preferences
          final List<int> userPreferred =
              List<int>.from(data['data']['user_preferred'] ?? []);

          return {
            'success': true,
            'tailors': tailors,
            'userPreferred': userPreferred,
            'message':
                data['message'] ?? 'Berhasil mendapatkan rekomendasi penjahit',
          };
        }
      }

      return {
        'success': false,
        'tailors': <TailorModel>[],
        'userPreferred': <int>[],
        'message': 'Gagal mendapatkan rekomendasi penjahit',
      };
    } catch (e, stackTrace) {
      AppLogger.error('Error getRecommendedTailors',
          error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'tailors': <TailorModel>[],
        'userPreferred': <int>[],
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Mengambil galeri penjahit berdasarkan id
  static Future<Map<String, dynamic>> getTailorGalleryById(int tailorId) async {
    try {
      print('Fetching tailor gallery for id: $tailorId');
      final token = await getToken();

      final headers = {
        'Accept': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/tailors/$tailorId/gallery'),
        headers: headers,
      );

      print('Tailor gallery response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Tailor gallery response: ${response.body}');

        // Parse data gallery ke dalam list GalleryModel
        final List<GalleryModel> galleryItems = [];

        if (data['data'] != null && data['data'] is List) {
          for (var item in data['data']) {
            galleryItems.add(GalleryModel.fromJson(item));
          }
        }

        return {
          'success': true,
          'gallery': galleryItems,
          'message': data['message'] ?? 'Berhasil mendapatkan galeri penjahit',
        };
      } else {
        return {
          'success': false,
          'gallery': <GalleryModel>[],
          'message': 'Gagal mendapatkan galeri penjahit',
        };
      }
    } catch (e) {
      print('Error getTailorGallery: $e');
      return {
        'success': false,
        'gallery': <GalleryModel>[],
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Mengambil detail penjahit berdasarkan id
  static Future<Map<String, dynamic>> getTailorById(int tailorId) async {
    try {
      print('Fetching tailor detail for id: $tailorId');
      final token = await getToken();

      final headers = {
        'Accept': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/tailors/$tailorId'),
        headers: headers,
      );

      print('Tailor detail response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Tailor detail response: ${response.body}');

        // Parse data menjadi TailorModel
        final TailorModel tailor = TailorModel.fromJson(data['data']);

        return {
          'success': true,
          'tailor': tailor,
          'message': data['message'] ?? 'Berhasil mendapatkan detail penjahit',
        };
      } else {
        return {
          'success': false,
          'tailor': null,
          'message': 'Gagal mendapatkan detail penjahit',
        };
      }
    } catch (e) {
      print('Error getTailorById: $e');
      return {
        'success': false,
        'tailor': null,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Membuat booking baru
  static Future<Map<String, dynamic>> createBooking(
    int tailorId,
    String appointmentDate,
    String appointmentTime,
    String serviceType,
    String category,
    String notes,
    File? designPhoto,
  ) async {
    try {
      print('Creating booking for tailor: $tailorId');
      final token = await getToken();

      final headers = {
        'Accept': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      };

      // Membuat request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/tailors/$tailorId/book'),
      );

      // Menambahkan headers
      request.headers.addAll(headers);

      // Menambahkan form fields
      request.fields['appointment_date'] = appointmentDate;
      request.fields['appointment_time'] = appointmentTime;
      request.fields['service_type'] = serviceType;
      request.fields['category'] = category;
      request.fields['notes'] = notes;

      // Menambahkan file jika ada
      if (designPhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'design_photo',
            designPhoto.path,
          ),
        );
      }

      // Kirim request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Booking response code: ${response.statusCode}');
      print('Booking response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Booking berhasil dibuat',
          'data': data['data'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal membuat booking',
        };
      }
    } catch (e) {
      print('Error createBooking: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Mengambil daftar booking penjahit
  static Future<Map<String, dynamic>> getTailorBookings() async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/penjahit/bookings'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Tailor bookings response status: ${response.statusCode}');
      print('DEBUG: Tailor bookings response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Log customer data dari API untuk debug
        if (data['data'] != null &&
            data['data'] is List &&
            data['data'].isNotEmpty) {
          final firstBooking = data['data'][0];
          if (firstBooking['customer'] != null) {
            print(
                'DEBUG: Sample customer data received: ${firstBooking['customer']}');
            if (firstBooking['customer']['profile_photo'] != null) {
              print(
                  'DEBUG: Profile photo from API: ${firstBooking['customer']['profile_photo']}');
            }
          }
        }

        return {
          'success': true,
          'bookings': data['data'],
          'message': data['message'] ?? 'Data booking berhasil diambil',
        };
      }

      final decodedResponse = jsonDecode(response.body);
      return {
        'success': false,
        'message': decodedResponse['message'] ?? 'Gagal memuat data booking',
      };
    } catch (e) {
      print('ERROR: Gagal memuat data booking: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Mengambil daftar booking penjahit berdasarkan status
  static Future<Map<String, dynamic>> getTailorBookingsByStatus(
      String status) async {
    try {
      // Validasi status yang diterima
      final validStatuses = ['diterima', 'diproses', 'selesai', 'dibatalkan'];
      if (!validStatuses.contains(status.toLowerCase())) {
        return {
          'success': false,
          'message':
              'Status tidak valid. Status yang valid adalah: ${validStatuses.join(", ")}'
        };
      }

      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/penjahit/bookings/status/$status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          'DEBUG: Tailor bookings by status response status: ${response.statusCode}');

      // Hanya print sebagian respons untuk debug yang lebih mudah dibaca
      if (response.body.length > 300) {
        print(
            'DEBUG: Tailor bookings by status response body (first 300 chars): ${response.body.substring(0, 300)}...');
      } else {
        print(
            'DEBUG: Tailor bookings by status response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['data'] == null) {
          print('ERROR: API Response tidak memiliki field "data"');
          return {
            'success': false,
            'message': 'Format respons API tidak valid: tidak ada data booking',
          };
        }

        // Cetak informasi sampel untuk debugging
        if (data['data'] is List && data['data'].isNotEmpty) {
          print(
              'DEBUG: Contoh data booking pertama diterima: ${data['data'][0]}');

          // Jika data['data'][0] berisi customer, cetak info customer pertama untuk debug
          if (data['data'][0] is Map &&
              data['data'][0].containsKey('customer')) {
            print(
                'DEBUG: Sample customer data received: ${data['data'][0]['customer']}');
          }
        }

        return {
          'success': true,
          'bookings': data['data'],
          'message': data['message'] ?? 'Data booking berhasil diambil',
        };
      }

      final decodedResponse = jsonDecode(response.body);
      return {
        'success': false,
        'message': decodedResponse['message'] ?? 'Gagal memuat data booking',
      };
    } catch (e) {
      print('ERROR: Gagal memuat data booking berdasarkan status: $e');
      print('ERROR STACK TRACE: ${StackTrace.current}');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Menerima pesanan booking
  static Future<Map<String, dynamic>> acceptBooking(int bookingId) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/accept'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Accept booking response status: ${response.statusCode}');
      print('DEBUG: Accept booking response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'booking': data['data']['booking'],
          'message': data['message'] ?? 'Pesanan berhasil diterima',
        };
      }

      final decodedResponse = jsonDecode(response.body);
      return {
        'success': false,
        'message': decodedResponse['message'] ?? 'Gagal menerima pesanan',
      };
    } catch (e) {
      print('ERROR: Gagal menerima pesanan: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Menolak pesanan booking
  static Future<Map<String, dynamic>> rejectBooking(
      int bookingId, String reason) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      // Periksa status booking terlebih dahulu
      final bookingDetail = await getBookingDetail(bookingId);
      if (bookingDetail['success'] && bookingDetail['booking'] != null) {
        final booking = bookingDetail['booking'] as Map<String, dynamic>;
        final status = booking['status']?.toString().toLowerCase() ?? '';

        // Cek apakah status booking adalah reservasi/pending
        if (status != 'reservasi' && status != 'pending') {
          return {
            'success': false,
            'message':
                'Booking dengan status "$status" tidak dapat ditolak. Hanya booking dengan status "reservasi" yang dapat ditolak.',
          };
        }
      }

      // Jika status valid, lanjutkan dengan permintaan API
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/reject'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rejection_reason': reason,
        }),
      );

      print('DEBUG: Reject booking response status: ${response.statusCode}');
      print('DEBUG: Reject booking response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'booking': data['data']?['booking'],
          'message': data['message'] ?? 'Pesanan berhasil ditolak',
        };
      }

      // Handle error validasi dengan pesan yang lebih spesifik
      final decodedResponse = jsonDecode(response.body);
      String errorMessage =
          decodedResponse['message'] ?? 'Gagal menolak pesanan';

      // Cek jika ada data.error (format error spesifik)
      if (decodedResponse['data'] != null &&
          decodedResponse['data'] is Map &&
          decodedResponse['data']['error'] != null) {
        errorMessage = decodedResponse['data']['error'];
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('ERROR: Gagal menolak pesanan: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Mendapatkan detail booking berdasarkan ID
  static Future<Map<String, dynamic>> getBookingDetail(int bookingId) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      // Ambil semua booking dari endpoint yang tersedia
      final response = await http.get(
        Uri.parse('$baseUrl/penjahit/bookings'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Booking list response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] && data['data'] != null && data['data'] is List) {
          // Cari booking dengan ID yang sesuai
          final List bookings = data['data'];

          // Metode aman untuk mencari booking dengan ID tertentu
          Map<String, dynamic>? booking;
          for (var item in bookings) {
            if (item is Map<String, dynamic> && item['id'] == bookingId) {
              booking = item;
              break;
            }
          }

          if (booking != null) {
            print('DEBUG: Booking dengan ID $bookingId ditemukan');
            return {
              'success': true,
              'booking': booking,
              'message': 'Detail pesanan berhasil diambil',
            };
          } else {
            print('DEBUG: Booking dengan ID $bookingId tidak ditemukan');
            return {
              'success': false,
              'message': 'Booking dengan ID $bookingId tidak ditemukan',
            };
          }
        } else {
          print('DEBUG: Format response tidak sesuai: ${response.body}');
          return {
            'success': false,
            'message': 'Format data tidak sesuai',
          };
        }
      }

      print('DEBUG: Gagal mengambil data booking: ${response.body}');
      final decodedResponse = jsonDecode(response.body);
      return {
        'success': false,
        'message': decodedResponse['message'] ?? 'Gagal memuat detail pesanan',
      };
    } catch (e) {
      print('ERROR: Gagal memuat detail pesanan: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Mendapatkan role user yang sedang login
  static Future<String?> getUserRole() async {
    try {
      final userData = await getProfile();
      if (userData['success'] && userData['user'] != null) {
        return userData['user']['role'];
      }
      return null;
    } catch (e) {
      print('ERROR: Gagal mendapatkan role user: $e');
      return null;
    }
  }

  /// Mendapatkan data profil pengguna yang sedang login
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Profile response status: ${response.statusCode}');
      print('DEBUG: Profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'user': data['data'],
          'message': data['message'] ?? 'Profil berhasil diambil',
        };
      }

      final decodedResponse = jsonDecode(response.body);
      return {
        'success': false,
        'message': decodedResponse['message'] ?? 'Gagal memuat profil',
      };
    } catch (e) {
      print('ERROR: Gagal memuat profil: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Memperbarui data booking
  static Future<Map<String, dynamic>> updateBooking(
      Map<String, dynamic> data) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      final bookingId = data['booking_id'];

      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      print('DEBUG: Update booking response status: ${response.statusCode}');
      print('DEBUG: Update booking response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Booking berhasil diperbarui',
          'data': responseData['data'],
        };
      }

      final responseData = jsonDecode(response.body);
      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal memperbarui booking',
      };
    } catch (e) {
      print('ERROR: Gagal memperbarui booking: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Memilih gambar dari galeri
  static Future<File?> pickImage() async {
    // Placeholder implementation
    // Dalam implementasi sebenarnya perlu menggunakan plugin seperti image_picker
    print('WARNING: pickImage belum diimplementasikan');
    return null;
  }

  /// Mengunggah file ke server
  static Future<Map<String, dynamic>> uploadFile(
      File file, String directory) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.',
        };
      }

      // Placeholder implementation
      // Dalam implementasi sebenarnya perlu menggunakan multipart request
      print('WARNING: uploadFile belum diimplementasikan');

      return {
        'success': false,
        'message': 'Fungsi upload belum diimplementasikan',
      };
    } catch (e) {
      print('ERROR: Gagal mengunggah file: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Memperbarui harga pesanan dan tanggal penyelesaian
  static Future<Map<String, dynamic>> updateBookingPrice(
      int bookingId, int price, String completionDate) async {
    try {
      print('DEBUG: Memperbarui harga pesanan #$bookingId dengan harga $price dan tanggal selesai $completionDate');
      print('DEBUG: Tipe data price: ${price.runtimeType}');
      
      // Verifikasi nilai tidak mengalami perubahan yang tidak diinginkan
      if (price.toString().length > 10) {
        print('ERROR: Nilai harga terlalu besar: $price. Kemungkinan ada masalah konversi.');
      }

      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      // Pastikan data yang dikirim konsisten
      final jsonBody = jsonEncode({
        'total_price': price,
        'completion_date': completionDate,
      });
      print('DEBUG: JSON yang dikirim ke server: $jsonBody');

      final response = await http.patch(
        Uri.parse('$baseUrl/bookings/$bookingId/price'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonBody,
      );

      print('DEBUG: Update price response status: ${response.statusCode}');
      print('DEBUG: Update price response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Log data respons secara lebih detail
        if (data['data'] != null && data['data']['booking'] != null) {
          final bookingData = data['data']['booking'];
          print('DEBUG: Booking data dari server: $bookingData');
          
          if (bookingData['total_price'] != null) {
            print('DEBUG: Harga yang diterima dari server: ${bookingData['total_price']}');
            print('DEBUG: Tipe data harga dari server: ${bookingData['total_price'].runtimeType}');
            
            // Jika server mengembalikan tipe data yang berbeda, coba konversi
            if (bookingData['total_price'] is String) {
              final String priceStr = bookingData['total_price'];
              print('DEBUG: Harga string dari server: $priceStr');
              
              // Coba parse ke numerik jika memungkinkan
              if (priceStr.contains('.')) {
                try {
                  final double priceDouble = double.parse(priceStr);
                  print('DEBUG: Harga dikonversi ke double: $priceDouble');
                  
                  // Update nilai dalam data respons
                  bookingData['total_price'] = priceDouble.toStringAsFixed(0);
                  print('DEBUG: Harga diupdate ke format tanpa desimal: ${bookingData['total_price']}');
                } catch (e) {
                  print('ERROR: Gagal mengkonversi harga: $e');
                }
              }
            }
          }
          
          // Log tanggal penyelesaian yang diterima
          if (bookingData['completion_date'] != null) {
            print('DEBUG: Tanggal penyelesaian dari server: ${bookingData['completion_date']}');
          }
        }
        
          return {
            'success': true,
          'message': data['message'] ?? 'Harga dan tanggal selesai berhasil diperbarui',
          'booking': data['data']?['booking'],
          };
        }

      final decodedResponse = jsonDecode(response.body);
        return {
          'success': false,
        'message':
            decodedResponse['message'] ?? 'Gagal memperbarui harga dan tanggal selesai pesanan',
      };
      } catch (e) {
      print('ERROR: Gagal memperbarui harga dan tanggal selesai pesanan: $e');
      print('ERROR STACK TRACE: ${StackTrace.current}');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Mendapatkan data kalender penjahit berdasarkan bulan dan tahun
  static Future<Map<String, dynamic>> getTailorCalendar(
      String month, String year) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/penjahit/calendar/$month/$year'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Tailor calendar response status: ${response.statusCode}');
      print('DEBUG: Tailor calendar response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Data kalender berhasil dimuat',
            'data': data['data'],
          };
        }

        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memuat data kalender',
        };
      }

      // Handle error response
      Map<String, dynamic> errorResponse = {};
      try {
        errorResponse = jsonDecode(response.body);
      } catch (e) {
        errorResponse = {'message': 'Gagal memuat data kalender'};
      }

      return {
        'success': false,
        'message': errorResponse['message'] ?? 'Gagal memuat data kalender',
      };
    } catch (e) {
      print('ERROR: Gagal memuat data kalender: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  /// Mendapatkan data dashboard penjahit
  static Future<Map<String, dynamic>> getTailorDashboard() async {
    try {
      final token = await getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/penjahit/dashboard'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Tailor dashboard response status: ${response.statusCode}');
      print('DEBUG: Tailor dashboard response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'Data dashboard berhasil dimuat',
            'data': data['data'],
          };
        }

        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memuat data dashboard',
        };
      }

      // Handle error response
      Map<String, dynamic> errorResponse = {};
      try {
        errorResponse = jsonDecode(response.body);
      } catch (e) {
        errorResponse = {'message': 'Gagal memuat data dashboard'};
      }

      return {
        'success': false,
        'message': errorResponse['message'] ?? 'Gagal memuat data dashboard',
      };
    } catch (e) {
      print('ERROR: Gagal memuat data dashboard: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Method untuk menyelesaikan pembayaran akhir booking
  static Future<Map<String, dynamic>> completePayment(
      int bookingId, String pickupDate) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.'
        };
      }

      print(
          'DEBUG: Memproses pembayaran untuk booking ID: $bookingId dengan tanggal pengambilan: $pickupDate');

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/completion-payment'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'pickup_date': pickupDate,
        }),
      );

      print('DEBUG: Respon status: ${response.statusCode}');
      print('DEBUG: Respon body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Pembayaran berhasil dikonfirmasi',
          'booking': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memproses pembayaran',
        };
      }
    } catch (e) {
      print('ERROR: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Tambahkan method baru untuk menghitung penjahit terdekat berdasarkan data rekomendasi
  static Future<Map<String, dynamic>> getNearbyTailors({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Gunakan data dari API rekomendasi
      final result = await getRecommendedTailors();

      print('\n===== DEBUG NEARBY TAILORS =====');
      print('Menggunakan data rekomendasi untuk menghitung penjahit terdekat');

      if (result['success'] == true && result['tailors'] != null) {
        List<TailorModel> allTailors = result['tailors'] as List<TailorModel>;

        // Filter penjahit yang memiliki data lokasi
        List<TailorModel> tailorsWithLocation = allTailors.where((tailor) {
          return tailor.latitude != null &&
              tailor.longitude != null &&
              tailor.latitude!.isNotEmpty &&
              tailor.longitude!.isNotEmpty;
        }).toList();

        print('Ditemukan ${tailorsWithLocation.length} penjahit dengan data lokasi dari ${allTailors.length} total penjahit');

        // Hitung jarak untuk setiap penjahit
        for (var tailor in tailorsWithLocation) {
          double tailorLat = double.tryParse(tailor.latitude!) ?? 0;
          double tailorLng = double.tryParse(tailor.longitude!) ?? 0;

          // Hitung jarak menggunakan formula Haversine
          double distance =
              _calculateDistance(latitude, longitude, tailorLat, tailorLng);

          // Update jarak pada model
          tailor.updateDistance(distance);
        }

        // Urutkan berdasarkan jarak terdekat
        tailorsWithLocation.sort((a, b) => (a.distance ?? double.infinity)
            .compareTo(b.distance ?? double.infinity));

        // Batasi hanya menampilkan penjahit dalam radius 10km
        final nearbyTailors = tailorsWithLocation
            .where(
                (tailor) => tailor.distance != null && tailor.distance! <= 10)
            .toList();
            
        // Debug info untuk penjahit terdekat
        print('\n===== NEARBY TAILORS AFTER FILTERING =====');
        for (var tailor in nearbyTailors) {
          print('Tailor ID: ${tailor.id}, Name: ${tailor.name}, Distance: ${tailor.distance?.toStringAsFixed(2)} km');
          print('  - Average Rating: ${tailor.average_rating}');
          print('  - Completed Orders: ${tailor.completed_orders}');
        }
        print('===========================================\n');

        return {
          'success': true,
          'tailors': nearbyTailors,
          'message': 'Berhasil mendapatkan data penjahit terdekat',
        };
      } else {
        return {
          'success': false,
          'tailors': <TailorModel>[],
          'message':
              result['message'] ?? 'Gagal mendapatkan data penjahit terdekat',
        };
      }
    } catch (e) {
      print('ERROR: Error getting nearby tailors: $e');
      return {
        'success': false,
        'tailors': <TailorModel>[],
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Tambahkan method untuk menghitung jarak antara dua koordinat
  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radius bumi dalam kilometer

    // Konversi derajat ke radian
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    // Formula Haversine
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }


  /// Fungsi khusus untuk memvalidasi dan men-debug URL gambar desain
  static Future<Map<String, dynamic>> validateDesignPhotoUrl(String url) async {
    try {
      print('\n======= DEBUG DESIGN PHOTO URL =======');
      print('URL yang akan dicek: $url');

      // Periksa jika URL-nya valid
      Uri? uri;
      try {
        uri = Uri.parse(url);
        print('URL parsing berhasil: $uri');
        print('Scheme: ${uri.scheme}');
        print('Host: ${uri.host}');
        print('Path: ${uri.path}');
      } catch (e) {
        print('URL tidak valid: $e');
        return {'success': false, 'message': 'URL tidak valid: $e', 'url': url};
      }

      // Coba lakukan request HEAD untuk memeriksa ketersediaan
      try {
        final headResponse = await http.head(uri);
        print('HEAD response status: ${headResponse.statusCode}');
        print('HEAD response headers: ${headResponse.headers}');

        if (headResponse.statusCode == 200) {
          print('✅ URL dapat diakses dengan HEAD request');
        } else {
          print(
              '❌ URL tidak dapat diakses dengan HEAD request: ${headResponse.statusCode}');
        }
      } catch (e) {
        print('❌ Error saat melakukan HEAD request: $e');
      }

      // Coba lakukan request GET untuk memeriksa konten
      try {
        final stopwatch = Stopwatch()..start();
        final response = await http.get(uri);
        stopwatch.stop();

        print('GET response time: ${stopwatch.elapsedMilliseconds}ms');
        print('GET response status: ${response.statusCode}');
        print('GET response content-type: ${response.headers['content-type']}');
        print(
            'GET response content-length: ${response.headers['content-length']}');

        if (response.statusCode == 200) {
          final contentType = response.headers['content-type'];
          if (contentType != null && contentType.startsWith('image/')) {
            print('✅ URL berisi gambar dengan tipe: $contentType');

            // Verifikasi jenis konten
            print('Verifikasi konten sebagai gambar...');
            print('Ukuran respons: ${response.bodyBytes.length} bytes');

            return {
              'success': true,
              'message': 'URL berisi gambar valid',
              'url': url,
              'contentType': contentType,
              'sizeBytes': response.bodyBytes.length,
              'responseTime': stopwatch.elapsedMilliseconds
            };
          } else {
            print('❌ URL tidak berisi gambar. Content-Type: $contentType');
            if (response.bodyBytes.length < 5000) {
              print('Respons (mungkin error): ${response.body}');
            }

            return {
              'success': false,
              'message': 'URL tidak berisi gambar',
              'url': url,
              'contentType': contentType,
              'responseBody': response.bodyBytes.length < 1000
                  ? response.body
                  : '(too large)',
              'statusCode': response.statusCode
            };
          }
        } else {
          print('❌ GET request gagal: ${response.statusCode}');
          print('Respons error: ${response.body}');

          return {
            'success': false,
            'message': 'GET request gagal',
            'url': url,
            'statusCode': response.statusCode,
            'responseBody':
                response.bodyBytes.length < 1000 ? response.body : '(too large)'
          };
        }
      } catch (e) {
        print('❌ Error saat melakukan GET request: $e');
        return {
          'success': false,
          'message': 'Error saat melakukan GET request',
          'url': url,
          'error': e.toString()
        };
      }

      print('======= END DEBUG DESIGN PHOTO URL =======\n');
    } catch (e) {
      print('ERROR: Exception during validateDesignPhotoUrl: $e');
      print('Stacktrace: ${StackTrace.current}');
      return {'success': false, 'message': 'Terjadi kesalahan: $e', 'url': url};
    }
  }

  /// Fungsi untuk mendebug semua masalah URL gambar
  static Future<void> debugAllImageUrls(List<String> urls) async {
    print('\n======= DEBUG ALL IMAGE URLS =======');
    print('Jumlah URL yang akan dicek: ${urls.length}');

    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      print('\n[$i/${urls.length}] Memeriksa URL: $url');

      try {
        final result = await validateDesignPhotoUrl(url);
        if (result['success'] == true) {
          successCount++;
          print('✅ URL #$i VALID: $url');
        } else {
          failCount++;
          print('❌ URL #$i TIDAK VALID: $url');
          print('  Alasan: ${result['message']}');
        }
      } catch (e) {
        failCount++;
        print('❌ URL #$i ERROR: $e');
      }
    }

    print('\nHasil pemeriksaan:');
    print('- URL valid: $successCount');
    print('- URL tidak valid/error: $failCount');
    print('======= END DEBUG ALL IMAGE URLS =======\n');
  }

  /// Fungsi untuk mendiagnosis dan memperbaiki URL gambar
  static Future<String> fixAndValidateImageUrl(String originalUrl) async {
    print('\n======= DIAGNOSA DAN PERBAIKAN URL GAMBAR =======');
    print('URL original: $originalUrl');

    // Periksa apakah URL sudah valid
    var checkResult = await validateDesignPhotoUrl(originalUrl);
    if (checkResult['success'] == true) {
      print('✅ URL original sudah valid');
      print('======= AKHIR DIAGNOSA URL GAMBAR =======\n');
      return originalUrl;
    }

    // Coba berbagai variasi URL untuk memperbaiki
    List<String> alternativeUrls = [];

    // 1. Ubah http ke https atau sebaliknya
    if (originalUrl.startsWith('http://')) {
      alternativeUrls.add(originalUrl.replaceFirst('http://', 'https://'));
    } else if (originalUrl.startsWith('https://')) {
      alternativeUrls.add(originalUrl.replaceFirst('https://', 'http://'));
    }

    // 2. Cek variasi path
    Uri? uri;
    try {
      uri = Uri.parse(originalUrl);

      // Ekstrak komponen path
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;

        // Coba dengan path langsung ke storage
        if (!pathSegments.contains('storage') &&
            !originalUrl.contains('/storage/')) {
          final newPathWithStorage = '/storage/${pathSegments.join('/')}';
          alternativeUrls
              .add('${uri.scheme}://${uri.authority}$newPathWithStorage');
        }

        // Coba path dengan design_photos jika belum ada
        if (!pathSegments.contains('design_photos')) {
          alternativeUrls.add(
              '${uri.scheme}://${uri.authority}/storage/design_photos/$lastSegment');
        }
      }
    } catch (e) {
      print('❌ Error parsing URL untuk membuat alternatif: $e');
    }

    // 3. Tambahkan baseUrl jika URL relatif
    if (!originalUrl.startsWith('http')) {
      if (originalUrl.startsWith('/')) {
        alternativeUrls.add('$imageBaseUrl$originalUrl');
      } else {
        alternativeUrls.add('$imageBaseUrl/$originalUrl');
      }

      // Dengan /storage/ prefix
      if (!originalUrl.contains('storage')) {
        if (originalUrl.startsWith('/')) {
          alternativeUrls.add('$imageBaseUrl/storage$originalUrl');
        } else {
          alternativeUrls.add('$imageBaseUrl/storage/$originalUrl');
        }
      }
    }

    // Cetak semua URL alternatif
    print('URL alternatif yang akan dicoba:');
    for (int i = 0; i < alternativeUrls.length; i++) {
      print('[$i] ${alternativeUrls[i]}');
    }

    // Periksa semua URL alternatif
    for (int i = 0; i < alternativeUrls.length; i++) {
      final alternativeUrl = alternativeUrls[i];
      print('\nMencoba URL alternatif [$i]: $alternativeUrl');

      final result = await validateDesignPhotoUrl(alternativeUrl);
      if (result['success'] == true) {
        print('✅ URL alternatif [$i] VALID: $alternativeUrl');
        print('======= AKHIR DIAGNOSA URL GAMBAR =======\n');
        return alternativeUrl;
      } else {
        print('❌ URL alternatif [$i] TIDAK VALID');
      }
    }

    print('❌ Semua upaya perbaikan URL gagal');
    print('======= AKHIR DIAGNOSA URL GAMBAR =======\n');

    // Jika semua upaya gagal, kembalikan URL original
    return originalUrl;
  }

  /// Fungsi khusus untuk memperbaiki URL gambar design_photos
  static Future<String> fixDesignPhotoUrl(String originalUrl) async {
    try {
      print('\n======= DEBUG & FIX DESIGN PHOTO URL =======');
      print('URL original: $originalUrl');

      // Periksa jika URL sudah memakai scheme http/https
      if (originalUrl.startsWith('http')) {
        // Jika URL sudah lengkap, periksa apakah bisa diakses
        var result = await validateDesignPhotoUrl(originalUrl);
        if (result['success'] == true) {
          print('✅ URL sudah valid dan bisa diakses');
          return originalUrl;
        }

        // Jika tidak bisa diakses, coba ganti dari http ke https dan sebaliknya
        String alternativeUrl;
        if (originalUrl.startsWith('https://')) {
          alternativeUrl = originalUrl.replaceFirst('https://', 'http://');
          print('Mencoba alternatif HTTP: $alternativeUrl');
        } else {
          alternativeUrl = originalUrl.replaceFirst('http://', 'https://');
          print('Mencoba alternatif HTTPS: $alternativeUrl');
        }

        // Periksa URL alternatif
        result = await validateDesignPhotoUrl(alternativeUrl);
        if (result['success'] == true) {
          print('✅ URL alternatif valid: $alternativeUrl');
          return alternativeUrl;
        }
      } else {
        // URL tidak lengkap, coba bangun URL lengkap
        List<String> possibleUrls = [];

        // Variasi 1: Langsung tambahkan ke base URL
        if (originalUrl.startsWith('/')) {
          possibleUrls.add('$imageBaseUrl$originalUrl');
        } else {
          possibleUrls.add('$imageBaseUrl/$originalUrl');
        }

        // Variasi 2: Tambahkan storage path jika belum ada
        if (!originalUrl.contains('storage/') &&
            !originalUrl.contains('/storage/')) {
          if (originalUrl.startsWith('/')) {
            possibleUrls.add('$imageBaseUrl/storage$originalUrl');
          } else {
            possibleUrls.add('$imageBaseUrl/storage/$originalUrl');
          }
        }

        // Variasi 3: Jika ini adalah nama file design_photo, tambahkan path lengkap
        final fileName = originalUrl.split('/').last;
        // Jika namanya mengandung ekstensi gambar
        if (fileName.contains('.png') ||
            fileName.contains('.jpg') ||
            fileName.contains('.jpeg')) {
          possibleUrls.add('$imageBaseUrl/storage/design_photos/$fileName');
        }

        // Coba semua URL yang mungkin
        print('Mencoba ${possibleUrls.length} variasi URL:');
        for (int i = 0; i < possibleUrls.length; i++) {
          final url = possibleUrls[i];
          print('[$i] Mencoba: $url');

          var result = await validateDesignPhotoUrl(url);
          if (result['success'] == true) {
            print('✅ URL berhasil diperbaiki: $url');
            print('======= END DEBUG & FIX DESIGN PHOTO URL =======\n');
            return url;
          }
        }
      }

      // Upaya perbaikan gagal, kembalikan URL original
      print('❌ Semua upaya perbaikan gagal. Mengembalikan URL original.');
      print('======= END DEBUG & FIX DESIGN PHOTO URL =======\n');

      // Untuk kasus URL yang tidak valid, buat URL gambar placeholder
      if (!originalUrl.startsWith('http') && !originalUrl.contains('/')) {
        return 'assets/images/tailor_default.png';
      }

      return originalUrl;
    } catch (e) {
      print('ERROR saat memperbaiki URL gambar design: $e');
      return originalUrl;
    }
  }

  /// Fungsi untuk membuka dan men-debug masalah dengan gambar design
  static Future<void> debugDesignPhotoIssue(String designPhotoUrl) async {
    print('\n========== DEBUGGING DESIGN PHOTO ISSUE ==========');
    print('URL original: $designPhotoUrl');

    // Info dasar server
    print('\nINFO SERVER:');
    print('Base URL API: $baseUrl');
    print('Base URL Gambar: $imageBaseUrl');

    // Check URL structure
    print('\nANALISIS URL:');
    try {
      Uri? uri = Uri.parse(designPhotoUrl);
      print('- Scheme: ${uri.scheme}');
      print('- Host: ${uri.host}');
      print('- Path: ${uri.path}');
      print('- Query params: ${uri.queryParameters}');

      // Check if domain is correct
      if (uri.host != Uri.parse(imageBaseUrl).host) {
        print('⚠️ PERINGATAN: Host URL tidak sesuai dengan imageBaseUrl!');
      }

      // Check if path contains required parts
      if (!uri.path.contains('storage') &&
          !uri.path.contains('design_photos')) {
        print(
            '⚠️ PERINGATAN: Path URL tidak mengandung "storage" atau "design_photos"');
      }

      // Check file extension
      final extension = uri.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        print(
            '⚠️ PERINGATAN: Ekstensi file tidak standar untuk gambar: $extension');
      }
    } catch (e) {
      print('❌ URL tidak valid: $e');
    }

    // Try different variations of URL
    print('\nMENCOBA VARIASI URL:');
    List<String> variations = [];

    // Add variations based on different URL patterns
    if (designPhotoUrl.startsWith('http')) {
      try {
        Uri uri = Uri.parse(designPhotoUrl);
        String fileName =
            uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';

        if (designPhotoUrl.startsWith('https://')) {
          variations.add(designPhotoUrl.replaceFirst('https://', 'http://'));
        } else {
          variations.add(designPhotoUrl.replaceFirst('http://', 'https://'));
        }

        // Try adding or removing storage path
        if (!uri.path.contains('storage')) {
          var pathSegments = uri.pathSegments.toList();
          pathSegments.insert(0, 'storage');
          var newPath = '/${pathSegments.join('/')}';
          variations.add('${uri.scheme}://${uri.authority}$newPath');
        }

        // Try with direct design_photos path if it's just a file
        if (fileName.isNotEmpty && fileName.contains('.')) {
          variations.add('$imageBaseUrl/storage/design_photos/$fileName');
        }
      } catch (e) {
        print('❌ Error saat membuat variasi URL: $e');
      }
    } else {
      // It's a relative path or just a filename
      variations.add('$imageBaseUrl/$designPhotoUrl');
      variations.add('$imageBaseUrl/storage/$designPhotoUrl');

      // If it looks like a filename
      if (!designPhotoUrl.contains('/')) {
        variations.add('$imageBaseUrl/storage/design_photos/$designPhotoUrl');
      }
    }

    // Test all URL variations
    print('Testing ${variations.length} URL variations:');
    for (int i = 0; i < variations.length; i++) {
      final variation = variations[i];
      print('\n[$i] Testing: $variation');

      try {
        final result = await validateDesignPhotoUrl(variation);
        if (result['success'] == true) {
          print('✅ URL variation works! $variation');
          print('Content-Type: ${result['contentType']}');
          print('Size: ${result['sizeBytes']} bytes');
        } else {
          print('❌ URL variation failed: ${result['message']}');
        }
      } catch (e) {
        print('❌ Error testing URL variation: $e');
      }
    }

    // Check server connectivity
    print('\nCEK KONEKTIVITAS SERVER:');
    try {
      final response = await http.get(Uri.parse('$imageBaseUrl/ping'));
      print('Server base URL ping response: ${response.statusCode}');
    } catch (e) {
      print('❌ Error connecting to server: $e');
    }

    print('\n========== END DEBUGGING DESIGN PHOTO ISSUE ==========');
  }

  // Method untuk melakukan HTTP GET request
  static Future<ApiResponse> get(String endpoint) async {
    try {
      AppLogger.info('GET request ke $baseUrl$endpoint', tag: 'API');

      final token = await getToken();
      if (token == null) {
        AppLogger.error('Token tidak ditemukan', tag: 'API');
        return ApiResponse(
          isSuccess: false,
          message: 'Token tidak ditemukan. Silakan login kembali.',
        );
      }

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.debug('GET response: ${response.statusCode}', tag: 'API');

      // Parse response body
      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          isSuccess: true,
          message: decodedResponse['message'] ?? 'Berhasil mendapatkan data',
          data: decodedResponse['data'],
        );
      } else {
        return ApiResponse(
          isSuccess: false,
          message:
              decodedResponse['message'] ?? 'Terjadi kesalahan pada server',
        );
      }
    } catch (e) {
      AppLogger.error('Exception pada GET request', error: e, tag: 'API');
      return ApiResponse(
        isSuccess: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.',
          'data': {'name': '', 'email': ''}
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Berhasil mendapatkan data profil',
          'data': data['data'] ?? {'name': '', 'email': ''}
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mendapatkan data profil',
          'data': {'name': '', 'email': ''}
        };
      }
    } catch (e) {
      print('Error getting user profile: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
        'data': {'name': '', 'email': ''}
      };
    }
  }
}

/// Kelas untuk response API yang terstruktur
class ApiResponse {
  final bool isSuccess;
  final String? message;
  final dynamic data;

  ApiResponse({
    required this.isSuccess,
    this.message,
    this.data,
  });
}
