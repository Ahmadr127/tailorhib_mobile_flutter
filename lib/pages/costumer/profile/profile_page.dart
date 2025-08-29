import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../core/widgets/custom_button.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/controllers/profile_controller.dart';
import '../../../core/routes/routes.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/utils/url_helper.dart';
import '../../../core/utils/logger.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthController _authController = AuthController();
  final ProfileController _profileController = ProfileController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  File? _profileImage;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchProfileFromAPI();
  }

  Future<void> _fetchProfileFromAPI() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      // Gunakan ProfileController untuk memuat profil dari API
      AppLogger.info('Memuat profil dari API', tag: 'ProfilePage');

      final success = await _profileController.loadUserProfile(context);

      if (success) {
        AppLogger.info('Profil berhasil dimuat dari API', tag: 'ProfilePage');
        // Perbarui data form dengan data terbaru
        _loadUserData();
      } else {
        AppLogger.error('Gagal memuat profil dari API', tag: 'ProfilePage');
      }
    } catch (e) {
      AppLogger.error('Exception saat memuat profil dari API',
          error: e, tag: 'ProfilePage');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      setState(() {
        _nameController.text = userProvider.user!.name;
        _emailController.text = userProvider.user!.email;
        _phoneController.text = userProvider.user!.phoneNumber;
        _addressController.text = userProvider.user!.address;
      });
    }
  }

  Future<void> _pickImage() async {
    // Cegah membuka picker jika sudah aktif atau sedang mengupload
    if (_isUploadingPhoto) {
      AppLogger.warning('Image picker sudah aktif, abaikan request',
          tag: 'ProfilePage');
      return;
    }

    try {
      setState(() {
        _isUploadingPhoto = true;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Kompresi kualitas gambar untuk mengurangi ukuran
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });

        // Upload foto langsung setelah dipilih
        await _uploadProfilePhoto();
      } else {
        // User membatalkan pemilihan foto
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error saat memilih gambar',
          error: e, tag: 'ProfilePage');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  Future<void> _uploadProfilePhoto() async {
    if (_profileImage == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      // Upload foto profil menggunakan ProfileController
      final success =
          await _profileController.uploadProfilePhoto(context, _profileImage!);

      if (success) {
        setState(() {
          // Reset _profileImage setelah berhasil upload
          _profileImage = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengupload foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Siapkan data untuk update
      final Map<String, dynamic> updateData = {
        'name': _nameController.text,
        'email': _emailController.text, // tambahkan email
        'phone_number': _phoneController.text,
        'address': _addressController.text,
      };

      // Tambahkan latitude dan longitude jika tersedia
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user?.latitude != null &&
          userProvider.user?.longitude != null) {
        updateData['latitude'] = userProvider.user!.latitude;
        updateData['longitude'] = userProvider.user!.longitude;
      }

      AppLogger.debug('Data yang akan diupdate: $updateData',
          tag: 'ProfilePage');

      // Gunakan ProfileController untuk update profil
      final success =
          await _profileController.updateProfile(context, updateData);

      if (success) {
        // Refresh data setelah berhasil update
        await _profileController.loadUserProfile(context);
      }
    } catch (e) {
      AppLogger.error('Error saat update profil', error: e, tag: 'ProfilePage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
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

  // Tambahkan fungsi untuk refresh profile
  Future<void> _refreshProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoadingProfile = true;
    });

    try {
      AppLogger.info('Memuat ulang profil pengguna', tag: 'ProfilePage');
      await _fetchProfileFromAPI();

      AppLogger.info('Profil berhasil dimuat ulang', tag: 'ProfilePage');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      AppLogger.error('Gagal memuat ulang profil',
          error: e, tag: 'ProfilePage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Helper method untuk memastikan URL lengkap
    String getFullPhotoUrl(String? photoUrl) {
      if (photoUrl == null || photoUrl.isEmpty) {
        print('DEBUG COSTUMER PROFILE: Photo URL is null or empty');
        return '';
      }

      print('DEBUG COSTUMER PROFILE: Processing photo URL: $photoUrl');

      // Gunakan UrlHelper untuk mendapatkan URL lengkap
      final fullUrl = UrlHelper.getFullImageUrl(photoUrl);
      print('DEBUG COSTUMER PROFILE: Converted to full URL: $fullUrl');
      return fullUrl;
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final User? user = userProvider.user;

        // Jika tidak ada data user atau sedang memuat profil, tampilkan loading
        if (user == null || _isLoadingProfile) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Log info user untuk debugging
        print(
            'DEBUG COSTUMER PROFILE: User data loaded. Name: ${user.name}, Email: ${user.email}');
        print(
            'DEBUG COSTUMER PROFILE: Profile photo URL: ${user.profilePhoto}');

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Profil Pelanggan',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF1A2552),
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.white,
            iconTheme: const IconThemeData(color: Color(0xFF1A2552)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () {
                // Kembali ke halaman utama
                Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
              },
            ),
            actions: [
              // Tambahkan tombol refresh di AppBar
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF1A2552)),
                onPressed: _refreshProfile,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: _buildProfileImage(user, getFullPhotoUrl),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingPhoto ? null : _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: _isUploadingPhoto
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Verified Badge
                    if (user.emailVerifiedAt != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified,
                                size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Email Terverifikasi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Profile Form
                    _buildFormField(
                      label: 'Nama',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      label: 'Email',
                      controller: _emailController,
                      readOnly: true, // Email tidak bisa diubah
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      label: 'No. Handphone',
                      controller: _phoneController,
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      label: 'Alamat',
                      controller: _addressController,
                    ),

                    // Tambahkan bagian lokasi jika ada
                    if (user.latitude != null && user.longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lokasi',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Latitude: ${user.latitude}, Longitude: ${user.longitude}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Update Button
                    CustomButton(
                      text: 'Update Profil',
                      onPressed: _updateProfile,
                      isLoading: _isLoading,
                      borderRadius: 8,
                      backgroundColor: const Color(0xFF1E3A8A),
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    CustomButton(
                      text: 'Logout',
                      onPressed: () {
                        // Tampilkan dialog konfirmasi logout
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Konfirmasi Logout'),
                            content: const Text(
                                'Apakah Anda yakin ingin keluar dari aplikasi?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Tutup dialog
                                },
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Tampilkan loading
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  );

                                  // Proses logout
                                  await _authController.logout(context);

                                  // Tutup loading dialog
                                  Navigator.pop(context);

                                  // Tutup dialog konfirmasi
                                  Navigator.pop(context);

                                  // Navigasi ke halaman login
                                  Navigator.pushNamedAndRemoveUntil(context,
                                      AppRoutes.login, (route) => false);

                                  // Tampilkan pesan sukses
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Berhasil logout'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                child: const Text('Logout',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      borderRadius: 8,
                      backgroundColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method untuk membangun tampilan foto profil
  Widget _buildProfileImage(
      User user, String Function(String?) getFullPhotoUrl) {
    if (_isUploadingPhoto) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_profileImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.file(
          _profileImage!,
          fit: BoxFit.cover,
        ),
      );
    }

    if (user.profilePhoto != null && user.profilePhoto!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.network(
          getFullPhotoUrl(user.profilePhoto),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print(
                  'DEBUG COSTUMER PROFILE: Profile image loaded successfully');
              return child;
            }
            print('DEBUG COSTUMER PROFILE: Loading profile image...');
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print(
                'DEBUG COSTUMER PROFILE: Error loading profile image: $error');
            print(
                'DEBUG COSTUMER PROFILE: Failed URL: ${getFullPhotoUrl(user.profilePhoto)}');
            return const Icon(
              Icons.person,
              size: 40,
              color: Colors.grey,
            );
          },
        ),
      );
    }

    // Default image
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: Image.asset(
        'assets/images/tailor_default.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1A2552)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
