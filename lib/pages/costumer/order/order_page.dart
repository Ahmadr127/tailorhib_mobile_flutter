import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/controllers/booking_controller.dart';
import '../../../core/models/booking_model.dart';
import 'order_detail_page.dart';
// import '../../../core/widgets/custom_button.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = [
    'Semua',
    'Reservasi',
    'Diproses',
    'Selesai',
    'Dibatalkan'
  ];
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load data booking saat halaman pertama kali dibuka
    if (!_isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadBookings();
        }
      });
    }
  }

  // Method untuk memformat angka ke format rupiah
  String _formatCurrency(dynamic price) {
    if (price == null) return '0';
    
    // Bersihkan price dari karakter non-numerik
    String cleanPrice = price.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    
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

  Future<void> _loadBookings() async {
    if (!mounted) return;

    final bookingController =
        Provider.of<BookingController>(context, listen: false);
    try {
      // Convert _selectedFilter untuk filter lokal di BookingController
      String filterStatus = '';
      switch (_selectedFilter) {
        case 'Semua':
          filterStatus = 'Semua'; // Kosong berarti ambil semua
          break;
        case 'Reservasi':
          filterStatus = 'Reservasi';
          break;
        case 'Diproses':
          filterStatus = 'Diproses';
          break;
        case 'Selesai':
          filterStatus = 'Selesai';
          break;
        case 'Dibatalkan':
          filterStatus = 'Dibatalkan';
          break;
        default:
          filterStatus = 'Semua';
      }

      print('DEBUG: Loading bookings with filter: $filterStatus');

      // Muat semua data booking dan gunakan filter lokal
      await bookingController.loadBookings(filterStatus);

      // Debug: tampilkan data booking setelah diload
      if (!mounted) return; // Pengecekan tambahan

      if (bookingController.bookings.isNotEmpty) {
        print(
            'DEBUG: First booking loaded: ${bookingController.bookings[0].id}');
        print(
            'DEBUG: Tailor name: ${bookingController.bookings[0].getTailorName()}');
        print(
            'DEBUG: Tailor in booking: ${bookingController.bookings[0].tailor}');
      } else {
        print('DEBUG: No bookings loaded');
      }
    } catch (e) {
      if (mounted) {
        print('DEBUG: Error loading bookings: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToPaymentPage(BookingModel booking) {
    // Konversi totalPrice ke integer untuk menghindari error
    int totalPrice = 0;
    
    // Coba konversi totalPrice dari berbagai format
    try {
      if (booking.totalPrice != null) {
        // Jika totalPrice sudah berupa string, hapus karakter non-numerik
        String numericPrice = booking.totalPrice!.replaceAll(RegExp(r'[^0-9]'), '');
        if (numericPrice.isNotEmpty) {
          totalPrice = int.parse(numericPrice);
        }
      }
    } catch (e) {
      print('Error converting totalPrice: $e');
    }
    
    print('DEBUG: Navigating to payment page with totalPrice: $totalPrice (type: ${totalPrice.runtimeType})');
    
    Navigator.pushNamed(
      context,
      '/payment',
      arguments: {
        'bookingId': booking.id,
        'transactionCode': booking.transactionCode ?? 'N/A',
        'totalPrice': totalPrice,
      },
    ).then((result) {
      // Refresh halaman setelah kembali dari payment page
      if (result == true) {
        _loadBookings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, BookingController>(
      builder: (context, userProvider, bookingController, child) {
        final User? user = userProvider.user;

        // Jika tidak ada data user, tampilkan loading
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Row(
              children: [
                // Foto profil
                Container(
                  width: 35,
                  height: 35,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade300,
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: user.profilePhoto != null &&
                            user.profilePhoto!.isNotEmpty
                        ? Image.network(
                            _getFullProfilePhotoUrl(user.profilePhoto!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/avatar_default.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              );
                            },
                          ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pesanan Saya',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF1A2552),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            centerTitle: false,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.white,
            automaticallyImplyLeading: false,
          ),
          body: Column(
            children: [
              // Filter tabs - tampilan minimalis
              Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        _loadBookings();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        margin: const EdgeInsets.only(right: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF3D77E3)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? const Color(0xFF3D77E3)
                                : Colors.grey.shade700,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Divider tipis di bawah filter
              Container(
                height: 1,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.only(bottom: 16),
              ),

              // Tombol refresh
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    Text('Daftar Pesanan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey.shade800)),
                    const Spacer(),
                    InkWell(
                      onTap: _loadBookings,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D77E3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh,
                                color: Color(0xFF3D77E3), size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Refresh',
                              style: TextStyle(
                                color: Color(0xFF3D77E3),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),

              // Order list
              Expanded(
                child: bookingController.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : bookingController.errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  bookingController.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadBookings,
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          )
                        : bookingController.bookings.isEmpty
                            ? const Center(
                                child: Text('Tidak ada pesanan'),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: bookingController.bookings.length,
                                itemBuilder: (context, index) {
                                  final booking =
                                      bookingController.bookings[index];

                                  // Debug output
                                  print(
                                      'DEBUG: Building order card for booking ${booking.id}');
                                  print(
                                      'DEBUG: Customer name: ${booking.getCustomerName()}');
                                  print(
                                      'DEBUG: Profile photo path: ${booking.getProfilePhoto()}');
                                  print(
                                      'DEBUG: Formatted date: ${booking.getFormattedDate()}');
                                  print(
                                      'DEBUG: Formatted time: ${booking.getFormattedTime()}');
                                  print(
                                      'DEBUG: Repair details: ${booking.repairDetails}');
                                  print(
                                      'DEBUG: Repair notes: ${booking.repairNotes}');
                                  print(
                                      'DEBUG: Repair photo: ${booking.repairPhoto}');
                                  print(
                                      'DEBUG: Completion notes: ${booking.completionNotes}');
                                  print(
                                      'DEBUG: Completion photo: ${booking.completionPhoto}');
                                  print(
                                      'DEBUG: Completed at: ${booking.completedAt}');

                                  // Debugging detail data dari getOrderDetails
                                  final Map<String, dynamic> orderDetails =
                                      booking.getOrderDetails();
                                  print(
                                      'DEBUG: Full orderDetails: $orderDetails');

                                  return _buildOrderCard(
                                    orderDetails,
                                    bookingController,
                                  );
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(
      Map<String, dynamic>? bookingData, BookingController controller) {
    print('DEBUG: Building order card with data: $bookingData');

    // Mendapatkan data booking yang akan ditampilkan
    final int bookingId = bookingData?['id'] ?? 0;
    var booking = BookingModel.fromJson(bookingData ?? {});
    final String tailorName = booking.getTailorName();
    print('DEBUG: Tailor name from booking model: $tailorName');
    
    // Tambahkan kode transaksi
    final String transactionCode = bookingData?['transaction_code'] ?? '';

    // Warna status sesuai dengan status pesanan
    final String status = bookingData?['status'] ?? '';
    final Color statusColor = _getStatusColor(status);

    // Tambahkan variabel hasRating berdasarkan data rating
    final bool hasRating = bookingData?['rating'] != null &&
        (bookingData?['rating'] is num || bookingData?['rating'] is Map);

    // Debug data untuk memastikan semua field ada
    print('DEBUG: Building order card for booking $bookingId');
    print('DEBUG: Display Name: $tailorName'); // Log nama yang akan ditampilkan
    print('DEBUG: Status: $status');
    print('DEBUG: Payment status: ${bookingData?['payment_status']}');
    print('DEBUG: Design photo: ${bookingData?['designPhoto']}');
    print('DEBUG: Completion photo: ${bookingData?['completionPhoto']}');
    print('DEBUG: Repair notes: ${bookingData?['repair_notes']}');
    print('DEBUG: Repair photo: ${bookingData?['repair_photo']}');
    print('DEBUG: Repair details: ${bookingData?['repair_details']}');
    print('DEBUG: Completion notes: ${bookingData?['completion_notes']}');
    print('DEBUG: Completed at: ${bookingData?['completed_at']}');
    print('DEBUG: Has rating: $hasRating');
    print('DEBUG: Transaction code: $transactionCode');

    // Format tanggal dan waktu
    final String appointmentDate = bookingData?['appointmentDate'] ?? '';
    final String appointmentTime = bookingData?['appointmentTime'] ?? '';

    print('DEBUG: Raw appointment date: $appointmentDate');
    print('DEBUG: Raw appointment time: $appointmentTime');

    final String formattedDate = _formatDate(appointmentDate);
    final String formattedTime = _formatTime(appointmentTime);

    print('DEBUG: Formatted date result: $formattedDate');
    print('DEBUG: Formatted time result: $formattedTime');

    // Buat card yang lebih informatif dan menarik
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 6,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: statusColor.withOpacity(0.05),
              offset: const Offset(0, 1),
              blurRadius: 5,
              spreadRadius: 0,
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            // Navigasi ke halaman detail order
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailPage(
                    status: _getPageStatus(
                        status, bookingData?['statusDetail'] ?? ''),
                    orderData: {
                      ...bookingData ?? {},
                      'id': bookingId,
                      'tailorName': tailorName,
                      'tailorImage': bookingData?['tailorImage'] ??
                          'assets/images/avatar_default.png',
                      'serviceType': bookingData?['serviceType'] ?? 'Jahit',
                      'category': bookingData?['category'] ?? 'Pakaian',
                      'status': status.toLowerCase(),
                      'statusDetail': bookingData?['statusDetail'] ?? '',
                      'appointmentDate': bookingData?['appointmentDate'] ??
                          bookingData?['appointment_date'] ??
                          '',
                      'appointmentTime': bookingData?['appointmentTime'] ??
                          bookingData?['appointment_time'] ??
                          '10:00',
                      'created_at': bookingData?['created_at'] ?? '',
                      'payment_status':
                          bookingData?['payment_status'] ?? 'unpaid',
                      'transaction_code': transactionCode,
                    },
                  ),
                ),
              ).then((_) {
                // Refresh data setelah kembali dari halaman detail
                _loadBookings();
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Header dengan foto profil penjahit, nama, dan status badge
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Foto profil penjahit
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: _buildProfileImage(bookingData?['tailorImage'] ??
                                'assets/images/avatar_default.png'),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Info penjahit dan ID pesanan
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tailorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1A2552),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Pesanan #$bookingId',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Tampilkan kode transaksi sebagai informasi terpisah jika ada
                    if (transactionCode.isNotEmpty) 
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long, size: 14, color: Colors.grey.shade700),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Kode: $transactionCode',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Status badge - dipindahkan ke bawah untuk menghindari konflik layout
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        bookingData?['statusDetail'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(color: Colors.grey.shade200, height: 1),

              // Order details section dengan foto dan info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail foto desain atau hasil
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildOrderImage(
                            bookingData?['completionPhoto'],
                            bookingData?['designPhoto'],
                            bookingData?['serviceType'] ?? 'Jahit'),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Order details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service type and category
                          Text(
                            bookingData?['serviceType'] ?? 'Jahit',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF1A2552),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Jadwal temu
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                formattedDate != '-' && formattedTime != '-'
                                    ? '$formattedDate $formattedTime'
                                    : 'Jadwal belum ditentukan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Tanggal-tanggal penting sesuai status
                          if (status.toLowerCase() == 'reservasi') ...[
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Dibuat: ${_formatDate(bookingData?['created_at'] ?? '')}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (status.toLowerCase() == 'diproses') ...[
                            Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Diterima: ${_formatDate(bookingData?['accepted_at'] ?? '')}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (status.toLowerCase() == 'selesai') ...[
                            Row(
                              children: [
                                Icon(Icons.done_all,
                                    size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Selesai: ${_formatDate(bookingData?['completed_at'] ?? '')}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            if (bookingData?['pickup_date'] != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.local_shipping,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Diambil: ${_formatDate(bookingData?['pickup_date'] ?? '')}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ] else if (status.toLowerCase() == 'dibatalkan') ...[
                            Row(
                              children: [
                                Icon(Icons.cancel_outlined,
                                    size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Dibatalkan: ${_formatDate(bookingData?['rejected_at'] ?? '')}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            if (bookingData?['rejection_reason'] != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 14, color: Colors.red.shade400),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Alasan: ${bookingData?['rejection_reason']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.red.shade400,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],

                          // Catatan pesanan jika ada
                          if (bookingData?['notes']?.isNotEmpty == true) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.notes,
                                    size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Catatan: ${bookingData?['notes']}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Harga jika sudah ada
                          if (bookingData?['total_price'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Harga Jahit',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1A2552),
                                  ),
                                ),
                            Text(
                              'Rp ${_formatCurrency(bookingData?['total_price'])}',
                              style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                color: Color(0xFF1A2552),
                              ),
                            ),
                          ],
                            ),
                            
                            // Tambahkan total dengan biaya layanan
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Cek metode pembayaran untuk label
                                Flexible(
                                  child: Text(
                                    (bookingData?['payment_method'] ?? '').toString().toLowerCase() == 'cod' || 
                                    (bookingData?['payment_method'] ?? '').toString().toLowerCase() == 'cash_on_delivery' 
                                        ? 'Total Bayar' 
                                        : 'Total dengan Biaya Layanan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _calculateTotalWithServiceFee(
                                    bookingData?['total_price'], 
                                    paymentMethod: bookingData?['payment_method'] ?? ''
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Price and review button section untuk status selesai
              if (status.toLowerCase() == 'selesai')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status pembayaran
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (bookingData?['payment_status'] == 'paid' ||
                                    bookingData?['paymentStatus'] == 'paid')
                                ? Icons.check_circle
                                : Icons.pending,
                            size: 14,
                            color: (bookingData?['payment_status'] == 'paid' ||
                                    bookingData?['paymentStatus'] == 'paid')
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (bookingData?['payment_status'] == 'paid' ||
                                    bookingData?['paymentStatus'] == 'paid')
                                ? 'Lunas'
                                : 'Belum Lunas',
                            style: TextStyle(
                              fontSize: 12,
                              color: (bookingData?['payment_status'] ==
                                          'paid' ||
                                      bookingData?['paymentStatus'] == 'paid')
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      // Tombol rating - hanya tampil jika pembayaran sudah lunas
                      if (bookingData?['payment_status'] == 'paid' ||
                          bookingData?['paymentStatus'] == 'paid')
                        ElevatedButton.icon(
                          onPressed: () {
                            print(
                                'DEBUG: Button pressed with booking ID: ${bookingData?['id']}');

                            // Navigasi ke halaman detail dengan parameter rating
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderDetailPage(
                                    status: 'completed',
                                    orderData: {
                                      ...bookingData ?? {},
                                      'id': bookingId,
                                      'tailorName': tailorName,
                                      'tailorImage': bookingData?[
                                              'tailorImage'] ??
                                          'assets/images/avatar_default.png',
                                      'serviceType':
                                          bookingData?['serviceType'] ??
                                              'Jahit',
                                      'category':
                                          bookingData?['category'] ?? 'Pakaian',
                                      'status': 'selesai',
                                      'statusDetail': 'Pesanan Selesai',
                                      'rating': bookingData?['rating'],
                                      'review': bookingData?['review'],
                                      'transaction_code': transactionCode,
                                    },
                                  ),
                                ),
                              ).then((_) {
                                _loadBookings();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasRating
                                ? Colors.green
                                : const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            minimumSize: const Size(0, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(
                            hasRating ? Icons.star : Icons.star_border,
                            size: 14,
                          ),
                          label: Text(
                            hasRating ? 'Lihat Ulasan' : 'Beri Ulasan',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Tambahkan tombol bayar untuk status selesai yang belum lunas
                        if (status.toLowerCase() == 'selesai' && 
                            bookingData?['payment_status'] != 'paid' &&
                            bookingData?['paymentStatus'] != 'paid' &&
                            transactionCode.isNotEmpty) ...[
                          
                          // Cek metode pembayaran
                          if ((bookingData?['payment_method'] ?? '').toString().toLowerCase() != 'cod' && 
                              (bookingData?['payment_method'] ?? '').toString().toLowerCase() != 'cash_on_delivery') ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                // Tampilkan dialog konfirmasi pembayaran
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Konfirmasi Pembayaran'),
                                    content: const Text('Lanjutkan ke halaman pembayaran?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context); // Tutup dialog
                                          
                                          // Navigasi ke halaman pembayaran
                                          _navigateToPaymentPage(booking);
                                        },
                                        child: const Text('Bayar', style: TextStyle(color: Colors.blue)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.payment, size: 12, color: Colors.blue.shade800),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Bayar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            // Jika COD, tampilkan indikator metode pembayaran
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.monetization_on, size: 12, color: Colors.green.shade800),
                                  const SizedBox(width: 2),
                                  Text(
                                    'COD',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Metode baru untuk membangun thumbnail gambar pesanan (completion photo atau design photo)
  Widget _buildOrderImage(
      String? completionPhoto, String? designPhoto, String service) {
    print('DEBUG: Building order image with:');
    print('DEBUG: Completion photo: $completionPhoto');
    print('DEBUG: Design photo: $designPhoto');

    // Pilih foto yang akan ditampilkan (prioritaskan completion photo)
    String? selectedPhoto = completionPhoto?.isNotEmpty == true
        ? completionPhoto
        : designPhoto?.isNotEmpty == true
            ? designPhoto
            : null;

    if (selectedPhoto == null) {
      return _buildDefaultImage(service);
    }

    // Gunakan FutureBuilder untuk memperbaiki URL secara asinkron
    return FutureBuilder<String>(
      future: ApiService.fixDesignPhotoUrl(selectedPhoto),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        // Jika berhasil mendapatkan URL yang valid
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          String fixedUrl = snapshot.data!;
          print('DEBUG: Fixed image URL: $fixedUrl');

          return Image.network(
            fixedUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('DEBUG: Error loading fixed image: $error');
              return _buildDefaultImage(service);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              );
            },
          );
        }

        // Jika gagal mendapatkan URL, gunakan image default
        return _buildDefaultImage(service);
      },
    );
  }

  // Widget default dengan ikon berdasarkan jenis layanan
  Widget _buildDefaultImage(String service) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          service.toLowerCase().contains('perbaikan')
              ? Icons.construction
              : Icons.design_services,
          color: Colors.grey.shade400,
          size: 32,
        ),
      ),
    );
  }

  // Metode baru untuk membangun widget gambar profil
  Widget _buildProfileImage(String imagePath) {
    print('DEBUG: Building profile image: $imagePath');

    if (imagePath.isEmpty || imagePath == 'assets/images/avatar_default.png') {
      return Image.asset(
        'assets/images/avatar_default.png',
        fit: BoxFit.cover,
      );
    }

    String fullUrl = _getFullProfilePhotoUrl(imagePath);
    print('DEBUG: Full image URL: $fullUrl');

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('DEBUG: Error loading image from URL: $error');
        return Image.asset(
          'assets/images/avatar_default.png',
          fit: BoxFit.cover,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  // Helper method untuk memastikan URL lengkap
  String _getFullProfilePhotoUrl(String photoUrl) {
    // Jika URL sudah lengkap, kembalikan apa adanya
    if (photoUrl.startsWith('http')) {
      return photoUrl;
    }

    // Jika tidak, tambahkan base URL
    return ApiService.getFullImageUrl(photoUrl);
  }

  // Metode helper untuk memformat tanggal
  String _formatDate(String? dateString) {
    try {
      print('DEBUG: Formatting date input: $dateString');
      if (dateString == null || dateString.isEmpty) {
        print('DEBUG: Date string is null or empty');
        return 'Belum ditentukan';
      }

      // Jika dateString sudah dalam format yang diharapkan (seperti "26 April 2025"),
      // kembalikan langsung
      if (dateString.contains(' ') &&
          !dateString.contains('-') &&
          !dateString.contains('T')) {
        print('DEBUG: Date string already formatted: $dateString');
        return dateString;
      }

      // Coba parse tanggal dari format ISO
      DateTime date;
      if (dateString.contains('T')) {
        // Format ISO dengan timezone
        date = DateTime.parse(dateString);
        print('DEBUG: Parsed ISO date with timezone: $date');
      } else if (dateString.contains('-')) {
        // Format YYYY-MM-DD
        final parts = dateString.split('-');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          print('DEBUG: Parsed simple date: $date');
        } else {
          print('ERROR: Invalid date parts length: ${parts.length}');
          return 'Format tanggal tidak valid';
        }
      } else {
        // Format tidak dikenal
        print('ERROR: Unknown date format: $dateString');
        return 'Format tanggal tidak valid';
      }

      // Format ke bahasa Indonesia
      List<String> months = [
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
      print('DEBUG: Successfully formatted date: $formattedDate');
      return formattedDate;
    } catch (e, stackTrace) {
      print('ERROR: Exception in _formatDate: $e');
      print('ERROR: Stack trace: $stackTrace');
      print('ERROR: Original date string: $dateString');
      return 'Format tanggal tidak valid';
    }
  }

  // Metode helper untuk format waktu
  String _formatTime(String? time) {
    try {
      print('DEBUG: Formatting time input: $time');
      if (time == null || time.isEmpty) {
        print('DEBUG: Time string is null or empty');
        return 'Belum ditentukan';
      }

      // Jika format waktu sudah HH:mm, tambahkan WIB
      if (time.length <= 5 && time.contains(':')) {
        final parts = time.split(':');
        if (parts.length == 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          String formattedTime =
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} WIB';
          print('DEBUG: Successfully formatted time: $formattedTime');
          return formattedTime;
        }
      }

      // Jika ada detik atau timezone, ambil hanya jam dan menit
      if (time.contains(':')) {
        final parts = time.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          String minutePart = parts[1];
          if (minutePart.contains('.')) {
            minutePart = minutePart.split('.')[0];
          }
          if (minutePart.contains(' ')) {
            minutePart = minutePart.split(' ')[0];
          }
          final minute = int.parse(minutePart);
          String formattedTime =
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} WIB';
          print('DEBUG: Successfully formatted time: $formattedTime');
          return formattedTime;
        }
      }

      print('DEBUG: Using original time format: $time WIB');
      return '$time WIB';
    } catch (e, stackTrace) {
      print('ERROR: Exception in _formatTime: $e');
      print('ERROR: Stack trace: $stackTrace');
      print('ERROR: Original time string: $time');
      return 'Format waktu tidak valid';
    }
  }

  // Helper untuk mendapatkan status halaman berdasarkan status pesanan
  String _getPageStatus(String status, String statusDetail) {
    switch (status.toLowerCase()) {
      case 'reservasi':
        return statusDetail.contains('Dikonfirmasi')
            ? 'confirmation'
            : 'waiting';
      case 'diproses':
        return 'processing';
      case 'selesai':
        return 'completed';
      case 'dibatalkan':
        return 'canceled';
      default:
        return 'waiting';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reservasi':
        return const Color(0xFF3D77E3); // Biru
      case 'diproses':
        return const Color(0xFFFF9800); // Orange
      case 'selesai':
        return const Color(0xFF1E3A8A); // Indigo
      case 'dibatalkan':
        return const Color(0xFFE53935); // Merah
      default:
        return Colors.grey;
    }
  }

  // Tambahkan method untuk menghitung total dengan biaya layanan
  String _calculateTotalWithServiceFee(dynamic basePrice, {String? paymentMethod}) {
    try {
      // Parse harga dasar
      String cleanPrice = basePrice.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      
      // Handle decimal point
      if (cleanPrice.contains('.')) {
        List<String> parts = cleanPrice.split('.');
        cleanPrice = parts[0]; // Ambil bagian integer saja
      }
      
      // Parse ke integer
      int parsedPrice = int.tryParse(cleanPrice) ?? 0;
      
      // Cek apakah metode pembayaran adalah COD
      bool isCod = paymentMethod != null && 
                  (paymentMethod.toLowerCase() == 'cod' || 
                   paymentMethod.toLowerCase() == 'cash_on_delivery');
      
      // Tambahkan biaya layanan - 0 jika COD
      final int paymentServiceFee = isCod ? 0 : 4000;
      // final int tailorServiceFee = isCod ? 0 : 1000;
      int totalWithFees = parsedPrice + paymentServiceFee;
      
      // Format total
      final formatter = NumberFormat('#,###', 'id_ID');
      return 'Rp ${formatter.format(totalWithFees)}';
    } catch (e) {
      print('ERROR: Gagal menghitung total dengan biaya layanan: $e');
      return 'Rp 0';
    }
  }
}
