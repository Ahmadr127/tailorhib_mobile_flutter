import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/booking_model.dart';
import 'order_detail_Page.dart'; // Import halaman detail pesanan
import '../schedule/schedule_page.dart'; // Import halaman schedule

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  bool _isLoading = true;
  List<BookingModel> _bookings = [];
  String _errorMessage = '';
  String _currentStatus = 'semua'; // Status default: semua pesanan

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  // Fungsi untuk mendapatkan semua pesanan
  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentStatus = 'semua';
    });

    try {
      final result = await ApiService.getTailorBookings();

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success']) {
            final List bookingsJson = result['bookings'];
            _bookings = bookingsJson
                .map((json) => BookingModel.fromJson(json))
                .toList();
          } else {
            _errorMessage = result['message'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan: $e';
        });
      }
    }
  }

  // Fungsi baru untuk mendapatkan pesanan berdasarkan status
  Future<void> _fetchBookingsByStatus(String status) async {
    // Jika status = semua, gunakan API yang lama
    if (status == 'semua') {
      return _fetchBookings();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentStatus = status;
    });

    try {
      // Untuk status 'menunggu', kita ambil dari API getTailorBookings dan filter
      if (status == 'menunggu') {
        final result = await ApiService.getTailorBookings();

        if (mounted) {
          setState(() {
            _isLoading = false;
            if (result['success']) {
              final List bookingsJson =
                  result['bookings'] ?? result['data'] ?? [];
              print(
                  'DEBUG: Got ${bookingsJson.length} bookings, filtering for reservasi');

              // Filter hanya pesanan dengan status 'reservasi'
              final List filteredBookings = bookingsJson.where((booking) {
                final String bookingStatus =
                    (booking['status'] ?? '').toString().toLowerCase();
                print('DEBUG: Booking status: $bookingStatus');
                return bookingStatus == 'reservasi';
              }).toList();

              print(
                  'DEBUG: Found ${filteredBookings.length} bookings with reservasi status');

              _bookings = filteredBookings
                  .map((json) => BookingModel.fromJson(json))
                  .toList();
            } else {
              _errorMessage = result['message'];
            }
          });
        }
      } else {
        // Untuk status lain (diterima, diproses, selesai, dibatalkan)
        final result = await ApiService.getTailorBookingsByStatus(status);

        if (mounted) {
          setState(() {
            _isLoading = false;
            if (result['success']) {
              final List bookingsJson =
                  result['bookings'] ?? result['data'] ?? [];
              _bookings = bookingsJson
                  .map((json) => BookingModel.fromJson(json))
                  .toList();
            } else {
              _errorMessage = result['message'];
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan: $e';
        });
      }
      print('ERROR: Failed to fetch bookings by status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(builder: (context, userProvider, child) {
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
        backgroundColor: Colors.grey.shade50,
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
                          'assets/images/tailor_default.png',
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
              Text(
                user.name,
                style: const TextStyle(
                  color: Color(0xFF1A2552),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF1A2552)),
              onPressed: () {
                // Refresh data sesuai dengan status yang sedang aktif
                if (_currentStatus == 'semua') {
                  _fetchBookings();
                } else {
                  _fetchBookingsByStatus(_currentStatus);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined,
                  color: Color(0xFF1A2552)),
              onPressed: () {
                // Navigasi ke halaman kalender jadwal
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SchedulePage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Tab filter untuk status pesanan
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        _buildStatusTab('semua', 'Semua'),
                        _buildStatusTab('menunggu', 'Menunggu'),
                        _buildStatusTab('diproses', 'Sedang Diproses'),
                        _buildStatusTab('selesai', 'Selesai'),
                        _buildStatusTab('dibatalkan', 'Dibatalkan'),
                      ],
                    ),
                  ),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                ],
              ),
            ),

            // Tombol refresh
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text('Daftar Pesanan',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade800)),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      // Refresh data sesuai dengan status yang sedang aktif
                      if (_currentStatus == 'semua') {
                        _fetchBookings();
                      } else {
                        _fetchBookingsByStatus(_currentStatus);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2552).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh,
                              color: Color(0xFF1A2552), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Refresh',
                            style: TextStyle(
                              color: Color(0xFF1A2552),
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

            // Konten utama
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? _buildErrorState(_errorMessage)
                      : _bookings.isEmpty
                          ? _buildEmptyState()
                          : _buildOrderList(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatusTab(String status, String label) {
    final bool isActive = _currentStatus == status;

    return GestureDetector(
      onTap: () {
        if (status == 'semua') {
          _fetchBookings();
        } else {
          _fetchBookingsByStatus(status);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1A2552) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF1A2552) : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A2552).withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String statusText = '';

    switch (_currentStatus) {
      case 'semua':
        statusText = 'Belum ada pesanan';
        break;
      case 'menunggu':
        statusText = 'Belum ada pesanan yang menunggu konfirmasi';
        break;
      case 'diproses':
        statusText = 'Belum ada pesanan yang sedang diproses';
        break;
      case 'selesai':
        statusText = 'Belum ada pesanan yang selesai';
        break;
      case 'dibatalkan':
        statusText = 'Belum ada pesanan yang dibatalkan';
        break;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _currentStatus == 'dibatalkan'
                    ? Icons.cancel_outlined
                    : _currentStatus == 'menunggu'
                        ? Icons.hourglass_empty
                        : Icons.inbox_outlined,
                size: 40,
                color: _currentStatus == 'dibatalkan'
                    ? Colors.red.shade300
                    : _currentStatus == 'menunggu'
                        ? Colors.orange.shade400
                        : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2552),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pesanan akan muncul di sini ketika tersedia',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    // Pesan yang lebih user-friendly untuk berbagai error
    String displayMessage = message;
    String detailMessage = '';

    // Jika pesan error terkait status tidak valid
    if (message.contains('Status tidak valid')) {
      displayMessage = 'Terjadi Kesalahan';
      if (_currentStatus == 'menunggu') {
        detailMessage =
            'Tidak dapat memuat pesanan yang menunggu konfirmasi. Silakan gunakan tab "Semua" untuk melihat semua pesanan.';
      } else {
        detailMessage = 'Status tidak valid. Coba pilih tab status lainnya.';
      }
    } else if (message.contains('Token tidak ditemukan')) {
      displayMessage = 'Sesi Habis';
      detailMessage = 'Silakan login kembali untuk melanjutkan.';
    } else if (message.contains('No connection')) {
      displayMessage = 'Tidak Ada Koneksi Internet';
      detailMessage = 'Periksa koneksi internet Anda dan coba lagi.';
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2552),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              detailMessage.isNotEmpty ? detailMessage : message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_currentStatus == 'semua') {
                  _fetchBookings();
                } else {
                  _fetchBookingsByStatus(_currentStatus);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2552),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return _buildOrderCard(booking);
      },
    );
  }

  Widget _buildOrderCard(BookingModel booking) {
    // Mendapatkan warna berdasarkan status
    Color statusColor;
    switch (booking.status.toLowerCase()) {
      case 'diterima':
        statusColor = Colors.green;
        break;
      case 'diproses':
        statusColor = Colors.blue;
        break;
      case 'selesai':
        statusColor = Colors.purple;
        break;
      case 'dibatalkan':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    // Debug untuk foto profil
    final String? photoPath = booking.getCustomerPhoto();
    final String photoUrl =
        photoPath != null ? _getFullProfilePhotoUrl(photoPath) : '';
    print('DEBUG: Customer photo path: $photoPath');
    print('DEBUG: Full photo URL: $photoUrl');

    // Cek apakah status adalah reservasi
    final bool isReservasi = booking.status.toLowerCase() == 'reservasi';

    // Cek status pembayaran
    final String paymentStatus = (booking.paymentStatus ?? '').toLowerCase();
    final bool isPaid = paymentStatus == 'paid';

    // Cek apakah pesanan dibatalkan
    final bool isCancelled = booking.status.toLowerCase() == 'dibatalkan';
    final String? rejectionReason = booking.rejectionReason;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailPage(
                  booking: booking,
                ),
              ),
            ).then((_) {
              // Refresh data setelah kembali dari halaman detail
              if (_currentStatus == 'semua') {
                _fetchBookings();
              } else {
                _fetchBookingsByStatus(_currentStatus);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan status pesanan dan badge pembayaran yang lebih baik
                Row(
                  children: [
                    // Foto profil pelanggan
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                        border: Border.all(
                          color: Colors.grey.shade100,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: booking.getCustomerPhoto() != null &&
                                booking.getCustomerPhoto()!.isNotEmpty
                            ? Image.network(
                                _getFullProfilePhotoUrl(
                                    booking.getCustomerPhoto()!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                      'ERROR: Failed to load profile image: $error');
                                  return const Icon(Icons.person);
                                },
                              )
                            : const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Informasi pelanggan
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.getCustomerName(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Pesanan #${booking.id}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status badges - display both order status and payment status
                    if (booking.status.toLowerCase() == 'selesai')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Status pesanan
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple),
                            ),
                            child: const Text(
                              'Selesai',
                              style: TextStyle(
                                color: Colors.purple,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Status pembayaran
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? const Color(0xFF34A853).withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isPaid
                                    ? const Color(0xFF34A853)
                                    : Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPaid ? Icons.check_circle : Icons.pending,
                                  size: 12,
                                  color: isPaid
                                      ? const Color(0xFF34A853)
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPaid ? 'Lunas' : 'Belum Bayar',
                                  style: TextStyle(
                                    color: isPaid
                                        ? const Color(0xFF34A853)
                                        : Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      // Status pesanan saja jika bukan status 'selesai'
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          _getStatusText(booking.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                
                // Tampilkan kode transaksi jika tersedia
                if (booking.transactionCode != null && booking.transactionCode!.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 14, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          booking.transactionCode!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                Divider(color: Colors.grey.shade100, thickness: 1),
                const SizedBox(height: 16),

                // Tampilan khusus untuk status reservasi
                if (isReservasi) ...[
                  // Menampilkan tanggal janji
                  _buildOrderDetail(
                      'Tanggal Janji', booking.getFormattedDate()),
                  const SizedBox(height: 8),
                  // Menampilkan waktu
                  _buildOrderDetail('Waktu', booking.appointmentTime),
                  const SizedBox(height: 8),
                  // Menampilkan jenis layanan
                  _buildOrderDetail('Jenis Layanan', booking.serviceType),
                  const SizedBox(height: 8),
                  // Menampilkan kategori
                  _buildOrderDetail('Kategori', booking.category),
                ] else ...[
                  // Detail pesanan untuk status selain reservasi (tampilan default)
                  _buildOrderDetail(
                      'Tanggal Janji', booking.getFormattedDate()),
                  const SizedBox(height: 8),
                  _buildOrderDetail('Waktu', booking.appointmentTime),
                  const SizedBox(height: 8),
                  _buildOrderDetail('Jenis Layanan', booking.serviceType),
                  const SizedBox(height: 8),
                  _buildOrderDetail('Kategori', booking.category),
                ],
                
                // Menampilkan metode pembayaran
                if (booking.paymentMethod != null && booking.paymentMethod!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildOrderDetail('Metode Pembayaran', _getPaymentMethodText(booking.paymentMethod!)),
                ],

                // Jika status dibatalkan, tampilkan alasan penolakan
                if (isCancelled &&
                    rejectionReason != null &&
                    rejectionReason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cancel,
                            color: Colors.red.shade700, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alasan Penolakan',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rejectionReason,
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Jika status selesai dan ada tanggal pengambilan, tampilkan informasi dengan desain yang lebih modern
                if (booking.status.toLowerCase() == 'selesai' &&
                    booking.pickupDate != null &&
                    booking.pickupDate!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note,
                            color: Colors.blue.shade700, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Pengambilan: ${_formatDate(booking.pickupDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Tombol aksi berdasarkan status
                if (isReservasi)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          // Tampilkan dialog atau navigasi ke halaman penolakan
                          _showRejectDialog(booking.id);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Tolak'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          // Fungsi untuk menerima pesanan
                          try {
                            setState(() => _isLoading = true);
                            final result =
                                await ApiService.acceptBooking(booking.id);
                            setState(() => _isLoading = false);

                            if (result['success']) {
                              // Tampilkan pesan sukses
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ??
                                        'Pesanan berhasil diterima'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }

                              // Refresh data
                              if (_currentStatus == 'semua') {
                                _fetchBookings();
                              } else {
                                _fetchBookingsByStatus(_currentStatus);
                              }
                            } else {
                              // Tampilkan pesan error
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ??
                                        'Gagal menerima pesanan'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            setState(() => _isLoading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Terjadi kesalahan: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Terima'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method untuk mendapatkan status text yang lebih user-friendly
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'reservasi':
        return 'Menunggu';
      case 'diterima':
        return 'Diterima';
      case 'diproses':
        return 'Diproses';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  // Helper method untuk memastikan URL lengkap
  String _getFullProfilePhotoUrl(String photoUrl) {
    try {
      // Mencatat URL asli untuk debugging
      print('DEBUG: PhotoURL original: $photoUrl');

      // Jika URL sudah lengkap, kembalikan apa adanya
      if (photoUrl.startsWith('http')) {
        return photoUrl;
      }

      // Bersihkan URL dari karakter tidak perlu
      String cleanedUrl = photoUrl.trim();

      // Jika URL dimulai dengan "/storage"
      if (cleanedUrl.startsWith('/storage')) {
        String result = '${ApiService.imageBaseUrl}$cleanedUrl';
        print('DEBUG: Fixed URL (case 1): $result');
        return result;
      }

      // Jika dimulai dengan "storage/"
      else if (cleanedUrl.startsWith('storage/')) {
        String result = '${ApiService.imageBaseUrl}/$cleanedUrl';
        print('DEBUG: Fixed URL (case 2): $result');
        return result;
      }

      // Jika dimulai dengan "/"
      else if (cleanedUrl.startsWith('/')) {
        String result = '${ApiService.imageBaseUrl}$cleanedUrl';
        print('DEBUG: Fixed URL (case 3): $result');
        return result;
      }

      // Jika tidak memiliki awalan slash
      else {
        String result = '${ApiService.imageBaseUrl}/$cleanedUrl';
        print('DEBUG: Fixed URL (case 4): $result');
        return result;
      }
    } catch (e) {
      print('ERROR: Gagal memproses URL foto: $e untuk photoUrl=$photoUrl');
      return '${ApiService.imageBaseUrl}/placeholder.jpg'; // Return placeholder URL
    }
  }

  // Fungsi untuk menampilkan dialog penolakan pesanan
  Future<void> _showRejectDialog(int bookingId) async {
    final TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            elevation: 8,
            title: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.red.shade400,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tolak Pesanan',
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
              children: [
                const Text(
                  'Berikan alasan mengapa Anda menolak pesanan ini',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Alasan penolakan...',
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
                      borderSide: BorderSide(color: Colors.red.shade200),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                ),
                if (isSubmitting)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (reasonController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Mohon masukkan alasan penolakan'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                isSubmitting = true;
                              });

                              try {
                                final result = await ApiService.rejectBooking(
                                    bookingId, reasonController.text.trim());

                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }

                                if (context.mounted) {
                                  if (result['success']) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message'] ??
                                            'Pesanan berhasil ditolak'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    // Refresh data
                                    if (_currentStatus == 'semua') {
                                      _fetchBookings();
                                    } else {
                                      _fetchBookingsByStatus(_currentStatus);
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result['message'] ??
                                            'Gagal menolak pesanan'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Terjadi kesalahan: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Tolak Pesanan'),
                    ),
                  ),
                ],
              ),
            ],
          );
        });
      },
    );
  }

  // Helper untuk memformat tanggal
  String _formatDate(String isoDate) {
    try {
      final DateTime date = DateTime.parse(isoDate);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return isoDate;
    }
  }

  // Helper function untuk mendapatkan teks metode pembayaran
  String _getPaymentMethodText(String method) {
    switch (method.toLowerCase()) {
      case 'transfer_bank':
        return 'Transfer Bank';
      case 'cod':
      case 'cash_on_delivery':
        return 'Cash on Delivery (COD)';
      default:
        return method;
    }
  }
}
