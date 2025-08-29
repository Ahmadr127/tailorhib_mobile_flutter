import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/wallet_wd_controller.dart';
import '../../../core/models/wallet_transaction_model.dart';
import 'dart:developer' as developer;
import '../../../core/services/api_service.dart';
import '../../../core/services/wallet_wd_service.dart';
import '../../../core/utils/url_helper.dart';
import '../../../core/utils/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WalletHistoryPage extends StatefulWidget {
  const WalletHistoryPage({super.key});

  @override
  State<WalletHistoryPage> createState() => _WalletHistoryPageState();
}

class _WalletHistoryPageState extends State<WalletHistoryPage> {
  // Format currency
  final currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Format date
  late final DateFormat dateFormat;
  bool _initialized = false;
  final bool _isDebugMode = false; // Nonaktifkan mode debug untuk user
  String _selectedStatusFilter = 'all'; // Default filter: semua status
  bool _isBalanceExpanded = false; // State untuk panel saldo (collapsed by default)

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('id_ID', null);
    setState(() {
      dateFormat = DateFormat.yMMMMd('id_ID').add_Hm();
      _initialized = true;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    if (!_initialized || !mounted) return;

    try {
      _logInfo('Memuat data wallet...');
      final controller = Provider.of<WalletWDController>(context, listen: false);
      await controller.fetchWalletInfo();
      await controller.fetchBankAccounts();
      await controller.fetchWithdrawalHistory(); // Tanpa filter
      _logInfo('Selesai memuat data wallet');
    } catch (e) {
      _logInfo('Error memuat data wallet: $e');
    }
  }

  // Metode untuk memuat data penarikan berdasarkan status
  Future<void> _loadWithdrawalWithStatus(String status) async {
    if (!_initialized || !mounted) return;

    try {
      _logInfo('Memuat withdrawal dengan status: $status');
      final controller = Provider.of<WalletWDController>(context, listen: false);
      await controller.fetchWithdrawalHistory(status: status);
      _logInfo('Selesai memuat withdrawal dengan status: $status');
    } catch (e) {
      _logInfo('Error memuat withdrawal: $e');
    }
  }

  // Fungsi untuk membantu debugging wallet service
  Future<void> _debugWalletService() async {
    if (!_isDebugMode) return;
    
    try {
      _logInfo('====== DEBUG WALLET SERVICE ======');
      
      // Debug token
      final token = await ApiService.getToken();
      _logInfo('Token autentikasi: ${token != null ? 'Ada (${token.substring(0, 10)}...)' : 'Null'}');
      
      // Debug base URL
      final baseUrl = UrlHelper.baseUrl;
      _logInfo('Base URL API: $baseUrl');
      
      // Debug endpoint penarikan
      final withdrawalEndpoint = '$baseUrl/withdrawals';
      _logInfo('Endpoint withdrawal: $withdrawalEndpoint');
      
      _logInfo('====== END DEBUG WALLET SERVICE ======');
    } catch (e, stackTrace) {
      _logError('Error saat debugging wallet service', e, stackTrace);
    }
  }
  
  // Fungsi untuk debug informasi wallet
  void _debugWalletInfo(WalletWDController controller) {
    if (!_isDebugMode) return;
    
    _logInfo('====== DEBUG WALLET INFO ======');
    final walletInfo = controller.walletInfo;
    
    if (walletInfo == null) {
      _logInfo('Wallet Info: null');
    } else {
      _logInfo('Wallet Balance: ${walletInfo.balance}');
      _logInfo('Transactions count: ${walletInfo.transactions.length}');
      
      if (walletInfo.transactions.isNotEmpty) {
        _logInfo('Latest transaction: ${walletInfo.transactions.first.description} - ${walletInfo.transactions.first.amount}');
      }
    }
    
    _logInfo('Error message: ${controller.errorMessage}');
    _logInfo('====== END DEBUG WALLET INFO ======');
  }
  
  // Fungsi untuk debug riwayat penarikan
  void _debugWithdrawalHistory(WalletWDController controller) {
    if (!_isDebugMode) return;
    
    _logInfo('====== DEBUG WITHDRAWAL HISTORY ======');
    final withdrawals = controller.withdrawalHistory;
    
    _logInfo('Withdrawal count: ${withdrawals.length}');
    
    if (withdrawals.isEmpty) {
      _logInfo('Tidak ada data penarikan.');
    } else {
      for (int i = 0; i < withdrawals.length; i++) {
        final withdrawal = withdrawals[i];
        _logInfo('Withdrawal #${i + 1}:');
        _logInfo('- amount: ${withdrawal['amount']}');
        _logInfo('- status: ${withdrawal['status']}');
        _logInfo('- created_at: ${withdrawal['created_at']}');
        
        final bankAccount = withdrawal['bank_account'];
        _logInfo('- bank: ${bankAccount['bank_name']}');
        _logInfo('- account: ${bankAccount['account_number']}');
      }
    }
    
    _logInfo('Error message: ${controller.errorMessage}');
    _logInfo('====== END DEBUG WITHDRAWAL HISTORY ======');
  }
  
  // Fungsi helper untuk logging
  void _logInfo(String message) {
    if (_isDebugMode && mounted) {
      // Tambahkan prefix untuk membedakan log dari halaman ini
      developer.log('[WALLET HISTORY] $message', name: 'TailorHub');
    }
  }
  
  // Metode ini tidak akan melakukan apa-apa di mode produksi
  // tapi tetap disediakan untuk memudahkan debugging jika diperlukan
  void _logError(String message, dynamic error, StackTrace? stackTrace) {
    if (_isDebugMode) {
      developer.log(
        '[WALLET HISTORY ERROR] $message: $error',
        name: 'TailorHub',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (BuildContext context) {
          final TabController tabController = DefaultTabController.of(context);
          
          // Tambahkan listener untuk tab aktif jika diperlukan
          tabController.addListener(() {
            // Jika diperlukan kode reaksi terhadap perubahan tab
          });
                  
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Riwayat Wallet',
                style: TextStyle(
                  color: Color(0xFF1A2552),
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF1A2552)),
              bottom: const TabBar(
                labelColor: Color(0xFF1A2552),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF1A2552),
                tabs: [
                  Tab(text: 'Transaksi'),
                  Tab(text: 'Penarikan'),
                ],
              ),
            ),
            body: Consumer<WalletWDController>(
              builder: (context, walletController, child) {
                if (walletController.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (walletController.errorMessage.isNotEmpty) {
                  _logInfo('Error dari controller: ${walletController.errorMessage}');
                  
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          walletController.errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A2552),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                // Tambahkan widget Card untuk menampilkan informasi saldo
                return Column(
                  children: [
                    // Info Card - Informasi Saldo
                    if (walletController.walletInfo != null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isBalanceExpanded = !_isBalanceExpanded;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Informasi Saldo',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A2552),
                                        ),
                                      ),
                                      Icon(
                                        _isBalanceExpanded 
                                            ? Icons.keyboard_arrow_up 
                                            : Icons.keyboard_arrow_down,
                                        color: const Color(0xFF1A2552),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total'),
                                      Text(
                                        currencyFormat.format(walletController.walletInfo!.getBalanceAsDouble()),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Detail saldo tertahan dan tersedia
                                if (_isBalanceExpanded)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
                                    child: Column(
                                      children: [
                                        const Divider(),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Saldo Tertahan'),
                                            Text(
                                              currencyFormat.format(walletController.walletInfo!.getPendingWithdrawalsAsDouble()),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Saldo Tersedia'),
                                            Text(
                                              currencyFormat.format(walletController.walletInfo!.getAvailableBalanceAsDouble()),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade700,
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
                        ),
                      ),
                  
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab Transaksi
                          _buildTransactionsTab(walletController),

                          // Tab Penarikan
                          _buildWithdrawalsTab(walletController),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            floatingActionButton: null,
          );
        }
      ),
    );
  }

  Widget _buildTransactionsTab(WalletWDController walletController) {
    final transactions = walletController.walletInfo?.transactions ?? [];

    if (transactions.isEmpty) {
      _logInfo('Transactions tab: Data kosong');
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada transaksi',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    _logInfo('Transactions tab: Menampilkan ${transactions.length} transaksi');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: transaction.getTypeColor().withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        transaction.getTypeIcon(),
                        color: transaction.getTypeColor(),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.description,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(DateTime.parse(transaction.createdAt)),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${transaction.type.toLowerCase() == 'credit' ? '+' : '-'} ${currencyFormat.format(transaction.getAmountAsDouble())}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: transaction.getTypeColor(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWithdrawalsTab(WalletWDController walletController) {
    final withdrawals = walletController.withdrawalHistory;

    // Widget untuk chip filter
    Widget buildFilterChip(String label, String value) {
      final isSelected = _selectedStatusFilter == value;
      return InkWell(
        onTap: () {
          setState(() {
            _selectedStatusFilter = value;
          });
          if (value == 'all') {
            _loadData();
          } else {
            _loadWithdrawalWithStatus(value);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1A2552) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    // Widget untuk filter status
    Widget buildStatusFilter() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Status:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A2552),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    buildFilterChip('Semua', 'all'),
                    const SizedBox(width: 8),
                    buildFilterChip('Menunggu', 'pending'),
                    const SizedBox(width: 8),
                    buildFilterChip('Diproses', 'processing'),
                    const SizedBox(width: 8),
                    buildFilterChip('Selesai', 'completed'),
                    const SizedBox(width: 8),
                    buildFilterChip('Ditolak', 'rejected'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (withdrawals.isEmpty) {
      _logInfo('Withdrawals tab: Data kosong');
      
      return Column(
        children: [
          // Tampilkan filter meskipun data kosong
          buildStatusFilter(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat penarikan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tampilkan tombol untuk melakukan penarikan jika data kosong
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Navigasi ke halaman penarikan dan tunggu hasil
                      final result = await Navigator.pushNamed(context, AppRoutes.withdrawal);
                      
                      // Jika hasil = true (penarikan berhasil), refresh data
                      if (result == true && mounted) {
                        _loadData();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2552),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Ajukan Penarikan Dana'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    _logInfo('Withdrawals tab: Menampilkan ${withdrawals.length} penarikan');
    
    return Column(
      children: [
        // Filter status
        buildStatusFilter(),
        // List penarikan
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: withdrawals.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final withdrawal = withdrawals[index];
                  final bankAccount = withdrawal['bank_account'];
                  final status = withdrawal['status'] as String;
                  final amount = double.parse(withdrawal['amount'].toString());
                  final createdAt = DateTime.parse(withdrawal['created_at']);
                  final processedAt = withdrawal['processed_at'] != null 
                      ? DateTime.parse(withdrawal['processed_at']) 
                      : null;
                  final proofOfPayment = withdrawal['proof_of_payment'];

                  // Warna status
                  final statusColor = walletController.getWithdrawalStatusColor(status);
                  final statusText = walletController.getWithdrawalStatusText(status);

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Baris pertama: ID Penarikan & Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ID #${withdrawal['id']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      status.toLowerCase() == 'completed' 
                                        ? Icons.check_circle
                                        : status.toLowerCase() == 'rejected'
                                            ? Icons.cancel
                                            : Icons.pending_actions,
                                      size: 12,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: statusColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Bank information
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A2552).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance,
                                    color: Color(0xFF1A2552),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bankAccount['bank_name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        bankAccount['account_number'],
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      Text(
                                        bankAccount['account_holder_name'],
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Amount information
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Jumlah Penarikan:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                currencyFormat.format(amount),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A2552),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Dates information
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tanggal Pengajuan:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateFormat.format(createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (processedAt != null)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tanggal Proses:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateFormat.format(processedAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          // Bukti pembayaran section (if available)
                          if (proofOfPayment != null)
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(10),
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
                                      Icon(
                                        Icons.receipt_long,
                                        size: 16,
                                        color: Colors.blue.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Bukti Pembayaran Tersedia',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      // Buka halaman untuk melihat bukti pembayaran dengan URL lengkap
                                      // Gunakan URL API langsung dan pastikan path lengkap termasuk direktori proof_of_payments/
                                      final String fullPath = proofOfPayment;
                                      final paymentUrl = 'https://api.tailors.stuffly.my.id/storage/$fullPath';
                                      print('Opening payment proof image: $paymentUrl');
                                      _showPaymentProofDialog(context, paymentUrl);
                                    },
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('Lihat Bukti Pembayaran'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue.shade700,
                                      side: BorderSide(color: Colors.blue.shade300),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Alasan penolakan
                          if (withdrawal['rejection_reason'] != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 16,
                                        color: Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Alasan Penolakan:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    withdrawal['rejection_reason'],
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Metode untuk menampilkan bukti pembayaran dalam dialog
  void _showPaymentProofDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      useSafeArea: true,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Bukti Pembayaran',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Stack(
              children: [
                // Image viewer
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        print('Error loading image: $error for URL: $url');
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                'Gagal memuat gambar bukti pembayaran: ${error.toString()}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                // Re-show the dialog after a short delay
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  _showPaymentProofDialog(context, imageUrl);
                                });
                              },
                            ),
                          ],
                        );
                      },
                      fit: BoxFit.contain,
                      fadeInDuration: const Duration(milliseconds: 200),
                    ),
                  ),
                ),
                
                // Bottom info (optional - info tentang bukti pembayaran)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Text(
                      'Bukti pembayaran penarikan dana',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
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