import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';

class AuthController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController shopDescriptionController =
      TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  List<int> selectedSpecializations = [];
  List<Map<String, dynamic>> availableSpecializations = [];
  bool isLoading = false;

  // Map untuk menyimpan error validasi
  Map<String, String> validationErrors = {};

  AuthController() {
    _loadSpecializations();
  }

  bool validateLoginInputs(BuildContext context) {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password harus diisi')),
      );
      return false;
    }
    return true;
  }

  bool validateRegistrationInputs(BuildContext context,
      {bool isTailor = false}) {
    // Reset error validasi sebelumnya
    validationErrors.clear();
    bool isValid = true;

    // Validasi email
    if (emailController.text.isEmpty) {
      validationErrors['email'] = 'Email tidak boleh kosong';
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(emailController.text)) {
      validationErrors['email'] = 'Format email tidak valid';
      isValid = false;
    }

    // Validasi nama
    if (nameController.text.isEmpty) {
      validationErrors['name'] = 'Nama tidak boleh kosong';
      isValid = false;
    }

    // Validasi no handphone
    if (phoneController.text.isEmpty) {
      validationErrors['phone'] = 'Nomor handphone tidak boleh kosong';
      isValid = false;
    } else if (!RegExp(r'^[0-9]{10,13}$').hasMatch(phoneController.text)) {
      validationErrors['phone'] = 'Nomor handphone tidak valid (10-13 digit)';
      isValid = false;
    }

    // Validasi alamat
    if (addressController.text.isEmpty) {
      validationErrors['address'] = 'Alamat tidak boleh kosong';
      isValid = false;
    }

    // Validasi password
    if (passwordController.text.isEmpty) {
      validationErrors['password'] = 'Password tidak boleh kosong';
      isValid = false;
    } else if (passwordController.text.length < 8) {
      validationErrors['password'] = 'Password minimal 8 karakter';
      isValid = false;
    }

    // Validasi konfirmasi password
    if (confirmPasswordController.text.isEmpty) {
      validationErrors['confirm_password'] =
          'Konfirmasi password tidak boleh kosong';
      isValid = false;
    } else if (passwordController.text != confirmPasswordController.text) {
      validationErrors['confirm_password'] = 'Password tidak cocok';
      isValid = false;
    }

    // Validasi spesifik untuk penjahit
    if (isTailor) {
      if (storeNameController.text.isEmpty) {
        validationErrors['store_name'] = 'Nama toko tidak boleh kosong';
        isValid = false;
      }

      if (experienceController.text.isEmpty) {
        validationErrors['experience'] = 'Pengalaman tidak boleh kosong';
        isValid = false;
      } else if (!RegExp(r'^[0-9]+$').hasMatch(experienceController.text)) {
        validationErrors['experience'] = 'Pengalaman harus berupa angka';
        isValid = false;
      }

      if (shopDescriptionController.text.isEmpty) {
        validationErrors['shop_description'] =
            'Deskripsi toko tidak boleh kosong';
        isValid = false;
      }
    }

    // Tampilkan error dalam dialog jika ada error validasi
    if (!isValid) {
      showValidationErrorDialog(context);
    }

    return isValid;
  }

  bool validateForgotPassword(BuildContext context) {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak boleh kosong')),
      );
      return false;
    }
    return true;
  }

  Future<void> logout([BuildContext? context]) async {
    print('DEBUG: Memulai proses logout...');
    try {
      // Reset semua controller
      print('DEBUG: Mereset semua controller...');
      emailController.clear();
      nameController.clear();
      phoneController.clear();
      addressController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      storeNameController.clear();
      experienceController.clear();
      shopDescriptionController.clear();
      latitudeController.clear();
      longitudeController.clear();
      selectedSpecializations.clear();
      availableSpecializations.clear();
      print('DEBUG: Semua controller berhasil direset');

      // Hapus data user dari provider jika context tersedia
      if (context != null) {
        print('DEBUG: Membersihkan data user dari provider...');
        try {
          await Provider.of<UserProvider>(context, listen: false).clearUser();
          print('DEBUG: Data user berhasil dihapus dari provider');
        } catch (e) {
          print('ERROR saat menghapus data user dari provider: $e');
        }
      } else {
        print(
            'DEBUG: Context tidak tersedia, melewati pembersihan user provider');
      }

      // Panggil API logout untuk menghapus token autentikasi
      print('DEBUG: Memanggil ApiService.logout()...');
      try {
        await AuthService.clearAuthData();
        print('DEBUG: Token autentikasi berhasil dihapus');
      } catch (e) {
        print('ERROR saat menghapus token autentikasi: $e');
      }

      print('DEBUG: Proses logout selesai');
    } catch (e) {
      print('ERROR KRITIS pada proses logout: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  void dispose() {
    emailController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    storeNameController.dispose();
    experienceController.dispose();
    shopDescriptionController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
  }

  Future<void> _loadSpecializations() async {
    availableSpecializations = await ApiService.getSpecializations();
  }

  void toggleSpecialization(int id) {
    if (selectedSpecializations.contains(id)) {
      selectedSpecializations.remove(id);
    } else {
      selectedSpecializations.add(id);
    }
  }

  Future<bool> loginTailor(BuildContext context) async {
    if (!validateLoginInputs(context)) return false;

    isLoading = true;

    try {
      final result = await ApiService.loginTailor(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      isLoading = false;

      // Tampilkan respons lengkap untuk debugging
      print('DEBUG LOGIN FULL RESPONSE: ${result.toString()}');

      if (result['success'] == true) {
        // Verifikasi token tersimpan dengan benar
        final token = await ApiService.getToken();
        if (token == null || token.isEmpty) {
          print(
              'WARNING: Token tidak berhasil disimpan setelah login penjahit berhasil');
        }

        print(
            'DEBUG AUTH: Respons login sukses, struktur data: ${result.keys.join(', ')}');

        // Simpan data user ke UserProvider
        if (result.containsKey('user') && result['user'] is Map) {
          var userData = result['user'] as Map<String, dynamic>;
          print(
              'DEBUG AUTH: User data dari "user": ${userData.keys.join(', ')}');
          if (userData.containsKey('profile_photo')) {
            print(
                'DEBUG AUTH: Profile photo dari data user: ${userData['profile_photo']}');
          }

          await Provider.of<UserProvider>(context, listen: false)
              .setUser(userData);

          print('DEBUG AUTH: User data saved to provider from "user" key');
        } else if (result.containsKey('data') &&
            result['data'] is Map &&
            (result['data'] as Map).containsKey('user')) {
          var userData =
              (result['data'] as Map)['user'] as Map<String, dynamic>;
          print(
              'DEBUG AUTH: User data dari "data.user": ${userData.keys.join(', ')}');
          if (userData.containsKey('profile_photo')) {
            print(
                'DEBUG AUTH: Profile photo dari data.user: ${userData['profile_photo']}');
          }

          await Provider.of<UserProvider>(context, listen: false)
              .setUser(userData);

          print('DEBUG AUTH: User data saved to provider from "data.user" key');
        } else {
          print('WARNING: Data user tidak ditemukan dalam respons login');
          if (result.containsKey('data')) {
            print('DEBUG AUTH: Konten "data": ${result['data']}');
          }
        }

        // Simpan data autentikasi
        if (token != null) {
          await AuthService.saveAuthData(
            token,
            'penjahit',
            result['user']['id'],
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        // Cek apakah error terkait email belum diverifikasi
        if (result.containsKey('data') && 
            result['data'] is Map && 
            (result['data'] as Map).containsKey('error')) {
          
          final errorMsg = result['data']['error'].toString();
          if (errorMsg.contains('Email belum diverifikasi')) {
            // Ekstrak email dari pesan error
            final emailMatch = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}')
                .firstMatch(errorMsg);
            final email = emailMatch != null ? emailMatch.group(0) : emailController.text.trim();
            
            // Tampilkan dialog email belum diverifikasi dengan respons lengkap
            showEmailVerificationDialog(context, email ?? '', result);
            return false;
          }
        }

        // Jika bukan error email belum diverifikasi, tampilkan dialog error login
        showErrorDialog(context, 'Login Gagal', 
          'Pesan: ${result['message']}\n\n${result['data'] != null ? 'Detail: ${result['data']}' : ''}');
        return false;
      }
    } catch (e) {
      isLoading = false;
      print('ERROR login penjahit: $e');
      showErrorDialog(context, 'Terjadi Kesalahan', 'Error: $e');
      return false;
    }
  }

  Future<bool> registerTailor(BuildContext context) async {
    // Validasi dasar input
    if (!validateRegistrationInputs(context, isTailor: true)) return false;

    // Validasi tambahan untuk spesialisasi
    if (selectedSpecializations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu spesialisasi'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    isLoading = true;

    try {
      // Log data yang akan dikirimkan
      print('Sending registration data to API:');
      print('Name: ${nameController.text.trim()}');
      print('Email: ${emailController.text.trim()}');
      print('Phone: ${phoneController.text.trim()}');
      print('Store: ${storeNameController.text.trim()}');
      print('Experience: ${experienceController.text.trim()}');
      print('Address: ${addressController.text.trim()}');
      print('Shop Description: ${shopDescriptionController.text.trim()}');
      print('Specializations: $selectedSpecializations');

      // Parsing latitude dan longitude jika ada
      double? latitude;
      double? longitude;

      if (latitudeController.text.isNotEmpty) {
        latitude = double.tryParse(latitudeController.text);
        print('Latitude: $latitude');
      }

      if (longitudeController.text.isNotEmpty) {
        longitude = double.tryParse(longitudeController.text);
        print('Longitude: $longitude');
      }

      final result = await ApiService.registerTailor(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        passwordConfirmation: confirmPasswordController.text,
        phoneNumber: phoneController.text.trim(),
        address: addressController.text.trim(),
        shopDescription: shopDescriptionController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        specializations: selectedSpecializations,
      );

      isLoading = false;

      print('Registration result: $result');

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        String errorMessage =
            result['message'] ?? 'Terjadi kesalahan saat registrasi';

        // Cek apakah ada pesan error spesifik
        if (result.containsKey('errors')) {
          try {
            final errors = result['errors'] as Map<String, dynamic>;
            if (errors.isNotEmpty) {
              errorMessage = '';
              validationErrors.clear(); // Reset validasi errors

              errors.forEach((key, value) {
                if (value is List && value.isNotEmpty) {
                  // Format field name untuk tampilan yang lebih baik
                  String fieldName = key.replaceAll('_', ' ');
                  fieldName =
                      fieldName[0].toUpperCase() + fieldName.substring(1);

                  String errorMsg = '• $fieldName: ${value.first}';
                  errorMessage += '$errorMsg\n';
                  validationErrors[key] = value.first.toString();
                } else if (value is String) {
                  String errorMsg = '• $key: $value';
                  errorMessage += '$errorMsg\n';
                  validationErrors[key] = value;
                }
              });

              // Tampilkan dialog error registrasi
              showRegistrationErrorDialog(context);
            }
          } catch (e) {
            print('Error processing error messages: $e');
          }
        } else {
          // Jika tidak ada errors detail, tampilkan pesan umum
          showErrorDialog(context, 'Registrasi Gagal', errorMessage);
        }

        return false;
      }
    } catch (e) {
      isLoading = false;
      print('Exception during tailor registration: $e');
      showErrorDialog(context, 'Terjadi Kesalahan', 'Error: $e');
      return false;
    }
  }

  // Metode login untuk customer dengan UserProvider
  Future<bool> loginCustomer(BuildContext context) async {
    if (!validateLoginInputs(context)) return false;

    isLoading = true;

    try {
      final result = await ApiService.loginCustomer(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      isLoading = false;

      // Tampilkan respons lengkap untuk debugging
      print('DEBUG LOGIN FULL RESPONSE: ${result.toString()}');
      
      if (result['success'] == true) {
        // Verifikasi token tersimpan dengan benar
        final token = await ApiService.getToken();
        if (token == null || token.isEmpty) {
          print(
              'WARNING: Token tidak berhasil disimpan setelah login berhasil');
        }

        // Simpan data user ke UserProvider
        if (result.containsKey('user') && result['user'] is Map) {
          await Provider.of<UserProvider>(context, listen: false)
              .setUser(result['user'] as Map<String, dynamic>);
        } else if (result.containsKey('data') &&
            result['data'] is Map &&
            (result['data'] as Map).containsKey('user')) {
          await Provider.of<UserProvider>(context, listen: false)
              .setUser((result['data'] as Map)['user'] as Map<String, dynamic>);
        } else {
          print('WARNING: Data user tidak ditemukan dalam respons login');
        }

        // Simpan data autentikasi
        if (token != null) {
          await AuthService.saveAuthData(
            token,
            'pelanggan',
            result['user']['id'],
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        // Cek apakah error terkait email belum diverifikasi
        if (result.containsKey('data') && 
            result['data'] is Map && 
            (result['data'] as Map).containsKey('error')) {
          
          final errorMsg = result['data']['error'].toString();
          if (errorMsg.contains('Email belum diverifikasi')) {
            // Ekstrak email dari pesan error
            final emailMatch = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}')
                .firstMatch(errorMsg);
            final email = emailMatch != null ? emailMatch.group(0) : emailController.text.trim();
            
            // Tampilkan dialog email belum diverifikasi
            showEmailVerificationDialog(context, email ?? '', result);
            return false;
          }
        }

        // Jika bukan error email belum diverifikasi, tampilkan dialog error login
        showErrorDialog(context, 'Login Gagal', 
          'Pesan: ${result['message']}\n\n${result['data'] != null ? 'Detail: ${result['data']}' : ''}');
        return false;
      }
    } catch (e) {
      isLoading = false;
      print('ERROR login: $e');
      showErrorDialog(context, 'Terjadi Kesalahan', 'Error: $e');
      return false;
    }
  }

  // Metode register untuk customer
  Future<bool> registerCustomer(BuildContext context) async {
    // Validasi dasar input
    if (!validateRegistrationInputs(context)) return false;

    // Validasi tambahan untuk spesialisasi
    if (selectedSpecializations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu model jahit'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Validasi lokasi
    if ((latitudeController.text.isEmpty &&
            longitudeController.text.isNotEmpty) ||
        (latitudeController.text.isNotEmpty &&
            longitudeController.text.isEmpty)) {
      validationErrors['location'] =
          'Latitude dan longitude harus diisi keduanya';
      showValidationErrorDialog(context);
      return false;
    }

    // Jika tidak ada lokasi yang dimasukkan sama sekali, beritahu pengguna
    if (latitudeController.text.isEmpty && longitudeController.text.isEmpty) {
      // Tampilkan dialog konfirmasi untuk melanjutkan tanpa lokasi
      bool continueWithoutLocation =
          await _showNoLocationConfirmationDialog(context);
      if (!continueWithoutLocation) {
        return false;
      }
    }

    isLoading = true;

    try {
      // Log data yang akan dikirimkan
      print('Sending customer registration data to API:');
      print('Name: ${nameController.text.trim()}');
      print('Email: ${emailController.text.trim()}');
      print('Phone: ${phoneController.text.trim()}');
      print('Address: ${addressController.text.trim()}');
      print('Preferred Specializations: $selectedSpecializations');

      // Parsing latitude dan longitude jika ada
      double? latitude;
      double? longitude;

      if (latitudeController.text.isNotEmpty) {
        latitude = double.tryParse(latitudeController.text);
        print('Latitude: $latitude');
      } else {
        print('WARNING: Latitude controller text kosong!');
      }

      if (longitudeController.text.isNotEmpty) {
        longitude = double.tryParse(longitudeController.text);
        print('Longitude: $longitude');
      } else {
        print('WARNING: Longitude controller text kosong!');
      }

      final result = await ApiService.registerCustomer(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        phoneNumber: phoneController.text.trim(),
        address: addressController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        preferredSpecializations: selectedSpecializations,
      );

      isLoading = false;

      print('Customer registration result: $result');

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        String errorMessage =
            result['message'] ?? 'Terjadi kesalahan saat registrasi';

        // Cek apakah ada pesan error spesifik
        if (result.containsKey('errors') && result['errors'] != null) {
          try {
            final errors = result['errors'] as Map<String, dynamic>;
            if (errors.isNotEmpty) {
              errorMessage = '';
              validationErrors.clear(); // Reset validasi errors

              errors.forEach((key, value) {
                if (value is List && value.isNotEmpty) {
                  // Format field name untuk tampilan yang lebih baik
                  String fieldName = key.replaceAll('_', ' ');
                  fieldName =
                      fieldName[0].toUpperCase() + fieldName.substring(1);

                  String errorMsg = '• $fieldName: ${value.first}';
                  errorMessage += '$errorMsg\n';
                  validationErrors[key] = value.first.toString();
                } else if (value is String) {
                  // Format field name untuk tampilan yang lebih baik
                  String fieldName = key.replaceAll('_', ' ');
                  fieldName =
                      fieldName[0].toUpperCase() + fieldName.substring(1);

                  String errorMsg = '• $fieldName: $value';
                  errorMessage += '$errorMsg\n';
                  validationErrors[key] = value;
                }
              });

              // Tampilkan dialog error registrasi
              showRegistrationErrorDialog(context);
            }
          } catch (e) {
            print('Error processing error messages: $e');
            showErrorDialog(context, 'Registrasi Gagal', errorMessage);
          }
        } else {
          // Jika tidak ada errors detail, tampilkan pesan umum
          showErrorDialog(context, 'Registrasi Gagal', errorMessage);
        }

        return false;
      }
    } catch (e) {
      isLoading = false;
      print('Exception during customer registration: $e');
      showErrorDialog(context, 'Terjadi Kesalahan', 'Error: $e');
      return false;
    }
  }

  // Menampilkan dialog error validasi yang lebih jelas
  void showValidationErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(
              'Form Tidak Lengkap',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2552),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Harap perbaiki kesalahan berikut:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ...validationErrors.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'MENGERTI',
              style: TextStyle(
                color: Color(0xFF1A2552),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Menampilkan dialog error registrasi dengan detail validasi
  void showRegistrationErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(
              'Registrasi Gagal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2552),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Server menolak pendaftaran karena alasan berikut:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ...validationErrors.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cancel_outlined,
                            size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'MENGERTI',
              style: TextStyle(
                color: Color(0xFF1A2552),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Menampilkan dialog error umum
  void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2552),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'TUTUP',
              style: TextStyle(
                color: Color(0xFF1A2552),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Menampilkan dialog konfirmasi untuk mendaftar tanpa lokasi
  Future<bool> _showNoLocationConfirmationDialog(BuildContext context) async {
    bool result = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(
              'Lokasi Tidak Diatur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2552),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anda belum mengatur lokasi (koordinat) untuk akun Anda.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Lokasi dibutuhkan untuk memudahkan menemukan penjahit terdekat.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Apakah Anda ingin melanjutkan pendaftaran tanpa lokasi?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              result = false;
              Navigator.pop(context);
            },
            child: Text(
              'BATAL',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              result = true;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2552),
              foregroundColor: Colors.white,
            ),
            child: const Text('LANJUTKAN'),
          ),
        ],
      ),
    );
    return result;
  }

  // Fungsi publik untuk menampilkan dialog konfirmasi lokasi
  Future<bool> showNoLocationConfirmationDialog(BuildContext context) {
    return _showNoLocationConfirmationDialog(context);
  }

  // Update tampilan dialog verifikasi email untuk tidak menampilkan respons API
  void showEmailVerificationDialog(BuildContext context, String email, Map<String, dynamic> apiResponse) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 64,
                color: Color(0xFF1A2552),
              ),
              const SizedBox(height: 16),
              const Text(
                'Email Belum Diverifikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2552),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kami telah mengirimkan ulang email verifikasi ke $email',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Silakan periksa email Anda dan klik tautan verifikasi untuk mengaktifkan akun Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2552),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
