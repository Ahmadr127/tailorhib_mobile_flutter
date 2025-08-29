import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/booking_controller.dart';
import 'dart:convert';
import '../../../core/utils/url_helper.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';

class OrderDetailPage extends StatefulWidget {
  final String status;
  final Map<String, dynamic> orderData;

  const OrderDetailPage({
    super.key,
    required this.status,
    required this.orderData,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();

  // Perbaiki helper method untuk konversi status
  String getApiStatus() {
    switch (status) {
      case 'waiting':
        return 'reservasi';
      case 'confirmation':
        return 'accepted';
      case 'processing':
        return 'diproses';
      case 'completed':
        return 'selesai';
      case 'canceled':
        return 'dibatalkan';
      default:
        return 'all'; // Gunakan 'all' sebagai default, bukan 'reservasi'
    }
  }
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  File? _designImage;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _datePickupController = TextEditingController();

  String _selectedService = 'Jahit Baru';
  String _selectedCategory = 'Atasan';
  String _tailorName = '';
  String _tailorImage = '';

  final Map<String, bool> _selectedSizes = {
    'Panjang Depan : 50 cm': false,
    'Lingkar Pinggang : 50 cm': false,
    'Lingkar paha : 20 cm': false,
    'Lingkar Pinggul : 50 cm': false,
    'Lingkar bahu : 20 cm': false,
    'Lingkar Paha : 20 cm': false,
  };

  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Debug info yang lebih detail
    print('DEBUG: ===== INITIALIZING ORDER DETAIL PAGE =====');
    print('DEBUG: Status: ${widget.status}');
    print('DEBUG: Order Data: ${widget.orderData}');
    print('DEBUG: Order Data Keys: ${widget.orderData.keys.toList()}');
    print('DEBUG: Order Data Values: ${widget.orderData.values.toList()}');

    try {
      // Debug untuk tailor data
      print('DEBUG: Tailor Data: ${widget.orderData['tailor']}');
      print('DEBUG: Tailor Name: ${widget.orderData['tailorName']}');
      print('DEBUG: Tailor Image: ${widget.orderData['tailorImage']}');

      // Set data from orderData dengan penanganan null yang lebih baik
      _tailorName = widget.orderData['tailorName']?.toString() ?? 'Penjahit';
      _tailorImage = widget.orderData['tailorImage']?.toString() ?? '';

      print('DEBUG: Set Tailor Name: $_tailorName');
      print('DEBUG: Set Tailor Image: $_tailorImage');

      // Pre-fill name dari data orderan
      _nameController.text = _tailorName;

      // Debug untuk price
      print('DEBUG: Price Data: ${widget.orderData['price']}');
      print('DEBUG: Price Type: ${widget.orderData['price']?.runtimeType}');

      // Set price dari data (default jika tidak ada)
      _priceController.text =
          (widget.orderData['price']?.toString() ?? '200.000');
      print('DEBUG: Set Price: ${_priceController.text}');

      // Debug untuk appointment data
      print(
          'DEBUG: Appointment Date Raw: ${widget.orderData['appointmentDate']}');
      print(
          'DEBUG: Appointment Time Raw: ${widget.orderData['appointmentTime']}');
      print('DEBUG: Service Type: ${widget.orderData['serviceType']}');
      print('DEBUG: Category: ${widget.orderData['category']}');

      // Pre-fill fields for any status dengan penanganan null yang lebih baik
      String? appointmentDate = widget.orderData['appointmentDate']?.toString();
      if (appointmentDate != null && appointmentDate.isNotEmpty) {
        _dateController.text = _formatDate(appointmentDate);
      }

      String? appointmentTime = widget.orderData['appointmentTime']?.toString();
      if (appointmentTime != null && appointmentTime.isNotEmpty) {
        _timeController.text = _formatBookingTime(appointmentTime);
      }

      _selectedService =
          widget.orderData['serviceType']?.toString() ?? 'Jahit Baru';
      _selectedCategory = widget.orderData['category']?.toString() ?? 'Atasan';

      print('DEBUG: Set Appointment Date: ${_dateController.text}');
      print('DEBUG: Set Appointment Time: ${_timeController.text}');
      print('DEBUG: Set Service Type: $_selectedService');
      print('DEBUG: Set Category: $_selectedCategory');

      // Panggil _loadBookingDetails setelah widget diinisialisasi
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('DEBUG: Calling _loadBookingDetails in post frame callback');
        _loadBookingDetails();
      });
    } catch (e, stackTrace) {
      print('ERROR: Exception in initState: $e');
      print('ERROR: Stack trace: $stackTrace');
      // Set default values jika terjadi error
      _datePickupController.text =
          _formatDate(DateTime.now().add(const Duration(days: 7)).toString());
      _dateController.text = '';
      _timeController.text = '';
      _selectedService = 'Jahit Baru';
      _selectedCategory = 'Atasan';
    }
  }

  // Perbaiki method _formatDate untuk menangani null dan format tanggal yang tidak valid
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '-';
    }

    try {
      // Jika tanggal sudah dalam format lokal (misalnya "16 April 2025")
      if (dateString.contains(' ') &&
          !dateString.contains('-') &&
          !dateString.contains('/')) {
        return dateString;
      }

      // Coba parse tanggal dari format ISO
      DateTime date;
      if (dateString.contains('T')) {
        // Format ISO dengan timezone
        date = DateTime.parse(dateString);
      } else if (dateString.contains('-')) {
        // Format YYYY-MM-DD
        final parts = dateString.split('-');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          throw const FormatException('Format tanggal tidak valid');
        }
      } else {
        // Coba parse format lainnya
        date = DateTime.parse(dateString);
      }

      final List<String> months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];

      String formattedDate =
          '${date.day} ${months[date.month - 1]} ${date.year}';
      print('DEBUG: Formatted date: $formattedDate from $dateString');
      return formattedDate;
    } catch (e) {
      print('ERROR: Gagal memformat tanggal: $dateString, error: $e');
      return '-';
    }
  }

  // Perbaiki method untuk format waktu booking
  String _formatBookingTime(String? time) {
    if (time == null || time.isEmpty) {
      return '-';
    }

    try {
      print('DEBUG: Formatting booking time: $time');

      // Jika waktu adalah "05:01" atau format jam:menit sederhana
      if (time.contains(':') && time.length <= 5) {
        final parts = time.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        String formattedTime =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        print('DEBUG: Formatted simple time: $formattedTime');
        return formattedTime;
      }

      // Jika format sudah HH:mm atau H:mm dengan teks tambahan
      if (time.contains(':')) {
        final parts = time.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);

          // Ambil menit saja tanpa detik/milisecond jika ada
          String minutePart = parts[1];
          if (minutePart.contains('.')) {
            minutePart = minutePart.split('.')[0];
          }
          if (minutePart.contains(' ')) {
            minutePart = minutePart.split(' ')[0];
          }

          final minute = int.parse(minutePart);

          // Format ke 24 jam
          String formattedTime =
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          print('DEBUG: Formatted complex time: $formattedTime');
          return formattedTime;
        }
      }

      // Coba parse sebagai full datetime jika bentuknya lengkap
      if (time.contains('T') || time.contains(' ')) {
        DateTime dateTime;
        if (time.contains('T')) {
          dateTime = DateTime.parse(time);
        } else {
          dateTime = DateTime.parse('2024-01-01 $time');
        }

        String formattedTime =
            '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        print('DEBUG: Formatted datetime time: $formattedTime');
        return formattedTime;
      }

      print('DEBUG: Using original time: $time');
      return time;
    } catch (e) {
      print('ERROR: Gagal memformat waktu: $time, error: $e');
      return '-';
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _designImage = File(image.path);
      });
    }
  }

  // Perbaiki method _loadBookingDetails untuk menangani null dengan lebih baik
  Future<void> _loadBookingDetails() async {
    try {
      print('DEBUG: ===== LOADING BOOKING DETAILS =====');
      print('DEBUG: Order Data ID: ${widget.orderData['id']}');
      print('DEBUG: Order Data Type: ${widget.orderData['id']?.runtimeType}');

      // Pastikan orderData memiliki semua informasi yang dibutuhkan
      if (widget.orderData.containsKey('id') && widget.orderData['id'] != null) {
        print('DEBUG: Using existing order data');
        setState(() {
          // Ambil data tanggal dan waktu dengan penanganan null yang lebih baik
          final appointmentDate = widget.orderData['appointmentDate'] ?? 
                                widget.orderData['appointment_date'] ?? '';
          final appointmentTime = widget.orderData['appointmentTime'] ?? 
                                widget.orderData['appointment_time'] ?? '';
          
          _dateController.text = appointmentDate.toString();
          _timeController.text = appointmentTime.toString();
          _nameController.text = widget.orderData['tailorName']?.toString() ?? '';
          _priceController.text = widget.orderData['price']?.toString() ?? '';

          print('DEBUG: Set Date Controller: ${_dateController.text}');
          print('DEBUG: Set Time Controller: ${_timeController.text}');
          print('DEBUG: Set Name Controller: ${_nameController.text}');
          print('DEBUG: Set Price Controller: ${_priceController.text}');

          // Tangani tanggal pengambilan dengan lebih baik
          String? pickupDate = widget.orderData['pickupDate'] ?? widget.orderData['pickup_date'];
          print('DEBUG: Pickup date from order data: $pickupDate');

          if (pickupDate == null || pickupDate.toString().isEmpty) {
            DateTime defaultDate = DateTime.now().add(const Duration(days: 7));
            _datePickupController.text = _formatDate(defaultDate.toString());
            print('DEBUG: Using default pickup date: ${_datePickupController.text}');
          } else {
            _datePickupController.text = _formatDate(pickupDate.toString());
            print('DEBUG: Using provided pickup date: ${_datePickupController.text}');
          }

          // Update selected values dengan penanganan null
          _selectedService = widget.orderData['serviceType']?.toString() ?? 
                           widget.orderData['service_type']?.toString() ?? 'Jahit Baru';
          _selectedCategory = widget.orderData['category']?.toString() ?? 'Atasan';
          _tailorName = widget.orderData['tailorName']?.toString() ?? '';

          print('DEBUG: Set Selected Service: $_selectedService');
          print('DEBUG: Set Selected Category: $_selectedCategory');
          print('DEBUG: Set Tailor Name: $_tailorName');

          // Dapatkan foto tailor dengan penanganan null
          String? tailorPhoto;
          if (widget.orderData['tailor'] != null) {
            print('DEBUG: Tailor object exists: ${widget.orderData['tailor']}');
            tailorPhoto = widget.orderData['tailor']['profile_photo']?.toString();
            print('DEBUG: Tailor photo from object: $tailorPhoto');
          }
          _tailorImage = tailorPhoto ?? widget.orderData['tailorImage']?.toString() ?? '';
          print('DEBUG: Set Tailor Image: $_tailorImage');
        });
        return;
      }

      // Fallback ke BookingController jika data tidak lengkap
      print('DEBUG: Falling back to BookingController data');
      final bookingController = Provider.of<BookingController>(context, listen: false);

      if (bookingController.bookings.isNotEmpty) {
        // Cari booking yang sesuai dengan ID
        final booking = bookingController.bookings.firstWhere(
          (b) => b.id == widget.orderData['id'],
          orElse: () => bookingController.bookings.first,
        );

        setState(() {
          _dateController.text = booking.appointmentDate ?? '';
          _timeController.text = booking.appointmentTime ?? '';
          _nameController.text = booking.getTailorName() ?? '';
          _priceController.text = booking.totalPrice ?? '';

          // Tangani tanggal pengambilan
          String? pickupDate = booking.pickupDate;
          if (pickupDate == null || pickupDate.isEmpty) {
            DateTime defaultDate = DateTime.now().add(const Duration(days: 7));
            _datePickupController.text = _formatDate(defaultDate.toString());
          } else {
            _datePickupController.text = _formatDate(pickupDate);
          }

          _selectedService = booking.serviceType ?? 'Jahit Baru';
          _selectedCategory = booking.category ?? 'Atasan';
          _tailorName = booking.getTailorName() ?? '';
          _tailorImage = booking.getTailorPhoto() ?? '';
        });
      }
    } catch (e, stackTrace) {
      print('ERROR: Exception during booking detail loading: $e');
      print('ERROR: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Tambahkan fungsi untuk melakukan submit rating
  Future<void> _submitRating(int bookingId) async {
    if (_rating == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan berikan rating terlebih dahulu'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Debug untuk ID booking
    print('DEBUG: Attempting to rate booking ID: $bookingId');

    if (bookingId <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID Booking tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Periksa autentikasi terlebih dahulu
      final authData = await AuthService.getAuthData();

      if (authData == null) {
        if (mounted) {
          // Tampilkan dialog login jika belum login
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Sesi Login Berakhir'),
              content: const Text(
                  'Sesi login Anda telah berakhir. Silakan login kembali untuk memberikan rating dan ulasan.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Arahkan ke halaman login
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login', (route) => false);
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final bookingController =
          Provider.of<BookingController>(context, listen: false);
      final result = await bookingController.rateBooking(
        bookingId,
        _rating.round(),
        _reviewController.text,
      );

      if (!mounted) return;

      // Cek apakah response mengandung error autentikasi
      if (result['error_type'] == 'auth_error' || 
          result['message']?.toString().toLowerCase().contains('unauthenticated') == true ||
          result['message']?.toString().toLowerCase().contains('unauthorized') == true) {
        // Tampilkan dialog login jika tidak terautentikasi
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Sesi Login Berakhir'),
            content: const Text(
                'Sesi login Anda telah berakhir. Silakan login kembali untuk memberikan rating dan ulasan.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Arahkan ke halaman login
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login', (route) => false);
                },
                child: const Text('Login'),
              ),
            ],
          ),
        );
        return;
      }
      
      // Cek apakah ada error validasi
      if (result['error_type'] == 'validation_error') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Validasi gagal. Periksa rating dan ulasan Anda.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Berhasil memberikan rating'),
            backgroundColor: Colors.green,
          ),
        );

        // Tampilkan dialog sukses
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 50),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                  // Check icon di dalam lingkaran hijau
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade500,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Judul "Rating Berhasil"
                  const Text(
                    'Rating Berhasil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2552),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Pesan terima kasih
                  const Text(
                    'Terima kasih atas ulasan Anda.\nKami sangat menghargai\nmasukan yang diberikan!',
              textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Tombol OK
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
                },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memberikan rating'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Pastikan controller dibersihkan
    _dateController.dispose();
    _timeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _datePickupController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building order detail with status: ${widget.status}');
    print('DEBUG: Order data: ${widget.orderData}');
    print('DEBUG: Is order completed? ${_isOrderCompleted()}');
    print('DEBUG: Has rating? ${_hasRating()}');
    print('DEBUG: Rating value: ${widget.orderData['rating']}');
    print('DEBUG: Review: ${widget.orderData['review']}');
    print('DEBUG: Booking ID: ${_getBookingId()}');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Color(0xFF1A2552),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gunakan format yang sama untuk semua status
                    _buildInfoCard(context),
                    const SizedBox(height: 12),
                    _buildOrderInfoCard(),
                ],
              ),
            ),

            // Bagian status pembayaran tetap ditampilkan untuk status yang sesuai
            if ((widget.status == 'processing' ||
                    widget.status == 'completed' ||
                    widget.status == 'canceled') &&
                widget.orderData['payment_status'] != 'paid' &&
                widget.orderData['paymentStatus'] != 'paid')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: _buildPaymentStatusSection(
                    widget.orderData['payment_status'] ??
                        widget.orderData['paymentStatus']),
              ),
              
            // Tampilkan tombol bayar jika pesanan selesai dan belum dibayar
            // Cek juga metode pembayaran bukan COD
            if (_isOrderCompleted() && 
                !_isPaymentPaid() && 
                widget.orderData['transaction_code'] != null && 
                widget.orderData['transaction_code'].toString().isNotEmpty &&
                (widget.orderData['payment_method'] ?? '').toString().toLowerCase() != 'cod' &&
                (widget.orderData['payment_method'] ?? '').toString().toLowerCase() != 'cash_on_delivery')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: _buildPaymentButton(
                  _getBookingId(),
                  widget.orderData['total_price']?.toString() ?? '0',
                  widget.orderData['transaction_code'].toString(),
                ),
              ),
              
            // Rating section untuk order yang sudah selesai
            if (_isOrderCompleted())
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildRatingSection(_getBookingId()),
              ),
              
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Update method _buildProcessingOrderDetails untuk tampilan yang lebih profesional dan lengkap
  Widget _buildProcessingOrderDetails() {
    final statusDetail = widget.orderData['statusDetail'] ?? '';
    final notes = widget.orderData['notes'];
    final serviceType = widget.orderData['serviceType'] ?? '';
    final category = widget.orderData['category'] ?? '';
    final totalPrice = widget.orderData['total_price']?.toString() ?? '0';
    
    // Data tambahan yang lebih lengkap
    final transactionCode = widget.orderData['transaction_code'] ?? '';
    final paymentMethod = widget.orderData['payment_method'] ?? '';
    final paymentStatus = widget.orderData['payment_status'] ?? widget.orderData['paymentStatus'] ?? '';
    final orderStatus = widget.orderData['status']?.toString().toLowerCase() ?? '';
    final createdAt = widget.orderData['created_at'] ?? '';
    final completedAt = widget.orderData['completed_at'] ?? '';
    final measurements = widget.orderData['measurements'];
    final pickupDate = widget.orderData['pickup_date'] ?? widget.orderData['pickupDate'] ?? '';
    
    // Periksa apakah pesanan sudah selesai dan belum dibayar
    // Juga cek apakah metode pembayaran bukan COD
    final bool canPayWithMidtrans = 
        orderStatus == 'selesai' && 
        paymentStatus != 'paid' && 
        totalPrice != '0' &&
        transactionCode.isNotEmpty &&
        paymentMethod.toLowerCase() != 'cod' &&
        paymentMethod.toLowerCase() != 'cash_on_delivery';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Header dengan status
        Row(
          children: [
              const Text(
                'Detail Pesanan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2552),
                ),
              ),
              const Spacer(),
              // Status badge
              _buildStatusBadge(orderStatus, statusDetail)
            ],
          ),
        const SizedBox(height: 16),
          const Divider(),
          
          // Status detail section
          _buildDetailSection('Status',
            Row(
            children: [
                Icon(_getStatusIcon(orderStatus), size: 18, color: _getStatusColor(orderStatus)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusDetail,
          style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(orderStatus),
                    ),
                  ),
                ),
              ],
            )
          ),
          
          // Jenis layanan & kategori
          _buildDetailSection('Jenis Layanan',
            Row(
                  children: [
                Icon(Icons.design_services, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                    Text(
                  serviceType,
                      style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                        color: Color(0xFF1A2552),
                      ),
                ),
              ],
            )
          ),
          
          _buildDetailSection('Kategori',
            Row(
              children: [
                Icon(Icons.category, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
            color: Color(0xFF1A2552),
          ),
        ),
              ],
            )
          ),
          
          // Kode transaksi
          if (transactionCode.isNotEmpty)
            _buildDetailSection('Kode Transaksi',
        Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD1DEFF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
            children: [
                    const Icon(Icons.receipt_long, size: 16, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                        transactionCode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                          ),
                        ),
                      ],
                    ),
              )
            ),
            
            // Metode pembayaran
            if (paymentMethod.isNotEmpty)
              _buildDetailSection('Metode Pembayaran',
                Row(
                  children: [
                    Icon(Icons.payment, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      _formatPaymentMethod(paymentMethod),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
            color: Color(0xFF1A2552),
          ),
        ),
                  ],
                )
              ),
            
            // Status pembayaran  
            _buildDetailSection('Status Pembayaran',
              _buildPaymentStatusBadge(paymentStatus)
            ),
            
            // Catatan
            if (notes != null && notes.toString().isNotEmpty)
              _buildDetailSection('Catatan',
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                    color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
                    notes.toString(),
              style: TextStyle(
                fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                )
              ),
          
            // Tanggal pesanan
            if (createdAt.isNotEmpty)
              _buildDetailSection('Tanggal Pesanan',
                Row(
                  children: [
                    Icon(Icons.date_range, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
              color: Color(0xFF1A2552),
            ),
          ),
                  ],
                )
              ),
          
            // Tanggal selesai jika sudah selesai atau dalam proses
            if ((completedAt != null && completedAt.isNotEmpty) || 
                (widget.orderData['completion_date'] != null && widget.orderData['completion_date'].toString().isNotEmpty))
              _buildDetailSection('Tanggal Selesai',
                Row(
              children: [
                    Icon(Icons.event_available, size: 18, color: Colors.green[600]),
                    const SizedBox(width: 8),
                  Text(
                      _formatDate(completedAt ?? widget.orderData['completion_date']),
                    style: TextStyle(
                      fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                )
              ),
            
            // Tanggal pengambilan jika sudah ada
            if (pickupDate.isNotEmpty)
              _buildDetailSection('Tanggal Pengambilan',
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_note, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                  Text(
                        _formatDate(pickupDate),
                    style: TextStyle(
                      fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                )
              ),
            
            // Tampilkan total harga jika ada
            if (totalPrice != '0')
              _buildDetailSection('Total Harga',
          Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
                  child: Row(
              children: [
                      const Icon(Icons.monetization_on, size: 18, color: Color(0xFF22C55E)),
                      const SizedBox(width: 8),
                  Text(
                        'Rp ${_formatCurrency(totalPrice)}',
                        style: const TextStyle(
                          fontSize: 16,
                      fontWeight: FontWeight.bold,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                )
              ),
            
            // Ukuran jika ada dan jenis perbaikan adalah jahit baru
            if (measurements != null && measurements.toString().isNotEmpty && serviceType.toLowerCase() == 'jahit baru')
              _buildMeasurementsSection(measurements.toString(), category),
            
            // Tombol bayar jika belum dibayar
            if (canPayWithMidtrans)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToPaymentPage(
                      _getBookingId(), 
                      totalPrice, 
                      transactionCode
                    ),
                    icon: const Icon(Icons.payment),
                    label: const Text('Bayar Sekarang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                        ),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }
  
  // Helper widget untuk section detail
  Widget _buildDetailSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
            title,
              style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }
  
  // Helper widget untuk menampilkan ukuran
  Widget _buildMeasurementsSection(String measurementsString, String category) {
    Map<String, dynamic> measurementsMap = {};
    
    try {
      // Coba parse measurements sebagai JSON
      measurementsMap = jsonDecode(measurementsString);
    } catch (e) {
      print('ERROR: Gagal parse measurements: $e');
      // Fallback jika parsing gagal, mencoba parse manual
      measurementsString = measurementsString.replaceAll('{', '').replaceAll('}', '');
      List<String> pairs = measurementsString.split(',');
      
      for (String pair in pairs) {
        if (pair.contains(':')) {
          List<String> keyValue = pair.split(':');
          if (keyValue.length >= 2) {
            String key = keyValue[0].trim().replaceAll('"', '').replaceAll("'", '');
            String value = keyValue[1].trim().replaceAll('"', '').replaceAll("'", '');
            measurementsMap[key] = value;
          }
        }
      }
    }
    
    if (measurementsMap.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return _buildDetailSection('Ukuran',
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
          color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'Ukuran $category',
              style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2552),
                      ),
                    ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...measurementsMap.entries.map((entry) {
              if (entry.key == 'catatan_tambahan') return const SizedBox.shrink();
              
              String displayKey = entry.key.toString()
                .replaceAll('_', ' ')
                .split(' ')
                .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
                .join(' ');
                
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayKey,
                      style: TextStyle(
                            fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '${entry.value} cm',
                      style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A2552),
                          ),
                        ),
                  ],
                ),
              );
            }),
            
            // Catatan tambahan jika ada
            if (measurementsMap.containsKey('catatan_tambahan') && 
                measurementsMap['catatan_tambahan'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Catatan Tambahan:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                measurementsMap['catatan_tambahan'].toString(),
                                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                      ),
                    ),
                  ],
          ],
        ),
      )
    );
  }
  
  // Helper untuk warna status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reservasi':
        return const Color(0xFF3B82F6); // Blue
      case 'diproses':
        return const Color(0xFFF59E0B); // Amber
      case 'selesai':
        return const Color(0xFF10B981); // Green
      case 'dibatalkan':
        return const Color(0xFFEF4444); // Red
      default:
        return Colors.grey;
    }
  }
  
  // Helper untuk icon status
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'reservasi':
        return Icons.event;
      case 'diproses':
        return Icons.engineering;
      case 'selesai':
        return Icons.check_circle;
      case 'dibatalkan':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }
  
  // Helper untuk format currency
  String _formatCurrency(String price) {
    // Bersihkan price dari karakter non-numerik
    String cleanPrice = price.replaceAll(RegExp(r'[^0-9.]'), '');
    
    // Handle decimal point
    if (cleanPrice.contains('.')) {
      List<String> parts = cleanPrice.split('.');
      cleanPrice = parts[0]; // Ambil bagian integer saja
    }
    
    // Jika kosong, return 0
    if (cleanPrice.isEmpty) return '0';
    
    // Parse ke integer
    int value = int.tryParse(cleanPrice) ?? 0;
    
    // Format dengan separator ribuan
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(value);
  }
  
  // Update widget untuk menampilkan badge status pesanan
  Widget _buildStatusBadge(String status, String statusDetail) {
    Color bgColor;
    Color textColor;
    String shortStatusText = _simplifyStatusText(statusDetail);

    switch (status.toLowerCase()) {
      case 'reservasi':
        bgColor = const Color(0xFFEEF2FF);
        textColor = const Color(0xFF3B82F6);
        break;
      case 'diproses':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        break;
      case 'selesai':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF10B981);
        break;
      case 'dibatalkan':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFEF4444);
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        shortStatusText,
                style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  // Fungsi untuk menyederhanakan teks status
  String _simplifyStatusText(String statusDetail) {
    // Pemetaan status panjang ke status pendek
    Map<String, String> statusMap = {
      'Pesanan telah selesai': 'Selesai',
      'Pesanan sedang diproses': 'Diproses',
      'Menunggu konfirmasi': 'Menunggu',
      'Pesanan dibatalkan': 'Dibatalkan',
      'Pesanan telah dikonfirmasi': 'Dikonfirmasi',
      'Menunggu pembayaran': 'Belum Bayar',
      'Pembayaran dikonfirmasi': 'Dibayar',
      'Menunggu penjahit': 'Tunggu Penjahit',
      'Menunggu pengambilan': 'Siap Diambil',
      'Pesanan telah diambil': 'Diambil',
      'Pesanan telah dibayar': 'Dibayar',
    };
    
    // Cari status pendek, jika tidak ditemukan gunakan original dengan batasan karakter
    return statusMap[statusDetail] ?? 
           (statusDetail.length > 12 ? '${statusDetail.substring(0, 12)}...' : statusDetail);
  }

  // Update widget untuk menampilkan badge status pembayaran
  Widget _buildPaymentStatusBadge(String? paymentStatus) {
    final bool isPaid = paymentStatus?.toLowerCase() == 'paid';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPaid ? const Color(0xFFA7F3D0) : const Color(0xFFFCD34D),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            size: 16,
            color: isPaid ? const Color(0xFF10B981) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 6),
              Text(
        isPaid ? 'Lunas' : 'Belum Lunas',
                style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPaid ? const Color(0xFF10B981) : const Color(0xFFD97706),
            ),
              ),
            ],
          ),
    );
  }

  // Method untuk mengecek apakah order sudah selesai
  bool _isOrderCompleted() {
    return widget.status == 'completed' ||
        (widget.orderData['status']?.toLowerCase() == 'selesai');
  }

  // Method untuk mengecek apakah booking sudah memiliki rating
  bool _hasRating() {
    final dynamic ratingValue = widget.orderData['rating'];

    // Jika rating berupa objek (dari API)
    if (ratingValue is Map) {
      return ratingValue.containsKey('rating') &&
          ratingValue['rating'] != null &&
          ratingValue['rating'].toString() != '0';
    }

    // Jika rating berupa nilai langsung
    return ratingValue != null && ratingValue != 0;
  }

  // Method untuk mendapatkan ID booking
  int _getBookingId() {
    // Cek ID langsung
    if (widget.orderData.containsKey('id') && widget.orderData['id'] != null) {
      final id = widget.orderData['id'];
      if (id is int && id > 0) {
        return id;
      } else if (id is String) {
        final parsedId = int.tryParse(id);
        if (parsedId != null && parsedId > 0) {
          return parsedId;
        }
      }
    }

    // Default return 0 jika tidak ada ID valid
    return 0;
  }

  // Method untuk format metode pembayaran
  String _formatPaymentMethod(String method) {
    if (method.isEmpty) return '-';
    
    switch(method.toLowerCase()) {
      case 'transfer_bank':
        return 'Transfer Bank';
      case 'cod':
      case 'cash_on_delivery':
        return 'Bayar di Tempat (COD)';
      case 'cash':
        return 'Tunai';
      case 'gopay':
        return 'GoPay';
      case 'ovo':
        return 'OVO';
      case 'dana':
        return 'DANA';
      case 'qris':
        return 'QRIS';
      case 'midtrans':
        return 'Midtrans Payment';
      default:
        // Format string dengan mengganti underscore dengan spasi dan capitalize kata pertama
        final words = method.split('_');
        return words.map((word) => word.isEmpty ? '' : 
          '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
          .join(' ');
    }
  }

  // Method untuk mengecek status pembayaran
  bool _isPaymentPaid() {
    // Cek kedua kemungkinan field status pembayaran
    final String? paymentStatus1 = widget.orderData['payment_status']?.toString().toLowerCase();
    final String? paymentStatus2 = widget.orderData['paymentStatus']?.toString().toLowerCase();
    
    // Return true jika salah satu status adalah 'paid'
    return paymentStatus1 == 'paid' || paymentStatus2 == 'paid';
  }

  // Method untuk navigasi ke halaman pembayaran
  void _navigateToPaymentPage(int bookingId, String totalPrice, String transactionCode) {
    if (bookingId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID booking tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Navigasi menggunakan named route dengan parameter
    Navigator.pushNamed(
      context, 
      '/payment',
      arguments: {
        'bookingId': bookingId,
        'totalPrice': totalPrice,
        'transactionCode': transactionCode,
      },
    ).then((result) {
      // Refresh halaman jika pembayaran berhasil
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        // Muat ulang halaman
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pop(context, true);
        });
      }
    });
  }

  // Method untuk tombol pembayaran
  Widget _buildPaymentButton(int bookingId, String totalPrice, String transactionCode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _navigateToPaymentPage(bookingId, totalPrice, transactionCode),
        icon: const Icon(Icons.payment),
        label: const Text('Bayar Sekarang'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // Method untuk menampilkan seksi status pembayaran
  Widget _buildPaymentStatusSection(String? paymentStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        const Text(
          'Status Pembayaran',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2552),
          ),
        ),
        const SizedBox(height: 8),
        _buildPaymentStatusBadge(paymentStatus),
      ],
    );
  }

  // Method untuk membangun info card
  Widget _buildInfoCard(BuildContext context) {
                    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
                          color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            offset: const Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            // Judul pesanan
            Text(
              '$_selectedService - $_selectedCategory',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                color: Color(0xFF1A2552),
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Tailor Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Foto penjahit
                if (_tailorImage.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: _buildTailorImage(_tailorImage),
                    ),
                  )
                else
                  Container(
                    width: 70,
                    height: 70,
        decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(width: 16),

                // Info penjahit
                Expanded(
                  child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
      children: [
        Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
                          color: const Color(0xFF1A2552).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Penjahit',
                  style: TextStyle(
                            fontSize: 12,
                    fontWeight: FontWeight.w500,
                            color: Color(0xFF1A2552),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tailorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2552),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
                              ),
                            ],
                          ),
                        ),
    );
  }
  
  // Method untuk build order info card
  Widget _buildOrderInfoCard() {
    final String? designPhoto = widget.orderData['designPhoto'];
    final String? completionPhoto = widget.orderData['completion_photo'];
    final String? completionNotes = widget.orderData['completion_notes'];
    final String? completionDate = widget.orderData['completion_date'];
    final String? status = widget.orderData['status']?.toString().toLowerCase();

    // Perbaiki pengambilan tanggal dan waktu
    String? appointmentDate = widget.orderData['appointmentDate'];
    String? appointmentTime = widget.orderData['appointmentTime'];

    // Coba ambil dari properti alternatif jika kosong
    if (appointmentDate == null || appointmentDate.isEmpty) {
      appointmentDate = widget.orderData['appointment_date'];
    }
    if (appointmentTime == null || appointmentTime.isEmpty) {
      appointmentTime = widget.orderData['appointment_time'];
    }

    final bool hasAppointmentDate =
        appointmentDate != null && appointmentDate.isNotEmpty;
    final bool hasAppointmentTime =
        appointmentTime != null && appointmentTime.isNotEmpty;

    final String formattedDate =
        hasAppointmentDate ? _formatDate(appointmentDate) : 'Belum ditentukan';
    final String formattedTime =
        hasAppointmentTime ? _formatBookingTime(appointmentTime) : '';

    // Buat pesan jadwal yang informatif
    String scheduleMessage;
    if (hasAppointmentDate && hasAppointmentTime) {
      scheduleMessage = '$formattedDate $formattedTime WIB';
    } else if (hasAppointmentTime) {
      scheduleMessage = 'Waktu: $formattedTime WIB (Tanggal belum ditentukan)';
    } else if (hasAppointmentDate) {
      scheduleMessage = '$formattedDate (Waktu belum ditentukan)';
    } else {
      scheduleMessage = 'Jadwal belum ditentukan';
    }

    // Data tambahan yang lengkap dari _buildProcessingOrderDetails
    final statusDetail = widget.orderData['statusDetail'] ?? '';
    final notes = widget.orderData['notes'];
    final serviceType = widget.orderData['serviceType'] ?? 'Jahit Baru';
    final category = widget.orderData['category'] ?? 'Atasan';
    final totalPrice = widget.orderData['total_price']?.toString() ?? '0';
    final transactionCode = widget.orderData['transaction_code'] ?? '';
    final paymentMethod = widget.orderData['payment_method'] ?? '';
    final paymentStatus = widget.orderData['payment_status'] ?? widget.orderData['paymentStatus'] ?? '';
    final orderStatus = widget.orderData['status']?.toString().toLowerCase() ?? '';
    final createdAt = widget.orderData['created_at'] ?? '';
    final completedAt = widget.orderData['completed_at'] ?? '';
    final measurements = widget.orderData['measurements'];
    final pickupDate = widget.orderData['pickup_date'] ?? widget.orderData['pickupDate'] ?? '';
    
    // Periksa apakah pesanan sudah selesai dan belum dibayar
    // Juga cek apakah metode pembayaran bukan COD
    final bool canPayWithMidtrans = 
        orderStatus == 'selesai' && 
        paymentStatus != 'paid' && 
        totalPrice != '0' &&
        transactionCode.isNotEmpty &&
        paymentMethod.toLowerCase() != 'cod' &&
        paymentMethod.toLowerCase() != 'cash_on_delivery';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan status dalam satu baris
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: Color(0xFF1A2552)),
                const SizedBox(width: 6),
                const Text(
                  'Detail Pemesanan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2552),
                  ),
                ),
                const Spacer(),
                // Status badge
                _buildStatusBadge(orderStatus, statusDetail),
              ],
            ),
            const SizedBox(height: 16),

            // Info Grid Layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tanggal dan Waktu Temu dalam satu container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Jadwal Temu',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              scheduleMessage,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: hasAppointmentDate && hasAppointmentTime
                                    ? const Color(0xFF1A2552)
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Jenis Layanan
                _buildInfoItem(
                  'Jenis Layanan',
                  serviceType,
                  icon: Icons.category,
                ),
                const SizedBox(height: 8),

                // Kategori
                _buildInfoItem(
                  'Kategori',
                  category,
                  icon: Icons.style,
                ),
                const SizedBox(height: 8),
                
                // Kode Transaksi
                if (transactionCode.isNotEmpty) ...[
                  _buildInfoItem(
                    'Kode Transaksi',
                    transactionCode,
                    icon: Icons.receipt_long,
                  ),
                  const SizedBox(height: 8),
                ],
                  
                // Metode Pembayaran
                if (paymentMethod.isNotEmpty) ...[
                  _buildInfoItem(
                    'Metode Pembayaran',
                    _formatPaymentMethod(paymentMethod),
                    icon: Icons.payment,
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Status Pembayaran
                if (paymentStatus.isNotEmpty) ...[
                  _buildDetailSection('Status Pembayaran',
                    _buildPaymentStatusBadge(paymentStatus)
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Tanggal pesanan
                if (createdAt.isNotEmpty) ...[
                  _buildInfoItem(
                    'Tanggal Pesanan',
                    _formatDate(createdAt),
                    icon: Icons.date_range,
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Tanggal selesai jika sudah selesai atau dalam proses
                if ((completedAt != null && completedAt.isNotEmpty) || 
                    (widget.orderData['completion_date'] != null && widget.orderData['completion_date'].toString().isNotEmpty))
                  _buildDetailSection('Tanggal Selesai',
                    Row(
                      children: [
                        Icon(Icons.event_available, size: 18, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(completedAt ?? widget.orderData['completion_date']),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[700],
                          ),
                        ),
                ],
                    )
                  ),
                
                // Tanggal pengambilan jika sudah ada
                if (pickupDate.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event_note, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Tanggal Pengambilan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(pickupDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
          ],
        ),
      ),
                  const SizedBox(height: 8),
                ],
                
                // Tampilkan total harga jika ada dengan rincian
                if (totalPrice != '0') ...[
                  _buildDetailedPriceBreakdown(totalPrice),
                  const SizedBox(height: 8),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Notes dan Design Photo
            if (notes != null && notes.toString().isNotEmpty) ...[
              _buildNotesSection(notes.toString()),
              const SizedBox(height: 12),
            ],

            if (designPhoto != null) ...[
              _buildDesignPhotoSection(designPhoto),
              const SizedBox(height: 12),
            ],
            
            // Ukuran jika ada dan jenis perbaikan adalah jahit baru
            if (measurements != null && measurements.toString().isNotEmpty && serviceType.toLowerCase() == 'jahit baru') ...[
              _buildMeasurementsSection(measurements.toString(), category),
              const SizedBox(height: 12),
            ],

            // Tampilkan completion date untuk status diproses dan selesai
            if ((status == 'diproses' || status == 'selesai') && completionDate != null) ...[
              _buildInfoItem(
                'Tanggal Selesai',
                _formatDate(completionDate),
                icon: Icons.event_available,
                iconColor: Colors.green[600],
                textColor: Colors.green[700],
              ),
              const SizedBox(height: 8),
            ],

            // Tampilkan completion photo dan notes hanya untuk status selesai
            if (status == 'selesai') ...[
              if (completionPhoto != null) ...[
                _buildCompletionPhotoSection(completionPhoto),
                const SizedBox(height: 12),
              ],
              if (completionNotes != null && completionNotes.isNotEmpty) ...[
                _buildCompletionNotesSection(completionNotes),
                const SizedBox(height: 12),
              ],
            ],

            // Tombol bayar jika belum dibayar dan status dalam halaman detail
            if (canPayWithMidtrans && widget.status == "processing")
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToPaymentPage(
                      _getBookingId(), 
                      totalPrice, 
                      transactionCode
                    ),
                    icon: const Icon(Icons.payment),
                    label: const Text('Bayar Sekarang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget baru untuk menampilkan rincian harga dengan breakdown
  Widget _buildDetailedPriceBreakdown(String totalPriceStr) {
    // Parse total price string ke integer
    int baseTotalPrice = int.tryParse(_cleanRupiah(totalPriceStr)) ?? 0;
    
    // Metode pembayaran
    final String paymentMethod = (widget.orderData['payment_method'] ?? '').toString().toLowerCase();
    final bool isCod = paymentMethod == 'cod' || paymentMethod == 'cash_on_delivery';
    
    // Biaya tambahan - 0 jika COD
    final int paymentServiceFee = isCod ? 0 : 4000;
    // final int tailorServiceFee = isCod ? 0 : 1000;
    
    // Hitung total akhir
    final int finalTotalPrice = baseTotalPrice + paymentServiceFee;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF22C55E),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rincian Biaya',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22C55E),
                ),
              ),
              const Spacer(),
              // Tampilkan badge COD jika metode pembayaran COD
              if (isCod)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'COD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          // Item biaya dengan format yang lebih bagus
          _buildPriceItem(
            "Biaya Jahit",
            _formatCurrency(baseTotalPrice.toString()),
            isMain: true,
          ),
          
          // Hanya tampilkan biaya layanan jika bukan COD
          if (!isCod) ...[
            _buildPriceItem(
              "Biaya Layanan Payment",
              _formatCurrency(paymentServiceFee.toString()),
            ),
            // _buildPriceItem(
            //   "Biaya Layanan Tailor",
            //   _formatCurrency(tailorServiceFee.toString()),
            // ),
          ] else ...[
            // Pesan penjelasan biaya COD
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                "Tidak ada biaya layanan tambahan untuk metode COD",
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2552),
                ),
              ),
              Text(
                'Rp ${_formatCurrency(finalTotalPrice.toString())}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper untuk menampilkan item harga
  Widget _buildPriceItem(String label, String price, {bool isMain = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMain ? 15 : 14,
              fontWeight: isMain ? FontWeight.w600 : FontWeight.normal,
              color: isMain ? const Color(0xFF1A2552) : Colors.grey.shade700,
            ),
          ),
          Text(
            'Rp $price',
            style: TextStyle(
              fontSize: isMain ? 15 : 14,
              fontWeight: isMain ? FontWeight.w600 : FontWeight.w500,
              color: isMain ? const Color(0xFF1A2552) : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk membersihkan format rupiah
  String _cleanRupiah(String nominal) {
    if (nominal.isEmpty) return '0';
    
    // Tangani kasus dengan angka desimal - ambil hanya bagian sebelum titik desimal
    if (nominal.contains('.')) {
      nominal = nominal.split('.')[0];
    }
    
    // Bersihkan nominal dari karakter non-angka
    String cleanNominal = nominal.replaceAll(RegExp(r'[^0-9]'), '');
    
    return cleanNominal;
  }

  // Helper untuk tampilan widget InfoItem dengan warna kustom
  Widget _buildInfoItem(String label, String value, {IconData? icon, Color? textColor, Color? iconColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? Colors.grey.shade600),
            const SizedBox(width: 8),
          ],
          // Label
          SizedBox(
            width: 100, // Fixed width untuk label
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Value dengan expanded untuk mengambil sisa ruang
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor ?? const Color(0xFF1A2552),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk _buildOrderInfoCard - Notes Section
  Widget _buildNotesSection(String notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan Pesanan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2552),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            notes,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // Helper untuk _buildOrderInfoCard - Design Photo Section
  Widget _buildDesignPhotoSection(String? photoPath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Desain',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2552),
          ),
        ),
        const SizedBox(height: 8),
        _buildDesignPhoto(photoPath),
      ],
    );
  }

  // Helper untuk tampilan foto desain
  Widget _buildDesignPhoto(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Tidak ada foto desain',
                style: TextStyle(
                  fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }

    final String fullUrl = _getFullImageUrl(photoPath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
          children: [
              const Icon(Icons.photo_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Foto desain tersedia (tap untuk memperbesar)',
              style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showImageDialog(context, fullUrl, 'Foto Desain'),
          child: Hero(
            tag: 'designPhoto$photoPath',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    fullUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported,
                                  color: Colors.grey, size: 40),
                              SizedBox(height: 8),
        Text(
                                'Gagal memuat gambar',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
                          color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
                        ),
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper untuk tampilan foto tailor
  Widget _buildTailorImage(String imagePath) {
    // Gunakan image dari network jika path tidak kosong
    if (imagePath.isNotEmpty) {
      // Gunakan UrlHelper untuk mendapatkan URL yang valid
      final fullUrl = UrlHelper.getValidImageUrl(imagePath);

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fullUrl,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/avatar_default.png',
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            );
          },
        ),
      );
    } else {
      // Gunakan asset sebagai fallback
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/avatar_default.png',
          width: 70,
          height: 70,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  // Helper untuk mendapatkan URL lengkap foto
  String _getFullImageUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return '';

    // Gunakan UrlHelper untuk mendapatkan URL yang valid
    return UrlHelper.getValidImageUrl(photoPath);
  }

  // Helper untuk tampilkan gambar dalam dialog
  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(8),
          child: Stack(
            alignment: Alignment.center,
        children: [
              // Foto dengan ukuran penuh
              InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          'Gagal memuat gambar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Header dengan judul dan tombol tutup
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
        );
      },
    );
  }

  // Method untuk _buildRatingSection
  Widget _buildRatingSection(int bookingId) {
    print('DEBUG: Building rating section with rating data: ${widget.orderData['rating']}');
    
    // Tambahkan logging untuk melihat apakah rating data valid
    if (widget.orderData['rating'] is Map) {
      print('DEBUG: Rating is Map with keys: ${(widget.orderData['rating'] as Map).keys.toList()}');
      print('DEBUG: Rating value: ${widget.orderData['rating']['rating']}');
      print('DEBUG: Review content: ${widget.orderData['rating']['review']}');
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
            'Rating & Ulasan',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2552),
              ),
            ),
            const SizedBox(height: 16),

          // Info box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                const Text(
                  'Bagikan pendapat Anda tentang kualitas layanan',
                          style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2552),
                          ),
                        ),
                const SizedBox(height: 4),
                      Text(
                  _isPaymentPaid()
                      ? 'Ulasan Anda sangat membantu penjahit untuk meningkatkan kualitas layanan'
                      : 'Anda perlu menyelesaikan pembayaran terlebih dahulu untuk dapat memberikan ulasan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tampilkan form rating atau rating yang sudah ada
          if (_hasRating()) 
            _buildFixedRating()
          else if (_isPaymentPaid()) 
            _buildRatingForm(bookingId)
          else
            _buildPaymentRequiredMessage(),
        ],
      ),
    );
  }
  
  // Widget untuk form rating baru
  Widget _buildRatingForm(int bookingId) {
    return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
        Row(
          children: [
            const Text(
              'Beri Rating: ',
                          style: TextStyle(
                fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A2552),
                          ),
                        ),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 24,
              itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Tulis Ulasan:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
                          color: Color(0xFF1A2552),
                        ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reviewController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ceritakan pengalaman Anda dengan layanan ini...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3D77E3)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submitRating(bookingId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
        color: Colors.white,
                    ),
                  )
                : const Text(
                    'Kirim Ulasan',
                          style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
  
  // Widget khusus untuk menampilkan rating yang sudah ada dengan perbaikan bug
  Widget _buildFixedRating() {
    // Ambil data rating
    dynamic ratingData = widget.orderData['rating'];
    print('DEBUG: Building fixed rating with data: $ratingData');
    
    // Extract rating value
    double ratingValue = 0;
    String reviewText = '';
    
    if (ratingData is Map) {
      // Handle case when rating is a Map
      var ratingVal = ratingData['rating'];
      if (ratingVal != null) {
        if (ratingVal is int) {
          ratingValue = ratingVal.toDouble();
        } else if (ratingVal is String) {
          ratingValue = double.tryParse(ratingVal) ?? 0;
        } else if (ratingVal is double) {
          ratingValue = ratingVal;
        }
      }
      reviewText = ratingData['review']?.toString() ?? '';
    } else {
      // Handle direct rating value (less common)
      if (ratingData is int) {
        ratingValue = ratingData.toDouble();
      } else if (ratingData is String) {
        ratingValue = double.tryParse(ratingData) ?? 0;
      } else if (ratingData is double) {
        ratingValue = ratingData;
      }
      reviewText = widget.orderData['review']?.toString() ?? '';
    }
    
    // Ensure we have a valid rating
    int displayRating = ratingValue.round();
    print('DEBUG: Final rating display value: $displayRating');
    
    // Ensure we have valid review text
    if (reviewText.isEmpty) {
      reviewText = 'Tidak ada ulasan';
    }
    
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Rating: ',
              style: TextStyle(
                fontSize: 14,
                            fontWeight: FontWeight.w500,
                color: Color(0xFF1A2552),
              ),
            ),
            const SizedBox(width: 4),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < displayRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
                      Text(
              '$displayRating/5',
                        style: const TextStyle(
                fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2552),
                        ),
                      ),
                    ],
                  ),
        const SizedBox(height: 12),
        const Text(
          'Ulasan Anda:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A2552),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            reviewText,
            style: TextStyle(
              fontSize: 14,
              fontStyle: reviewText == 'Tidak ada ulasan'
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: reviewText == 'Tidak ada ulasan'
                  ? Colors.grey.shade600
                  : Colors.black87,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
        children: [
                Icon(
                  Icons.check_circle,
                  color: Color(0xFF059669),
                  size: 18,
                ),
                SizedBox(width: 8),
            Text(
                  'Terima kasih atas ulasan Anda!',
              style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
          ],
        ),
      ),
        ),
      ],
    );
  }

  // Helper untuk menampilkan pesan pembayaran diperlukan
  Widget _buildPaymentRequiredMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFFD97706),
            size: 32,
          ),
          SizedBox(height: 12),
          Text(
            'Pembayaran Diperlukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97706),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Anda perlu menyelesaikan pembayaran terlebih dahulu untuk dapat memberikan ulasan.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF92400E),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          // Tombol Bayar Sekarang dihapus karena sudah ada di bagian atas halaman
        ],
      ),
    );
  }

  // Helper untuk tampilan foto penyelesaian
  Widget _buildCompletionPhotoSection(String photoPath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Hasil Jahitan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2552),
          ),
        ),
        const SizedBox(height: 8),
        _buildCompletionPhoto(photoPath),
      ],
    );
  }

  // Helper untuk tampilan foto hasil jahitan
  Widget _buildCompletionPhoto(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Tidak ada foto hasil jahitan',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }

    final String fullUrl = _getFullImageUrl(photoPath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Foto hasil jahitan tersedia (tap untuk memperbesar)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showImageDialog(context, fullUrl, 'Foto Hasil Jahitan'),
          child: Hero(
            tag: 'completionPhoto$photoPath',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    fullUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported,
                                  color: Colors.grey, size: 40),
                              SizedBox(height: 8),
                              Text(
                                'Gagal memuat gambar',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper untuk tampilan catatan penyelesaian
  Widget _buildCompletionNotesSection(String notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan Penyelesaian',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2552),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            notes,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// Tambahkan extension untuk mempercantik tampilan teks
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

