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
import '../../../core/widgets/gallery_grid_widget.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/controllers/gallery_controller.dart';
import '../../../core/models/gallery_item_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthController _authController = AuthController();
  final ProfileController _profileController = ProfileController();
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  final GalleryController _galleryController = GalleryController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _shopDescriptionController =
      TextEditingController();
  File? _profileImage;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _isRefreshingGallery = false;
  bool _isLoadingProfilePhoto = false;
  // Tambahkan Map untuk menyimpan mapping URL ke ID galeri
  final Map<String, int> _galleryUrlToId = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadGalleryData();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      setState(() {
        _nameController.text = userProvider.user!.name;
        _emailController.text = userProvider.user!.email;
        _phoneController.text = userProvider.user!.phoneNumber;
        _addressController.text = userProvider.user!.address;
        _shopDescriptionController.text =
            userProvider.user!.shopDescription ?? '';
      });
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _isLoadingProfilePhoto = true;
          _isUploadingPhoto = true;
        });

        AppLogger.info('Memulai upload foto profil: ${pickedFile.path}');
        _showLoadingDialog(context, 'Mengunggah foto profil...');

        await _profileController.uploadProfilePhoto(
            context, File(pickedFile.path));

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        setState(() {
          _isLoadingProfilePhoto = false;
          _isUploadingPhoto = false;
        });

        AppLogger.info('Upload foto profil selesai');
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isLoadingProfilePhoto = false;
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah foto: $e')),
      );
      AppLogger.error('Error in _pickAndUploadProfileImage: $e');
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Siapkan data untuk update
      final Map<String, dynamic> updateData = {
        'name': _nameController.text,
        'phone_number': _phoneController.text,
        'address': _addressController.text,
        'shop_description': _shopDescriptionController.text,
      };

      // Gunakan ProfileController untuk update profil
      final success =
          await _profileController.updateProfile(context, updateData);

      if (!success) {
        AppLogger.warning('Gagal memperbarui profil', tag: 'ProfilePage');
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

  @override
  Widget build(BuildContext context) {
    // Helper method untuk memastikan URL lengkap
    String getFullProfilePhotoUrl(String photoUrl) {
      print('DEBUG PROFILE: Processing photo URL: $photoUrl');

      // Jika URL sudah lengkap, kembalikan apa adanya
      if (photoUrl.startsWith('http')) {
        print('DEBUG PROFILE: Photo URL is already complete');
        return photoUrl;
      }

      // Jika tidak, tambahkan base URL
      final fullUrl =
          'http://10.0.2.2:8000${photoUrl.startsWith('/') ? '' : '/'}$photoUrl';
      print('DEBUG PROFILE: Converted to full URL: $fullUrl');
      return fullUrl;
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final User? user = userProvider.user;

        // Jika tidak ada data user, tampilkan loading
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Log info user untuk debugging
        print(
            'DEBUG PROFILE: User data loaded. Name: ${user.name}, Email: ${user.email}');
        print('DEBUG PROFILE: Profile photo URL: ${user.profilePhoto}');

        // Log gallery data
        if (user.gallery?.isNotEmpty ?? false) {
          print('DEBUG PROFILE: Gallery count: ${user.gallery!.length}');
        } else {
          print('DEBUG PROFILE: No gallery items available');
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Profil Penjahit',
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
                Navigator.pushReplacementNamed(context, AppRoutes.tailorHome);
              },
            ),
          ),
          body: SingleChildScrollView(
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
                          child: _isUploadingPhoto
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: _profileImage != null
                                      ? Image.file(
                                          _profileImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : user.profilePhoto != null
                                          ? Image.network(
                                              getFullProfilePhotoUrl(
                                                  user.profilePhoto!),
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  print(
                                                      'DEBUG PROFILE: Profile image loaded successfully');
                                                  return child;
                                                }
                                                print(
                                                    'DEBUG PROFILE: Loading profile image...');
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                print(
                                                    'DEBUG PROFILE: Error loading profile image: $error');
                                                return const Icon(
                                                  Icons.person,
                                                  size: 40,
                                                  color: Colors.grey,
                                                );
                                              },
                                            )
                                          : Image.asset(
                                              'assets/images/tailor_default.png',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
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
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploadingPhoto
                                ? null
                                : _pickAndUploadProfileImage,
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

                  // Badge Penjahit
                  // Container(
                  //   padding:
                  //       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  //   decoration: BoxDecoration(
                  //     color: const Color(0xFF1A2552).withOpacity(0.1),
                  //     borderRadius: BorderRadius.circular(12),
                  //   ),
                  //   child: Row(
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //       Icon(Icons.verified_user,
                  //           size: 16, color: const Color(0xFF1A2552)),
                  //       const SizedBox(width: 4),
                  //       Text(
                  //         'Penjahit Terverifikasi',
                  //         style: TextStyle(
                  //           fontSize: 12,
                  //           color: const Color(0xFF1A2552),
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  // Email Verified Badge
                  if (user.emailVerifiedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
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
                  const SizedBox(height: 16),

                  // Shop Description
                  _buildFormField(
                    label: 'Deskripsi Toko',
                    controller: _shopDescriptionController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // Tailor Gallery Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Galeri Toko',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2552),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tambahkan foto-foto terbaik karya Anda untuk menarik pelanggan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Menggunakan widget GalleryGridWidget
                      GalleryGridWidget(
                        galleryItems: user.gallery,
                        onTapItem: (imageUrl) => _showFullImage(imageUrl),
                        onLongPressItem: (imageUrl) =>
                            _showDeleteGalleryDialog(imageUrl),
                        onAddItem: () => _showAddGalleryDialog(),
                        isLoading: _isLoading &&
                            (user.gallery == null || user.gallery!.isEmpty),
                        isRefreshing: _isRefreshingGallery,
                      ),

                      const SizedBox(height: 16),
                    ],
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
                                    AppRoutes.loginTailor, (route) => false);

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
        );
      },
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    int maxLines = 1,
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
          maxLines: maxLines,
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
    _shopDescriptionController.dispose();
    _galleryController.dispose();
    super.dispose();
  }

  // Gallery methods
  Future<void> _showAddGalleryDialog() async {
    AppLogger.info('Membuka dialog tambah foto galeri', tag: 'Dialog');

    // Deklarasikan variabel di luar StatefulBuilder untuk dapat diakses dalam StatefulBuilder
    File? selectedImage;
    final titleController = TextEditingController(text: '');
    final descriptionController = TextEditingController(text: '');
    final categoryController = TextEditingController(text: 'umum');

    // Fokus node dengan logging
    final titleFocus = AppLogger.createLoggingFocusNode('Judul', tag: 'Dialog');
    final descriptionFocus =
        AppLogger.createLoggingFocusNode('Deskripsi', tag: 'Dialog');
    final categoryFocus =
        AppLogger.createLoggingFocusNode('Kategori', tag: 'Dialog');

    void logFormStatus() {
      AppLogger.form('Status validasi form', tag: 'Dialog', fields: {
        'gambar': selectedImage?.path,
        'judul': titleController.text,
        'deskripsi': descriptionController.text,
        'kategori': categoryController.text,
      });
    }

    // Tampilkan dialog form menggunakan StatefulBuilder agar bisa update UI dialog
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Cek apakah semua field terisi
          bool isFormValid = selectedImage != null &&
              titleController.text.isNotEmpty &&
              descriptionController.text.isNotEmpty &&
              categoryController.text.isNotEmpty;

          // Log saat widget dibuild ulang
          AppLogger.debug('Membangun dialog (form valid: $isFormValid)',
              tag: 'Dialog');

          return AlertDialog(
            title: const Text('Tambah Foto Galeri'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Foto yang ditambahkan akan muncul di profil Anda dan dapat dilihat oleh pelanggan.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Image preview
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 70,
                        );

                        if (image != null) {
                          AppLogger.debug('Gambar dipilih: ${image.path}',
                              tag: 'Dialog');
                          // Perbarui UI dengan gambar baru tanpa menutup dialog
                          setDialogState(() {
                            selectedImage = File(image.path);
                            logFormStatus();
                          });
                        }
                      },
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  selectedImage!,
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pilih Foto',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title field
                  TextField(
                    controller: titleController,
                    focusNode: titleFocus,
                    decoration: const InputDecoration(
                      labelText: 'Judul *',
                      hintText: 'Contoh: Kemeja Formal Pria',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      AppLogger.debug('Judul berubah: "$value"', tag: 'Dialog');
                      setDialogState(() {
                        logFormStatus();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  TextField(
                    controller: descriptionController,
                    focusNode: descriptionFocus,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi *',
                      hintText: 'Berikan deskripsi mengenai foto ini',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      AppLogger.debug('Deskripsi berubah: "$value"',
                          tag: 'Dialog');
                      setDialogState(() {
                        logFormStatus();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category field
                  TextField(
                    controller: categoryController,
                    focusNode: categoryFocus,
                    decoration: const InputDecoration(
                      labelText: 'Kategori *',
                      hintText: 'Contoh: Kemeja, Gaun, Celana',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      AppLogger.debug('Kategori berubah: "$value"',
                          tag: 'Dialog');
                      setDialogState(() {
                        logFormStatus();
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  AppLogger.debug('Dialog dibatalkan oleh pengguna',
                      tag: 'Dialog');
                  Navigator.of(context).pop();
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isFormValid
                    ? () {
                        AppLogger.info('Menyimpan data galeri', tag: 'Dialog');
                        AppLogger.form('Data yang akan disimpan',
                            tag: 'Dialog',
                            fields: {
                              'gambar': selectedImage?.path,
                              'judul': titleController.text,
                              'deskripsi': descriptionController.text,
                              'kategori': categoryController.text,
                            });

                        // Pastikan foto masih ada sebelum memanggil upload
                        if (selectedImage != null) {
                          Navigator.of(context).pop();
                          _processGalleryUpload(
                            selectedImage!,
                            titleController.text,
                            descriptionController.text,
                            categoryController.text,
                          );
                        }
                      }
                    : null, // Disable button if any required field is empty
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2552),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );

    // Dispose controllers dan focus nodes
    AppLogger.debug('Membuang controllers dan focus nodes', tag: 'Dialog');
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    titleFocus.dispose();
    descriptionFocus.dispose();
    categoryFocus.dispose();
  }

  Future<void> _processGalleryUpload(
      File imageFile, String title, String description, String category) async {
    try {
      setState(() {
        _isUploadingPhoto = true;
      });

      _showLoadingDialog(context, 'Mengunggah foto galeri...');

      final success = await _profileController.uploadGalleryPhoto(
        context,
        imageFile,
        title: title,
        description: description,
        category: category,
      );

      // Tutup dialog loading
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (success) {
        _refreshGallery();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto galeri berhasil ditambahkan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah foto: $e')),
      );
      AppLogger.error('Error in _processGalleryUpload: $e');
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  void _showFullImage(String imageUrl) {
    // Cari item galeri berdasarkan URL
    final galleryItem = _galleryController.galleryItems.firstWhere(
      (item) => item.fullPhotoUrl == imageUrl,
      orElse: () => GalleryItem(
        id: 0,
        title: '',
        description: '',
        category: '',
        photo: '',
        fullPhotoUrl: '',
        createdAt: '',
        updatedAt: '',
      ),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(galleryItem.title.isNotEmpty ? galleryItem.title : 'Foto Galeri'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteGalleryDialog(imageUrl);
                  },
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
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
                    return Container(
                      color: Colors.grey.shade100,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gagal memuat gambar',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (galleryItem.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      galleryItem.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            if (galleryItem.category.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.category,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      galleryItem.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteGalleryDialog(String imageUrl) {
    // Cari item galeri berdasarkan URL
    final galleryItem = _galleryController.galleryItems.firstWhere(
      (item) => item.fullPhotoUrl == imageUrl,
      orElse: () => GalleryItem(
        id: 0,
        title: '',
        description: '',
        category: '',
        photo: '',
        fullPhotoUrl: '',
        createdAt: '',
        updatedAt: '',
      ),
    );

    print('DEBUG DELETE: ==========================================');
    print('DEBUG DELETE: Memulai proses delete foto galeri');
    print('DEBUG DELETE: URL foto yang akan dihapus: $imageUrl');
    print('DEBUG DELETE: ID galeri: ${galleryItem.id}');
    print('DEBUG DELETE: ==========================================');

    if (galleryItem.id == 0) {
      print('DEBUG DELETE: Item galeri tidak ditemukan');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item galeri tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah Anda yakin ingin menghapus foto ini dari galeri?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tindakan ini tidak dapat dibatalkan.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.error_outline,
                              color: Colors.grey, size: 40),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (!context.mounted) return;

              _showLoadingDialog(context, 'Menghapus foto dari galeri...');

              try {
                final success = await _galleryController.deleteGalleryItem(
                  context,
                  galleryItem.id,
                );

                // Tutup dialog loading
                if (context.mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }

                if (success) {
                  print('DEBUG DELETE: Foto berhasil dihapus');
                  _refreshGallery();
                }
              } catch (e, stackTrace) {
                print('DEBUG DELETE: ==========================================');
                print('DEBUG DELETE: Error saat menghapus foto:');
                print('DEBUG DELETE: Error: $e');
                print('DEBUG DELETE: Stack trace: $stackTrace');
                print('DEBUG DELETE: ==========================================');

                // Pastikan dialog loading ditutup jika terjadi error
                if (context.mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus foto: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Metode untuk memuat data galeri
  Future<void> _loadGalleryData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      print('DEBUG GALLERY: Memulai proses load data galeri');
      AppLogger.info('Memuat data galeri...', tag: 'Gallery');
      
      // Gunakan GalleryController untuk fetch data
      final success = await _galleryController.fetchGalleryItems(context);
      
      if (success) {
        print('DEBUG GALLERY: Data galeri berhasil dimuat');
        print('DEBUG GALLERY: Jumlah item: ${_galleryController.galleryItems.length}');
        
        // Update galeri di UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.user != null) {
          final galleryUrls = _galleryController.galleryItems
              .map((item) => item.fullPhotoUrl)
              .toList();
          userProvider.updateUserGallery(galleryUrls);
          print('DEBUG GALLERY: Galeri berhasil diperbarui di UserProvider');
        }
      } else {
        print('DEBUG GALLERY: Gagal memuat data galeri');
      }
    } catch (e, stackTrace) {
      print('DEBUG GALLERY: Error saat load data galeri:');
      print('DEBUG GALLERY: Error: $e');
      print('DEBUG GALLERY: Stack trace: $stackTrace');
      AppLogger.error('Exception loading gallery', error: e, tag: 'Gallery');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('DEBUG GALLERY: Proses load data galeri selesai');
      }
    }
  }

  // Metode untuk merefresh galeri
  Future<void> _refreshGallery() async {
    if (!mounted) {
      AppLogger.warning(
          'Tidak dapat me-refresh galeri: widget tidak lagi mounted',
          tag: 'Gallery');
      return;
    }

    // Simpan referensi ke UserProvider di awal metode
    UserProvider? userProvider;
    try {
      userProvider = Provider.of<UserProvider>(context, listen: false);
    } catch (e) {
      AppLogger.error('Tidak dapat mengakses UserProvider untuk refresh galeri',
          error: e, tag: 'Gallery');
      return;
    }

    setState(() {
      _isRefreshingGallery = true;
    });

    try {
      AppLogger.info('Merefresh data galeri...', tag: 'Gallery');
      final result = await ApiService.getTailorGallery();
      AppLogger.api('Respons API refresh galeri:',
          data: result, tag: 'Gallery');

      if (result['success'] && result['data'] != null) {
        final List<dynamic> galleryData = result['data'];
        final List<String> galleryUrls = [];

        // Ekstrak URL foto dari data galeri
        AppLogger.debug('Mengekstrak URL foto dari ${galleryData.length} item',
            tag: 'Gallery');
        for (var item in galleryData) {
          if (item is Map<String, dynamic>) {
            String? photoUrl;

            // Prioritaskan full_photo_url jika tersedia
            if (item.containsKey('full_photo_url') &&
                item['full_photo_url'] != null) {
              photoUrl = item['full_photo_url'];
              AppLogger.debug('Menggunakan full_photo_url: $photoUrl',
                  tag: 'Gallery');
            }
            // Gunakan photo jika full_photo_url tidak tersedia
            else if (item.containsKey('photo') && item['photo'] != null) {
              // Gunakan utility method untuk mendapatkan URL lengkap
              String photo = item['photo'];
              photoUrl = ApiService.getFullImageUrl(photo);
              AppLogger.debug('Menggunakan photo dengan URL lengkap: $photoUrl',
                  tag: 'Gallery');
            }

            // Tambahkan URL ke list jika valid
            if (photoUrl != null && photoUrl.isNotEmpty) {
              galleryUrls.add(photoUrl);
            }
          }
        }

        AppLogger.info(
            'Jumlah foto galeri yang direfresh: ${galleryUrls.length}',
            tag: 'Gallery');

        // Update galeri di UserProvider jika masih valid
        if (userProvider.user != null) {
          await userProvider.updateUserGallery(galleryUrls);
          AppLogger.debug('Galeri berhasil direfresh di UserProvider',
              tag: 'Gallery');
        } else {
          AppLogger.warning(
              'User tidak tersedia, tidak dapat memperbarui galeri',
              tag: 'Gallery');
        }
      } else {
        AppLogger.warning('Error refreshing gallery: ${result['message']}',
            tag: 'Gallery');
      }
    } catch (e) {
      AppLogger.error('Exception refreshing gallery', error: e, tag: 'Gallery');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingGallery = false;
        });
      }
    }
  }
}
