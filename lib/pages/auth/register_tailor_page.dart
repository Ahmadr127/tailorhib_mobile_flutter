import 'package:flutter/material.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/password_field.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/widgets/location_picker_dialog.dart';
import '../clothing_category_page.dart';

class RegisterTailorPage extends StatefulWidget {
  const RegisterTailorPage({super.key});

  @override
  State<RegisterTailorPage> createState() => _RegisterTailorPageState();
}

class _RegisterTailorPageState extends State<RegisterTailorPage> {
  final AuthController _authController = AuthController();
  bool _isLoading = false;
  bool _useLocation =
      false; // untuk mengontrol apakah menggunakan lokasi atau tidak

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
          isTailor: true, // Dialog untuk penjahit
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Daftar Akun Penjahit',
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
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                      const SizedBox(height: 30),

                      // === INFORMASI TOKO ===
                      const Text(
                        'Informasi Toko',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2552),
                        ),
                      ),
                      const SizedBox(height: 16),



                      // Deskripsi Toko field
                      CustomTextField(
                        controller: _authController.shopDescriptionController,
                        labelText: 'Deskripsi Toko',
                        maxLines: 3,
                        hintText:
                            'Jelaskan secara singkat tentang toko/jasa jahit Anda',
                      ),
                      const SizedBox(height: 20),



                      // Alamat field
                      CustomTextField(
                        controller: _authController.addressController,
                        labelText: 'Alamat Toko',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Lokasi Toko (Peta)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
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
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Lokasi Toko',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: _useLocation
                                                ? const Color(0xFF1A2552)
                                                : Colors.grey.shade700,
                                          ),
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
                                          backgroundColor:
                                              const Color(0xFF1A2552),
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
                                      'Belum diatur',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Preview peta (jika lokasi sudah dipilih)
                            if (_useLocation &&
                                _authController
                                    .latitudeController.text.isNotEmpty)
                              Container(
                                height: 120,
                                width: double.infinity,
                                margin:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  color: const Color(0xFFE0E0E0),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Color(0xFF1A2552),
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Lat: ${double.parse(_authController.latitudeController.text).toStringAsFixed(6)}\nLng: ${double.parse(_authController.longitudeController.text).toStringAsFixed(6)}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
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
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });

                    // Validasi input tanpa melakukan registrasi
                    if (_validateBasicInfo(context)) {
                      // Update flag lokasi berdasarkan nilai koordinat
                      if (_authController.latitudeController.text.isNotEmpty &&
                          _authController.longitudeController.text.isNotEmpty) {
                        setState(() {
                          _useLocation = true;
                        });
                      }

                      // Lanjut ke halaman pemilihan spesialisasi
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClothingCategoryPage(
                            email: _authController.emailController.text,
                            name: _authController.nameController.text,
                            phone: _authController.phoneController.text,
                            address: _authController.addressController.text,
                            password: _authController.passwordController.text,
                            storeName: _authController.nameController.text,
                            experience: '0',
                            shopDescription:
                                _authController.shopDescriptionController.text,
                            latitude: _authController
                                    .latitudeController.text.isNotEmpty
                                ? double.tryParse(
                                    _authController.latitudeController.text)
                                : null,
                            longitude: _authController
                                    .longitudeController.text.isNotEmpty
                                ? double.tryParse(
                                    _authController.longitudeController.text)
                                : null,
                            isTailor: true, // Menandakan ini adalah penjahit
                          ),
                        ),
                      ).then((_) {
                        setState(() {
                          _isLoading = false;
                        });
                      });
                    } else {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Metode untuk validasi data dasar
  bool _validateBasicInfo(BuildContext context) {
    // Cek field yang kosong
    if (_authController.emailController.text.isEmpty ||
        _authController.nameController.text.isEmpty ||

        _authController.shopDescriptionController.text.isEmpty ||

        _authController.phoneController.text.isEmpty ||
        _authController.addressController.text.isEmpty ||
        _authController.passwordController.text.isEmpty ||
        _authController.confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Validasi password minimal 8 karakter
    if (_authController.passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password harus minimal 8 karakter'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Validasi password dan konfirmasi password
    if (_authController.passwordController.text !=
        _authController.confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password dan konfirmasi password harus sama'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Validasi format email sederhana
    if (!_authController.emailController.text.contains('@') ||
        !_authController.emailController.text.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format email tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }
}
