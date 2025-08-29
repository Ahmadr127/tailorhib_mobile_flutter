import 'package:flutter/material.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/password_field.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/widgets/location_picker_dialog.dart';
import '../clothing_category_page.dart';
import '../auth/login_page.dart';

class RegisterCustomerPage extends StatefulWidget {
  const RegisterCustomerPage({super.key});

  @override
  State<RegisterCustomerPage> createState() => _RegisterCustomerPageState();
}

class _RegisterCustomerPageState extends State<RegisterCustomerPage> {
  final AuthController _authController = AuthController();
  bool _isLoading = false;
  bool _useLocation = false;

  @override
  void initState() {
    super.initState();
    // Periksa apakah koordinat sudah diisi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_authController.latitudeController.text.isNotEmpty &&
          _authController.longitudeController.text.isNotEmpty) {
        setState(() {
          _useLocation = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  // Function to show location picker dialog
  void _showLocationPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LocationPickerDialog(
          initialLatitude: _authController.latitudeController.text.isNotEmpty
              ? double.tryParse(_authController.latitudeController.text)
              : null,
          initialLongitude: _authController.longitudeController.text.isNotEmpty
              ? double.tryParse(_authController.longitudeController.text)
              : null,
          isTailor: false, // Dialog untuk pelanggan
          onLocationSelected: (latitude, longitude) {
            setState(() {
              _authController.latitudeController.text = latitude.toString();
              _authController.longitudeController.text = longitude.toString();
              _useLocation = true;
            });
          },
        );
      },
    );
  }

  // Tambahkan fungsi untuk menampilkan dialog sukses
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 5,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dengan ikon sukses
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Judul Dialog
                const Text(
                  'Registrasi Berhasil!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2552),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Pesan utama
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Text(
                    'Selamat! Akun Anda telah berhasil dibuat. Silakan login untuk melanjutkan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Informasi verifikasi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mail_outline,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tolong periksa email Anda untuk verifikasi akun Anda.',
                          style: TextStyle(
                            color: Color(0xFF0D47A1),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Tombol login
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Tutup dialog dan navigasi ke halaman login
                      Navigator.of(context).pop();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2552),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Login Sekarang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Daftar Akun Pelanggan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),

                      // Informasi penting
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Informasi Pendaftaran',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lokasi (koordinat) diperlukan untuk mendaftar sebagai pelanggan. Hal ini membantu kami menemukan penjahit terdekat untuk Anda.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // === INFORMASI AKUN ===
                      const Text(
                        'Informasi Akun',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2552),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email field
                      CustomTextField(
                        controller: _authController.emailController,
                        labelText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),

                      // Password field
                      PasswordField(
                        controller: _authController.passwordController,
                        labelText: 'Password',
                        hintText: 'Minimal 8 karakter',
                      ),
                      const SizedBox(height: 20),

                      // Konfirmasi Password field
                      PasswordField(
                        controller: _authController.confirmPasswordController,
                        labelText: 'Konfirmasi Password',
                      ),
                      const SizedBox(height: 30),

                      // === INFORMASI PRIBADI ===
                      const Text(
                        'Informasi Pribadi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2552),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nama field
                      CustomTextField(
                        controller: _authController.nameController,
                        labelText: 'Nama',
                      ),
                      const SizedBox(height: 20),

                      // No Handphone field
                      CustomTextField(
                        controller: _authController.phoneController,
                        labelText: 'No Handphone',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      // Alamat field
                      CustomTextField(
                        controller: _authController.addressController,
                        labelText: 'Alamat',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Lokasi (Peta)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _useLocation
                                ? const Color(0xFF1A2552)
                                : Colors.red
                                    .shade300, // Red border jika belum diatur
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            // Header lokasi
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Baris pertama: Judul dan tombol
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        color: _useLocation
                                            ? const Color(0xFF1A2552)
                                            : Colors.red
                                                .shade400, // Red icon jika belum diatur
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Text(
                                              'Lokasi Anda',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: _useLocation
                                                    ? const Color(0xFF1A2552)
                                                    : Colors.red
                                                        .shade400, // Red text jika belum diatur
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '(Wajib)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red.shade400,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: _showLocationPickerDialog,
                                        icon: const Icon(Icons.map_outlined,
                                            size: 16),
                                        label: Text(
                                            _useLocation ? 'Ubah' : 'Pilih'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _useLocation
                                              ? const Color(0xFF1A2552)
                                              : Colors.red
                                                  .shade400, // Red button jika belum diatur
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          minimumSize: const Size(60, 30),
                                          textStyle:
                                              const TextStyle(fontSize: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Baris kedua: Informasi koordinat
                                  const SizedBox(height: 4),
                                  if (_useLocation &&
                                      _authController
                                          .latitudeController.text.isNotEmpty)
                                    Text(
                                      'Lat: ${double.parse(_authController.latitudeController.text).toStringAsFixed(6)}, Lng: ${double.parse(_authController.longitudeController.text).toStringAsFixed(6)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    )
                                  else
                                    Text(
                                      'Belum diatur - diperlukan untuk menemukan penjahit terdekat',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade300,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Lanjut button
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: CustomButton(
                  text: 'Lanjut',
                  isLoading: _isLoading,
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    // Validasi input
                    if (!_authController.validateRegistrationInputs(context)) {
                      setState(() {
                        _isLoading = false;
                      });
                      return;
                    }

                    // Update flag lokasi berdasarkan nilai koordinat
                    if (_authController.latitudeController.text.isNotEmpty &&
                        _authController.longitudeController.text.isNotEmpty) {
                      setState(() {
                        _useLocation = true;
                      });
                    }

                    // Validasi tambahan untuk lokasi jika belum diatur
                    if (!_useLocation) {
                      // Tampilkan dialog konfirmasi
                      bool continueWithoutLocation = await _authController
                          .showNoLocationConfirmationDialog(context);
                      if (!continueWithoutLocation) {
                        setState(() {
                          _isLoading = false;
                        });
                        return;
                      }
                    }

                    // Cek dan log koordinat sebelum navigasi
                    print(
                        'Koordinat yang akan diteruskan ke ClothingCategoryPage:');
                    print(
                        'Latitude: ${_authController.latitudeController.text}');
                    print(
                        'Longitude: ${_authController.longitudeController.text}');

                    // Lanjut ke halaman pemilihan model jahit
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClothingCategoryPage(
                          email: _authController.emailController.text,
                          name: _authController.nameController.text,
                          phone: _authController.phoneController.text,
                          address: _authController.addressController.text,
                          password: _authController.passwordController.text,
                          latitude:
                              _authController.latitudeController.text.isNotEmpty
                                  ? double.tryParse(
                                      _authController.latitudeController.text)
                                  : null,
                          longitude: _authController
                                  .longitudeController.text.isNotEmpty
                              ? double.tryParse(
                                  _authController.longitudeController.text)
                              : null,
                          isTailor: false, // Menandakan ini adalah pelanggan
                          onRegistrationSuccess: () {
                            // Tampilkan dialog sukses setelah registrasi berhasil
                            _showSuccessDialog();
                          },
                        ),
                      ),
                    ).then((_) {
                      setState(() {
                        _isLoading = false;
                      });
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
