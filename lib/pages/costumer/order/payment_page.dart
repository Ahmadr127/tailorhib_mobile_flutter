import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/midtrans_controller.dart';
import '../../../core/services/midtrans_service.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class PaymentPage extends StatefulWidget {
  final int bookingId;
  final String transactionCode;
  final dynamic totalPrice;

  const PaymentPage({
    super.key,
    required this.bookingId,
    required this.transactionCode,
    required this.totalPrice,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isInitialized = false;
  bool _isLoading = false;
  late MidtransController _midtransController;
  late int _bookingId;
  late int _numericTotalPrice;
  final List<Timer> _statusTimers = [];
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    _numericTotalPrice = _parseTotalPrice(widget.totalPrice);
    _initPayment();
  }

  int _parseTotalPrice(dynamic price) {
    print('DEBUG: Parsing price value (original): $price');
    print('DEBUG: Price type: ${price.runtimeType}');
    
    if (price is int) {
      print('DEBUG: Price is int: $price');
      return price;
    }
    
    if (price is double) {
      print('DEBUG: Price is double: $price');
      return price.toInt();
    }
    
    if (price is String) {
      try {
        // Hapus semua karakter non-angka
        String cleanPrice = price.replaceAll(RegExp(r'[^0-9]'), '');
        print('DEBUG: Cleaned price string: $cleanPrice');
        
        // Konversi ke integer
        int numericPrice = int.parse(cleanPrice);
        print('DEBUG: Parsed numeric price: $numericPrice');
        return numericPrice;
      } catch (e) {
        print('ERROR: Gagal parsing harga: $e');
        return 0;
      }
    }
    
    print('WARNING: Tipe harga tidak dikenali: ${price.runtimeType}');
    return 0;
  }

  void _initPayment() {
    setState(() {
      _isInitialized = false;
    });
      
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _midtransController = Provider.of<MidtransController>(context, listen: false);
        
      // Reset controller untuk memastikan state bersih
      _midtransController.reset();
        
      // Inisiasi pembayaran
      await _openPaymentPage();
        
      if (mounted) {
        if (_midtransController.isPaymentInitiated) {
          setState(() {
            _isInitialized = true;
          });
          
          // Mulai pengecekan status pembayaran secara periodik
          _startPaymentStatusCheck();
        } else {
          _showErrorSnackBar(_midtransController.errorMessage);
            
          // Kembali setelah error
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    });
  }

  Future<void> _openPaymentPage() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final result = await _midtransController.initiatePayment(_bookingId);
      
      if (result['success'] == true) {
        print('URL pembayaran siap: ${_midtransController.redirectUrl}');
        
        // Inisialisasi selesai
        setState(() {
          _isLoading = false;
        });
        
        if (_midtransController.redirectUrl.isNotEmpty) {
          // Buka halaman pembayaran dengan WebView dan perluas cakupan pengecekan
          print('Membuka halaman WebView...');
          
          // Mulai pemeriksaan status sebelum membuka WebView
          _startPaymentStatusCheck();
          
          // Buka halaman pembayaran
          await _midtransController.openPaymentPage(context);
          
          // Setelah WebView ditutup, periksa status 
          if (mounted) {
            // Pastikan pembayaran statusnya diperiksa
            final statusResult = await _midtransController.checkPaymentStatus(_bookingId);
            
            // Cek apakah pembayaran berhasil
            if (statusResult['success'] == true && 
                (_midtransController.paymentStatus == 'settlement' || 
                 _midtransController.paymentStatus == 'capture' || 
                 _midtransController.paymentStatus == 'paid')) {
              // Pembayaran berhasil, tampilkan dialog dan kembali
              _showPaymentSuccessDialog();
            }
          }
        } else {
          _showErrorSnackBar('URL pembayaran tidak tersedia');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(result['message'] ?? 'Gagal menginisiasi pembayaran');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Terjadi kesalahan: $e');
      print('Error saat membuka halaman pembayaran: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Dialog pembayaran berhasil
  void _showPaymentSuccessDialog() {
    if (!mounted) return;
    
    // Mencegah dialog ditampilkan berulang kali
    if (ModalRoute.of(context)?.isCurrent != true) {
      print('Halaman tidak aktif, tidak menampilkan dialog sukses');
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Mencegah dialog ditutup dengan tombol back
        child: AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade400,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pembayaran Berhasil',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pembayaran Anda telah berhasil diproses.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda dapat melihat detail pembayaran pada halaman ini.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Hanya tutup dialog, tidak keluar dari halaman payment
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Lihat Detail',
                style: TextStyle(
                  color: Color(0xFF1A2552),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Tutup dialog dan kembali ke halaman sebelumnya
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2552),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Kembali',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startPaymentStatusCheck() {
    // Cancel timer lama jika ada
    for (var timer in _statusTimers) {
      timer.cancel();
    }
    _statusTimers.clear();
    
    // Buat timer baru untuk pemeriksaan status - hanya memeriksa sekali saat awal dan setelah WebView ditutup
    // Tidak lagi menggunakan timer berkala
      
      try {
        // Hindari cek bertumpuk
        if (_isCheckingStatus) return;
        _isCheckingStatus = true;
        
      print('Mengecek status pembayaran awal... (${DateTime.now()})');
      // Coba periksa status secara manual terlebih dahulu
      _midtransController.checkPaymentStatusManual(_bookingId).then((dynamic result) {
        // Jika pemeriksaan manual gagal, gunakan metode normal
        if ((result as Map<String, dynamic>)['success'] != true) {
          return _midtransController.checkPaymentStatus(_bookingId);
        }
        return result;
      }).then((dynamic result) {
        final Map<String, dynamic> paymentResult = result as Map<String, dynamic>;
        // Periksa kembali mounted setelah await, untuk mencegah update pada widget yang sudah di-dispose
        if (!mounted) {
          _isCheckingStatus = false;
          return;
        }
        
        _isCheckingStatus = false;
        
        if (paymentResult['success'] == true) {
          // Jika status pembayaran berhasil
          if (_midtransController.paymentStatus == 'settlement' || 
              _midtransController.paymentStatus == 'capture' || 
              _midtransController.paymentStatus == 'paid') {
            // Pembayaran berhasil, tampilkan dialog
            print('Status pembayaran: ${_midtransController.paymentStatus} - pembayaran berhasil!');
            
            // Periksa kembali apakah masih mounted sebelum menampilkan dialog
            if (mounted) {
              // Tampilkan dialog sukses
              _showPaymentSuccessDialog();
            }
          } else {
            // Pembayaran belum selesai
            print('Status pembayaran: ${_midtransController.paymentStatus} - masih menunggu');
            if (mounted) {
              setState(() {
                // Update UI jika diperlukan
              });
            }
          }
        } else {
          print('Gagal memeriksa status: ${paymentResult['message']}');
        }
      }).catchError((e) {
        _isCheckingStatus = false;
        print('Error saat cek status: $e');
      });
      } catch (e) {
        _isCheckingStatus = false;
        print('Error saat cek status: $e');
      }
  }

  @override
  Widget build(BuildContext context) {
    final midtransController = Provider.of<MidtransController>(context);
    
    // Pastikan harga yang diterima dari API sudah dalam format yang benar
    print('DEBUG: Original price from widget: ${widget.totalPrice}');
    print('DEBUG: Parsed numeric price from widget: $_numericTotalPrice');
    print('DEBUG: MidtransController payment data: ${midtransController.paymentData}');
    
    // Prioritaskan mengambil total_price dari API response jika tersedia
    int priceToDisplay = _numericTotalPrice;
    if (midtransController.paymentData['total_price'] != null) {
      // Parse total_price dari API yang lebih akurat
      String apiPrice = midtransController.paymentData['total_price'].toString();
      print('DEBUG: API price string: $apiPrice');
      
      // Bersihkan string harga dari karakter non-angka (kecuali titik desimal)
      String cleanApiPrice = apiPrice.replaceAll(RegExp(r'[^0-9.]'), '');
      print('DEBUG: Clean API price: $cleanApiPrice');
      
      // Jika ada titik desimal, ambil bagian sebelum desimal
      if (cleanApiPrice.contains('.')) {
        cleanApiPrice = cleanApiPrice.split('.')[0];
      }
      print('DEBUG: Final clean API price: $cleanApiPrice');
      
      // Parse ke integer
      int apiPriceInt = int.tryParse(cleanApiPrice) ?? _numericTotalPrice;
      print('DEBUG: API price parsed to int: $apiPriceInt');
      
      // Gunakan nilai dari API jika valid
      if (apiPriceInt > 0) {
        priceToDisplay = apiPriceInt;
      }
    }
    
    print('DEBUG: Final price to display: $priceToDisplay');
    
    // Biaya tambahan
    const int paymentServiceFee = 4000;
    // const int tailorServiceFee = 1000;
    
    // Total akhir
    final int finalTotal = priceToDisplay + paymentServiceFee;
    
    // Format rupiah menggunakan angka yang benar
    final formattedBasePrice = _formatRupiah(priceToDisplay);
    final formattedPaymentFee = _formatRupiah(paymentServiceFee);
    // final formattedTailorFee = _formatRupiah(tailorServiceFee);
    final formattedTotalPrice = _formatRupiah(finalTotal);
    
    print('DEBUG: Final formatted price: $formattedTotalPrice');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: const Color(0xFF1A2552),
        foregroundColor: Colors.white,
        actions: [
          // Tombol refresh manual untuk status pembayaran
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh status pembayaran',
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              try {
                // Coba periksa status secara manual terlebih dahulu
                final manualResult = await _midtransController.checkPaymentStatusManual(_bookingId);
                if (!manualResult['success']) {
                  // Jika gagal, gunakan metode normal
                await _midtransController.checkPaymentStatus(_bookingId);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Status pembayaran diperbarui'),
                    duration: Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                _showErrorSnackBar('Gagal memperbarui status: $e');
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        ],
      ),
      body: midtransController.isLoading || _isLoading
        ? const Center(child: CircularProgressIndicator())
        : !_isInitialized
          ? const Center(child: Text('Memuat halaman pembayaran...'))
          : RefreshIndicator(
              onRefresh: () async {
                try {
                  await _midtransController.checkPaymentStatus(_bookingId);
                } catch (e) {
                  if (mounted) {
                    _showErrorSnackBar('Gagal memeriksa status: $e');
                  }
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info refresh
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, 
                              color: Colors.blue.shade800, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cek Status Pembayaran',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tekan tombol refresh di pojok kanan atas atau tarik layar ke bawah untuk memperbarui status pembayaran secara manual',
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                    // Header payment page
                    Container(
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
                          // Header dengan ikon
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2552).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Color(0xFF1A2552),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                    const Text(
                      'Ringkasan Pembayaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A2552),
                      ),
                              ),
                            ],
                    ),
                    const SizedBox(height: 16),
                          
                          // Kode transaksi
                    _buildInfoRow('Kode Transaksi', widget.transactionCode),
                          
                          // Status pembayaran dengan lencana
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                      'Status Pembayaran', 
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const Text(': '),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(midtransController.paymentStatus).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _getStatusColor(midtransController.paymentStatus),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                      MidtransService.getPaymentStatusText(midtransController.paymentStatus),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(midtransController.paymentStatus),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          // Rincian biaya layanan
                          // Item biaya dengan format yang lebih bagus
                          _buildPriceItem("Biaya Jahit", formattedBasePrice, isMain: true),
                          _buildPriceItem("Biaya Layanan Payment", formattedPaymentFee),
                         
                          
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          
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
                                'Rp $formattedTotalPrice',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A2552),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Tombol pembayaran
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: midtransController.isPaymentInitiated ? () => _midtransController.openPaymentPage(context) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2552),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Buka Halaman Pembayaran'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Catatan informasi
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.amber[800]),
                              const SizedBox(width: 8),
                          Text(
                                'Catatan Penting:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('1. Anda akan diarahkan ke halaman pembayaran Midtrans.'),
                          const Text('2. Pilih metode pembayaran yang Anda inginkan.'),
                          const Text('3. Setelah pembayaran berhasil, Anda akan kembali ke aplikasi.'),
                          const Text('4. Tekan tombol refresh di pojok kanan atas untuk memeriksa status pembayaran.'),
                          const Text('5. Status mungkin tidak langsung berubah, mohon tunggu beberapa saat.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

  // Widget untuk menampilkan baris informasi
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? const Color(0xFF1A2552),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk mendapatkan warna berdasarkan status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'settlement':
      case 'capture':
      case 'paid':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade700;
      case 'deny':
      case 'cancel':
      case 'expire':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  void _showCopyLinkDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tidak dapat membuka halaman pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kami tidak dapat membuka halaman pembayaran secara otomatis. Silakan salin link pembayaran berikut dan buka di browser Anda:',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link pembayaran disalin ke clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk memformat rupiah dengan pemisah titik sebagai ribuan
  String _formatRupiah(int value) {
    print('DEBUG: Format Rupiah - Input value: $value');
    
    // Format khusus tanpa desimal, dengan pemisah ribuan berupa titik
    final formatter = NumberFormat('#,###', 'id');
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 0;
    
    // Format angka dan ganti koma dengan titik
    String formatted = formatter.format(value);
    formatted = formatted.replaceAll(',', '.');
    
    print('DEBUG: Format Rupiah - Final formatted: $formatted');
    
    return formatted;
  }

  @override
  void dispose() {
    // Batalkan semua timer untuk mencegah callback yang tidak diinginkan
    for (var timer in _statusTimers) {
      timer.cancel();
    }
    _statusTimers.clear();
    super.dispose();
  }
}
