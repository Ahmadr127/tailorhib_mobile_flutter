import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/routes/routes.dart';
import '../../../core/services/booking_service.dart';

// Import widget-widget terpisah
import '../../../core/widgets/dropdown_field.dart';
import '../../../core/widgets/image_upload_field.dart';
import '../../../core/widgets/multiline_text_field.dart';
import '../../../core/widgets/label_text.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/services/api_service.dart';

class BookingPage extends StatefulWidget {
  final int tailorId;
  final String tailorName;
  final String? tailorImage;

  const BookingPage({
    super.key,
    required this.tailorId,
    required this.tailorName,
    this.tailorImage,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  String _selectedDate = 'Pilih Tanggal';
  String _selectedTime = 'Pilih Jam Temu';
  String _selectedService = 'Pilih Jenis Layanan';
  String _selectedCategory = 'Pilih Kategori';
  String _selectedPaymentMethod = 'transfer_bank'; // Default payment method
  String _imageDescription = 'Belum ada foto';
  final String _notes = '';
  File? _selectedImage;
  final _picker = ImagePicker();
  final _notesController = TextEditingController();

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      if (await permission.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Izin galeri ditolak permanen. Buka pengaturan untuk mengaktifkannya.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );

        final shouldOpenSettings = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Izin Diperlukan'),
                content: const Text(
                    'Untuk memilih gambar dari galeri, izin penyimpanan diperlukan. Buka pengaturan untuk memberikan izin?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Buka Pengaturan'),
                  ),
                ],
              ),
            ) ??
            false;

        if (shouldOpenSettings) {
          await openAppSettings();
        }
        return false;
      }

      var result = await permission.request();
      return result == PermissionStatus.granted;
    }
  }

  Future<void> _pickImage(bool isCamera) async {
    Navigator.pop(context);

    try {
      bool hasPermission = false;

      if (isCamera) {
        // Untuk kamera
        hasPermission = await _requestPermission(Permission.camera);
      } else {
        // Penanganan khusus untuk galeri - coba semua izin yang mungkin diperlukan
        // Cek Android versi
        bool isAndroid13OrAbove = await _isAndroid13OrAbove();

        if (isAndroid13OrAbove) {
          // Android 13+ menggunakan READ_MEDIA_IMAGES
          hasPermission = await _requestPermission(Permission.photos);
        } else {
          // Android 12 ke bawah menggunakan READ_EXTERNAL_STORAGE
          hasPermission = await _requestPermission(Permission.storage);
        }

        // Jika izin masih ditolak, coba cara alternatif
        if (!hasPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mencoba cara lain untuk mengakses galeri...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );

          // Coba langsung akses picker tanpa memeriksa izin
          hasPermission = true;
        }
      }

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Izin ditolak. Silakan aktifkan izin di pengaturan aplikasi.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // Tampilkan loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Memuat..."),
                ],
              ),
            ),
          );
        },
      );

      // Gunakan try-catch untuk setiap operasi picker
      XFile? pickedFile;
      try {
        if (isCamera) {
          pickedFile = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
          );
        } else {
          pickedFile = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 80,
          );
        }
      } catch (e) {
        print('Error pada picker: $e');
        // Tutup dialog loading jika masih ada
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Coba pendekatan alternatif jika pendekatan utama gagal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mencoba metode alternatif...'),
            duration: Duration(seconds: 1),
          ),
        );

        // Coba dengan picker lain atau pendekatan alternatif
        try {
          if (!isCamera) {
            // Hanya untuk galeri, coba dengan lowered permission
            pickedFile = await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 60, // Quality lebih rendah
              requestFullMetadata: false, // Jangan minta metadata penuh
            );
          }
        } catch (secondError) {
          print('Error pada pendekatan alternatif: $secondError');
        }
      }

      // Tutup dialog loading
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Proses hasil gambar jika ada
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile!.path);
          _imageDescription = isCamera
              ? 'Foto dari kamera dipilih'
              : 'Foto dari galeri dipilih';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCamera
                  ? 'Foto berhasil diambil dengan kamera'
                  : 'Foto berhasil dipilih dari galeri',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Tutup dialog loading jika masih ada
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error umum: $e');
      _showErrorDialog(e.toString());
    }
  }

  Future<bool> _isAndroid13OrAbove() async {
    // Ini hanya implementasi sederhana, dalam praktiknya Anda perlu
    // menggunakan platform channel untuk mendapatkan versi Android yang akurat
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        // Asumsi Android 13+ untuk saat ini
        // Dalam implementasi nyata, Anda perlu mendapatkan SDK version sebenarnya
        return true;
      }
    } catch (e) {
      print('Error checking Android version: $e');
    }
    return false;
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terjadi Kesalahan'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Detail error: $errorMessage'),
                const SizedBox(height: 10),
                const Text('Solusi yang bisa dicoba:'),
                const SizedBox(height: 5),
                const Text(
                    '1. Periksa izin penyimpanan di pengaturan aplikasi'),
                const Text('2. Pastikan aplikasi memiliki akses ke galeri'),
                const Text('3. Coba gunakan kamera sebagai alternatif'),
                const Text('4. Restart aplikasi dan coba lagi'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        );
      },
    );
  }

  void _selectImage() {
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Pilih Sumber Foto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.photo_library, color: Color(0xFF1A2552)),
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih foto dari galeri'),
                onTap: () => _pickImage(false),
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF1A2552)),
                ),
                title: const Text('Kamera'),
                subtitle: const Text('Ambil foto dengan kamera'),
                onTap: () => _pickImage(true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentMethodOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentOption('transfer_bank', 'Transfer Bank'),
              _buildPaymentOption('cod', 'Cash on Delivery (COD)'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(String value, String title) {
    return ListTile(
      title: Text(title),
      trailing: _selectedPaymentMethod == value
          ? const Icon(Icons.check_circle, color: Color(0xFF1A2552))
          : null,
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
        Navigator.pop(context);
      },
    );
  }

  // Menampilkan dialog berhasil booking dengan kode transaksi
  void _showBookingSuccessDialog(String transactionCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8F9FF), Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Animation/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2E7D32),
                  size: 60,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              const Text(
                'Booking Berhasil',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2552),
                ),
              ),
              const SizedBox(height: 20),
              
              // Transaction Code
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD0D9FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kode Transaksi:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transactionCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2552),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9E7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCE8A8)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFF5B100),
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pembayaran akan dilakukan setelah penjahit menentukan harga.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5F4C00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // OK Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.customerHome,
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'OK',
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
      ),
    );
  }

  // Menampilkan dialog error jadwal tidak tersedia
  void _showScheduleNotAvailableDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8F0), Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.event_busy,
                  color: Color(0xFFFF9800),
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              const Text(
                'Jadwal Tidak Tersedia',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2552),
                ),
              ),
              const SizedBox(height: 12),
              
              // Message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFE0B2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFFF9800),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5F4C00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Pilih Jadwal Lain',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text(
          'Detail Booking',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF1A2552),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          return false;
        },
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Penjahit
                Row(
                  children: [
                    // Foto penjahit - Hilangkan background
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.tailorImage != null &&
                              widget.tailorImage!.startsWith('/storage')
                          ? Image.network(
                              ApiService.getFullImageUrl(widget.tailorImage!),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/tailor_1.png',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              widget.tailorImage ??
                                  'assets/images/tailor_1.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Nama penjahit dan lokasi
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tailorName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Jalan Maritai No.45',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Info Pemesanan
                const Text(
                  'Info Pemesanan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Gunakan LabelText untuk label
                const LabelText(text: 'Tentukan Jam Temu:'),

                // Gunakan DropdownField untuk dropdown tanggal
                DropdownField(
                  value: _selectedDate,
                  onTap: _showDatePicker,
                ),

                const SizedBox(height: 12),

                // Dropdown jam
                DropdownField(
                  value: _selectedTime,
                  onTap: _showTimePicker,
                ),

                const SizedBox(height: 16),

                // Jenis Layanan
                const LabelText(text: 'Jenis Layanan:'),

                // Dropdown jenis layanan
                DropdownField(
                  value: _selectedService,
                  onTap: _showServiceOptions,
                ),

                const SizedBox(height: 12),

                // Kategori Pakaian
                const LabelText(text: 'Kategori Pakaian:'),

                // Dropdown kategori pakaian
                DropdownField(
                  value: _selectedCategory,
                  onTap: _showCategoryOptions,
                ),

                const SizedBox(height: 12),

                // Metode Pembayaran
                const LabelText(text: 'Metode Pembayaran:'),

                // Dropdown metode pembayaran
                DropdownField(
                  value: _getPaymentMethodDisplayName(),
                  onTap: _showPaymentMethodOptions,
                ),

                const SizedBox(height: 12),

                // Upload Foto - gunakan widget terpisah
                ImageUploadField(
                  description: _imageDescription,
                  selectedImage: _selectedImage,
                  onTap: _selectImage,
                ),

                const SizedBox(height: 12),

                // Detail Pesanan
                const LabelText(text: 'Detail Pesanan:'),

                // Text field detail
                MultilineTextField(
                  hintText: 'Tulis detail pesanan Anda di sini...',
                  controller: _notesController,
                ),

                const SizedBox(height: 30),

                // Tombol Konfirmasi Booking - gunakan CustomButton
                CustomButton(
                  text: 'Konfirmasi Booking',
                  onPressed: _confirmBooking,
                  borderRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method untuk mendapatkan nama tampilan metode pembayaran
  String _getPaymentMethodDisplayName() {
    switch (_selectedPaymentMethod) {
      case 'transfer_bank':
        return 'Transfer Bank';
      case 'cod':
        return 'Cash on Delivery (COD)';
      default:
        return 'Pilih Metode Pembayaran';
    }
  }

  void _showDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = "${date.day}/${date.month}/${date.year}";
      });
    }
  }

  void _showTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _selectedTime =
            "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  void _showServiceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Jenis Layanan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildServiceOption('Jahit Baru'),
              _buildServiceOption('Perbaikan'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceOption(String service) {
    return ListTile(
      title: Text(service),
      onTap: () {
        setState(() {
          _selectedService = service;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showCategoryOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Kategori Pakaian',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildCategoryOption('Atasan'),
              _buildCategoryOption('Bawahan'),
              _buildCategoryOption('Terusan'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryOption(String category) {
    return ListTile(
      title: Text(category),
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        Navigator.pop(context);
      },
    );
  }

  void _confirmBooking() async {
    // Validasi input
    if (_selectedDate == 'Pilih Tanggal' ||
        _selectedTime == 'Pilih Jam Temu' ||
        _selectedService == 'Pilih Jenis Layanan' ||
        _selectedCategory == 'Pilih Kategori') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data pemesanan')),
      );
      return;
    }

    // Variabel untuk menyimpan BuildContext
    final currentContext = context;

    // Tampilkan dialog konfirmasi
    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Booking'),
        content:
            const Text('Booking Anda akan dikirim ke penjahit. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              // Tutup dialog konfirmasi
              Navigator.pop(dialogContext);

              // Variabel untuk status loading dialog
              bool isLoadingShown = false;

              try {
                // Tampilkan loading dialog
                isLoadingShown = true;
                showDialog(
                  context: currentContext,
                  barrierDismissible: false,
                  builder: (loadingContext) => WillPopScope(
                    onWillPop: () async => false,
                    child: const Dialog(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 20),
                            Text("Mengirim booking..."),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                // Format tanggal dan waktu
                final dateParts = _selectedDate.split('/');
                final formattedDate =
                    '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}';

                // Format waktu ke format H:i
                final formattedTime = _formatTimeToHi(_selectedTime);

                // Kirim data booking ke API melalui BookingService
                final result = await BookingService.createBooking(
                  tailorId: widget.tailorId,
                  appointmentDate: formattedDate,
                  appointmentTime: formattedTime,
                  serviceType: _selectedService,
                  category: _selectedCategory,
                  notes: _notesController.text,
                  paymentMethod: _selectedPaymentMethod,
                  image: _selectedImage,
                );

                // Tutup loading dialog jika masih ditampilkan
                if (isLoadingShown && Navigator.canPop(currentContext)) {
                  Navigator.pop(currentContext);
                  isLoadingShown = false;
                }

                if (result['success']) {
                  // Booking berhasil dibuat
                  if (currentContext.mounted) {
                    final data = result['data'];
                    final transactionCode = data['transaction_code'] ?? 'UNKNOWN';
                    
                    // Tampilkan dialog sukses dengan kode transaksi
                    _showBookingSuccessDialog(transactionCode);
                  }
                } else {
                  // Cek apakah error karena jadwal tidak tersedia
                  if (result['data'] != null && 
                      result['data'] is Map && 
                      result['data'].containsKey('appointment')) {
                    
                    // Tampilkan dialog jadwal tidak tersedia
                    if (currentContext.mounted) {
                      _showScheduleNotAvailableDialog(result['data']['appointment']);
                    }
                  } else {
                    // Tampilkan pesan error umum
                    if (currentContext.mounted) {
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content:
                              Text(result['message'] ?? 'Gagal membuat booking'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                // Tutup loading dialog jika masih ditampilkan
                if (isLoadingShown && Navigator.canPop(currentContext)) {
                  Navigator.pop(currentContext);
                  isLoadingShown = false;
                }

                // Tampilkan pesan error
                if (currentContext.mounted) {
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    SnackBar(
                      content: Text('Terjadi kesalahan: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

  // Tambahkan method baru untuk memformat waktu ke format H:i
  String _formatTimeToHi(String timeString) {
    // Jika masih default, kembalikan waktu default yang valid
    if (timeString == 'Pilih Jam Temu') {
      return '09:00';
    }

    // Pemecahan string waktu
    final parts = timeString.split(':');
    if (parts.length != 2) {
      // Jika format tidak sesuai, kembalikan format default
      return '09:00';
    }

    // Pastikan jam dan menit dalam format yang benar
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;

    // Format ke H:i
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
