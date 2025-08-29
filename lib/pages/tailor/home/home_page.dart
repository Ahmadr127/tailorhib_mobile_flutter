import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/controllers/wallet_wd_controller.dart';
import '../schedule/schedule_page.dart';
import '../../../core/utils/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Format currency
  final currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // State variables untuk data dashboard
  List<Map<String, dynamic>> _incomingBookings = [];
  int _currentMonthEarnings = 0;
  int _totalEarnings = 0;
  double _averageRating = 0;
  int _totalCompletedOrders = 0;
  bool _isLoading = true;
  String _errorMessage = '';
  late WalletWDController _walletController;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _walletController = Provider.of<WalletWDController>(context, listen: false);
    _loadWalletData();
  }

  // Fungsi untuk mengambil data dashboard
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await ApiService.getTailorDashboard();

      setState(() {
        _isLoading = false;

        if (result['success']) {
          final data = result['data'];

          // Update state variables dengan konversi tipe data yang benar
          _incomingBookings =
              List<Map<String, dynamic>>.from(data['incoming_bookings'] ?? []);

          // Konversi string ke int untuk earnings
          _currentMonthEarnings =
              _parseStringToInt(data['current_month_earnings']);
          _totalEarnings = _parseStringToInt(data['total_earnings']);

          // Pastikan rating dikonversi dengan benar ke double
          _averageRating = _parseStringToDouble(data['average_rating']);

          // Konversi total orders ke int
          _totalCompletedOrders =
              _parseStringToInt(data['total_completed_orders']);

          print('DEBUG: Dashboard data loaded successfully');
        } else {
          _errorMessage = result['message'] ?? 'Gagal memuat data dashboard';
          print('DEBUG: Failed to load dashboard data: $_errorMessage');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
      print('ERROR: Failed to load dashboard data: $e');
    }
  }

  Future<void> _loadWalletData() async {
    await _walletController.fetchWalletInfo();
  }

  // Helper method untuk mengkonversi string ke int dengan aman
  int _parseStringToInt(dynamic value) {
    if (value == null) return 0;

    try {
      if (value is int) return value;
      if (value is double) return value.toInt();

      if (value is String) {
        // Hapus semua karakter non-numerik (seperti koma, titik, dll)
        final cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');

        // Jika string mengandung titik desimal, konversi ke double dahulu
        if (cleanValue.contains('.')) {
          return double.parse(cleanValue).toInt();
        }

        return int.parse(cleanValue);
      }

      return 0;
    } catch (e) {
      print('ERROR: Gagal konversi ke int: $e untuk nilai: $value');
      return 0;
    }
  }

  // Helper method untuk mengkonversi string ke double dengan aman
  double _parseStringToDouble(dynamic value) {
    if (value == null) return 0.0;

    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();

      if (value is String) {
        // Hapus semua karakter non-numerik (kecuali titik desimal)
        final cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.parse(cleanValue);
      }

      return 0.0;
    } catch (e) {
      print('ERROR: Gagal konversi ke double: $e untuk nilai: $value');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, WalletWDController>(
      builder: (context, userProvider, walletController, child) {
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
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF1A2552)),
                onPressed: () {
                  _loadDashboardData();
                  _loadWalletData();
                },
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                              onPressed: () {
                                _loadDashboardData();
                                _loadWalletData();
                              },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A2552),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await Future.wait([
                            _loadDashboardData(),
                            _loadWalletData(),
                          ]);
                        },
                        child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banner card
                            _buildBannerCard(),

                                const SizedBox(height: 24),

                                // Wallet card
                                _buildWalletCard(walletController),

                            const SizedBox(height: 24),

                            // Total Penghasilan card
                            _buildIncomeCard(),

                            const SizedBox(height: 24),

                            // Statistik Card
                            _buildStatisticsCard(),
                          ],
                        ),
                      ),
                    ),
        ),
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

  Widget _buildBannerCard() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2552),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background design elements
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -40,
            top: -40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Text section
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat Datang Kembali!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Anda telah menyelesaikan $_totalCompletedOrders pesanan.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Rating indicator
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Image or icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.content_cut,
                      color: Color(0xFF1A2552),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(WalletWDController walletController) {
    final walletInfo = walletController.walletInfo;
    final balance = walletInfo?.getBalanceAsDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Saldo Wallet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2552),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A2552),
                Color(0xFF2C3E7B),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background design elements
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -40,
                top: -40,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Total Saldo',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currencyFormat.format(balance),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to withdrawal page
                            Navigator.pushNamed(context, AppRoutes.withdrawal);
                          },
                          icon: const Icon(Icons.arrow_upward, size: 18),
                          label: const Text('Tarik Dana'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1A2552),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            // Navigate to transaction history page
                            Navigator.pushNamed(context, AppRoutes.walletHistory);
                          },
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('Riwayat'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Penghasilan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2552),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bulan ini',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currencyFormat.format(_currentMonthEarnings),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2552),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currencyFormat.format(_totalEarnings),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2552),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2552),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatisticItem(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  value: _totalCompletedOrders.toString(),
                  label: 'Selesai',
                ),
                _buildStatisticItem(
                  icon: Icons.star,
                  color: Colors.amber,
                  value: _averageRating.toStringAsFixed(1),
                  label: 'Rating',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
