import 'package:flutter/material.dart';
import '../core/widgets/category_card.dart';
import '../core/controllers/auth_controller.dart';
import '../core/controllers/category_controller.dart';
import '../core/widgets/custom_button.dart';
import '../core/services/api_service.dart';

class ClothingCategoryPage extends StatefulWidget {
  final String email;
  final String name;
  final String phone;
  final String address;
  final String password;
  final String? storeName;
  final String? experience;
  final String? shopDescription;
  final double? latitude;
  final double? longitude;
  final bool isTailor;
  final VoidCallback? onRegistrationSuccess;

  const ClothingCategoryPage({
    super.key,
    required this.email,
    required this.name,
    required this.phone,
    required this.address,
    required this.password,
    this.storeName,
    this.experience,
    this.shopDescription,
    this.latitude,
    this.longitude,
    this.isTailor = false,
    this.onRegistrationSuccess,
  });

  @override
  State<ClothingCategoryPage> createState() => _ClothingCategoryPageState();
}

class _ClothingCategoryPageState extends State<ClothingCategoryPage> {
  final AuthController _authController = AuthController();
  final CategoryController _categoryController = CategoryController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFormData();
    _loadSpecializations();
  }

  void _loadFormData() {
    // Transfer data from widget to auth controller
    _authController.emailController.text = widget.email;
    _authController.nameController.text = widget.name;
    _authController.phoneController.text = widget.phone;
    _authController.addressController.text = widget.address;
    _authController.passwordController.text = widget.password;
    _authController.confirmPasswordController.text = widget.password;

    // Load coordinates for both tailor and customer if available
    if (widget.latitude != null) {
      _authController.latitudeController.text = widget.latitude.toString();
      print('Loading latitude: ${widget.latitude}');
    }

    if (widget.longitude != null) {
      _authController.longitudeController.text = widget.longitude.toString();
      print('Loading longitude: ${widget.longitude}');
    }

    if (widget.isTailor) {
      _authController.storeNameController.text = widget.storeName ?? '';
      _authController.experienceController.text = widget.experience ?? '';
      _authController.shopDescriptionController.text =
          widget.shopDescription ?? '';
    }
  }

  Future<void> _loadSpecializations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Menggunakan ApiService untuk mendapatkan daftar spesialisasi
      final specializations = await ApiService.getSpecializations();
      print('Loaded ${specializations.length} specializations to display');

      if (mounted) {
        setState(() {
          _authController.availableSpecializations = specializations;
          // Inisialisasi data kategori dari API
          _categoryController.initializeFromApi(specializations);
        });
      }
    } catch (e) {
      print('Error loading specializations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat spesialisasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleRegistrationSuccess() {
    if (widget.onRegistrationSuccess != null) {
      widget.onRegistrationSuccess!();
    } else {
      // Default behavior jika callback tidak disediakan
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
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                      ),
                Icon(
                  Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 70,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Judul Dialog
                Text(
                    'Registrasi ${widget.isTailor ? 'Penjahit' : 'Pelanggan'} Berhasil!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2552),
                    ),
                  textAlign: TextAlign.center,
                ),
                  const SizedBox(height: 16),
                  
                  // Pesan utama
                Text(
                    widget.isTailor
                        ? 'Selamat! Akun penjahit Anda telah berhasil dibuat dan siap digunakan.'
                        : 'Selamat! Akun Anda telah berhasil dibuat.',
                  textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Informasi verifikasi
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.mail_outline,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Verifikasi Email',
                                style: TextStyle(
                                  color: Color(0xFF0D47A1),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kami telah mengirimkan email verifikasi ke ${_authController.emailController.text}. Harap periksa email Anda dan klik tautan verifikasi untuk mengaktifkan akun Anda.',
                                style: const TextStyle(
                                  color: Color(0xFF0D47A1),
                                  fontSize: 14,
                                ),
                              ),
                            ],
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
                  Navigator.of(context).pop();
                  // Navigasi ke halaman login
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    widget.isTailor ? '/login-tailor' : '/login',
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
                        'LOGIN SEKARANG',
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
  }

  // Tampilkan dialog error spesialisasi
  void _showSpecializationErrorDialog(BuildContext context, String userType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text(
              'Spesialisasi Diperlukan',
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
            Text(
              userType == "penjahit"
                  ? 'Anda belum memilih spesialisasi untuk akun penjahit Anda.'
                  : 'Anda belum memilih model jahit kesukaan.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              userType == "penjahit"
                  ? 'Harap pilih minimal satu spesialisasi untuk membuat profil penjahit yang lengkap dan memudahkan pelanggan menemukan jasa Anda.'
                  : 'Harap pilih minimal satu model jahit kesukaan untuk membantu kami merekomendasikan penjahit yang sesuai dengan preferensi Anda.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final String pageTitle = widget.isTailor
        ? 'Spesialis Kemampuan Kamu?'
        : 'Apa Model Jahit Kesukaan Kamu?';

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
        title: Text(
          pageTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSpecializationsList(),
              ),
              // Daftar button
              Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 
                    10 : 20.0, 
                  top: 10,
                ),
                child: CustomButton(
                  text: 'Daftar',
                  isLoading: _isLoading,
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      if (widget.isTailor) {
                        // Jika tidak ada spesialisasi yang dipilih
                        if (_authController.selectedSpecializations.isEmpty) {
                          // Tampilkan dialog error spesialisasi
                          _showSpecializationErrorDialog(context, "penjahit");
                          return;
                        }

                        // Log data registrasi
                        print(
                            'Memulai proses registrasi penjahit dengan spesialisasi:');
                        print('Email: ${_authController.emailController.text}');
                        print('Nama: ${_authController.nameController.text}');
                        print(
                            'Spesialisasi dipilih: ${_authController.selectedSpecializations}');

                        // Verifikasi bahwa koordinat terisi jika latitude/longitude dari halaman sebelumnya tersedia
                        if (widget.latitude != null &&
                            _authController.latitudeController.text.isEmpty) {
                          print(
                              'WARNING: Latitude hilang saat proses registrasi! widget.latitude: ${widget.latitude}');
                          _authController.latitudeController.text =
                              widget.latitude.toString();
                        }

                        if (widget.longitude != null &&
                            _authController.longitudeController.text.isEmpty) {
                          print(
                              'WARNING: Longitude hilang saat proses registrasi! widget.longitude: ${widget.longitude}');
                          _authController.longitudeController.text =
                              widget.longitude.toString();
                        }

                        // Proses registrasi penjahit
                        final success =
                            await _authController.registerTailor(context);
                        if (success) {
                          print(
                              'Registrasi berhasil, menampilkan dialog sukses');
                          _handleRegistrationSuccess();
                        } else {
                          print(
                              'Registrasi gagal, tetap pada halaman saat ini');
                          // Dialog error registrasi ditangani oleh AuthController
                        }
                      } else {
                        // Proses registrasi customer
                        if (_authController.selectedSpecializations.isEmpty) {
                          // Tampilkan dialog error spesialisasi
                          _showSpecializationErrorDialog(context, "pelanggan");
                          return;
                        }

                        // Log data registrasi pelanggan
                        print(
                            'Memulai proses registrasi pelanggan dengan spesialisasi:');
                        print('Email: ${_authController.emailController.text}');
                        print('Nama: ${_authController.nameController.text}');
                        print(
                            'Spesialisasi dipilih: ${_authController.selectedSpecializations}');
                        print(
                            'Koordinat Latitude: ${_authController.latitudeController.text}');
                        print(
                            'Koordinat Longitude: ${_authController.longitudeController.text}');

                        // Verifikasi bahwa koordinat terisi jika latitude/longitude dari halaman sebelumnya tersedia
                        if (widget.latitude != null &&
                            _authController.latitudeController.text.isEmpty) {
                          print(
                              'WARNING: Latitude hilang saat proses registrasi! widget.latitude: ${widget.latitude}');
                          _authController.latitudeController.text =
                              widget.latitude.toString();
                        }

                        if (widget.longitude != null &&
                            _authController.longitudeController.text.isEmpty) {
                          print(
                              'WARNING: Longitude hilang saat proses registrasi! widget.longitude: ${widget.longitude}');
                          _authController.longitudeController.text =
                              widget.longitude.toString();
                        }

                        // Proses registrasi pelanggan
                        final success =
                            await _authController.registerCustomer(context);
                        if (success) {
                          print(
                              'Registrasi pelanggan berhasil, navigasi ke halaman login');
                          _handleRegistrationSuccess();
                        } else {
                          print(
                              'Registrasi pelanggan gagal, tetap pada halaman saat ini');
                          // Dialog error registrasi ditangani oleh AuthController
                        }
                      }
                    } finally {
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

  Widget _buildSpecializationsList() {
    if (widget.isTailor) {
      // Tampilkan list spesialisasi dari API
      if (_authController.availableSpecializations.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.amber,
              ),
              SizedBox(height: 16),
              Text(
                'Tidak ada spesialisasi tersedia',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Silakan coba lagi nanti atau hubungi admin',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _categoryController.categoryGroups.length,
        itemBuilder: (context, groupIndex) {
          final categoryName = _categoryController.categoryGroups[groupIndex];
          final specializations =
              _categoryController.apiCategories[categoryName] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 8.0, right: 8.0, top: 16.0, bottom: 8.0),
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2552),
                  ),
                ),
              ),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: specializations.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemBuilder: (context, index) {
                    final spec = specializations[index];
                    final id = spec['id'] as int;
                    final name = spec['name'] as String;
                    final photoUrl = spec['fullPhotoUrl'] as String?;
                    final isSelected =
                        _authController.selectedSpecializations.contains(id);

                    // Debug logging
                    print('=== CategoryCard Debug Info ===');
                    print('Category Name: $name');
                    print(
                        'Image Path: ${photoUrl ?? 'assets/images/tailor_default.png'}');

                    // Determine if it's a network image based on URL pattern
                    final bool isNetworkImg = photoUrl != null &&
                        (photoUrl.startsWith('http://') ||
                            photoUrl.startsWith('https://'));

                    print('Is Network Image: $isNetworkImg');
                    print('Selected: $isSelected');
                    print('=============================');

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: CategoryCard(
                        imagePath:
                            photoUrl ?? 'assets/images/tailor_default.png',
                        categoryName: name,
                        isSelected: isSelected,
                        isNetworkImage: isNetworkImg,
                        onTap: () {
                          setState(() {
                            _authController.toggleSpecialization(id);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Menggunakan data dari API untuk tampilan kategori
      if (_categoryController.apiCategories.isEmpty) {
        return const Center(
          child: Text('Tidak ada kategori yang tersedia'),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _categoryController.categoryGroups.length,
        itemBuilder: (context, groupIndex) {
          final categoryName = _categoryController.categoryGroups[groupIndex];
          final specializations =
              _categoryController.apiCategories[categoryName] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 8.0, right: 8.0, top: 16.0, bottom: 8.0),
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2552),
                  ),
                ),
              ),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: specializations.length,
                  itemBuilder: (context, index) {
                    final spec = specializations[index];
                    final id = spec['id'] as int;
                    final name = spec['name'] as String;
                    final photoUrl = spec['fullPhotoUrl'] as String?;
                    final isSelected =
                        _authController.selectedSpecializations.contains(id);

                    // Debug logging
                    print('=== CategoryCard Debug Info ===');
                    print('Category Name: $name');
                    print(
                        'Image Path: ${photoUrl ?? 'assets/images/tailor_default.png'}');

                    // Determine if it's a network image based on URL pattern
                    final bool isNetworkImg = photoUrl != null &&
                        (photoUrl.startsWith('http://') ||
                            photoUrl.startsWith('https://'));

                    print('Is Network Image: $isNetworkImg');
                    print('Selected: $isSelected');
                    print('=============================');

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: CategoryCard(
                        imagePath:
                            photoUrl ?? 'assets/images/tailor_default.png',
                        categoryName: name,
                        isSelected: isSelected,
                        isNetworkImage: isNetworkImg,
                        onTap: () {
                          setState(() {
                            _authController.toggleSpecialization(id);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    }
  }
}
