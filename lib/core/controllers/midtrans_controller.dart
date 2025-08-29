import 'package:flutter/material.dart';
import '../services/midtrans_service.dart';
// import 'package:url_launcher/url_launcher.dart';
import '../../pages/costumer/order/midtrans_webview_page.dart';

class MidtransController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isPaymentInitiated = false;
  String _errorMessage = '';
  Map<String, dynamic> _paymentData = {};
  String _redirectUrl = '';
  String _snapToken = '';
  String _paymentStatus = 'unpaid';
  int? _bookingId;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isPaymentInitiated => _isPaymentInitiated;
  String get errorMessage => _errorMessage;
  Map<String, dynamic> get paymentData => _paymentData;
  String get redirectUrl => _redirectUrl;
  String get snapToken => _snapToken;
  String get paymentStatus => _paymentStatus;
  int? get bookingId => _bookingId;
  
  // Setters
  set errorMessage(String value) {
    _errorMessage = value;
    notifyListeners();
  }
  
  set paymentStatus(String value) {
    _paymentStatus = value;
    notifyListeners();
  }
  
  // Inisiasi pembayaran Midtrans untuk booking tertentu
  Future<Map<String, dynamic>> initiatePayment(int bookingId) async {
    _isLoading = true;
    _errorMessage = '';
    _bookingId = bookingId;
    notifyListeners();
    
    try {
      final result = await MidtransService.initiatePayment(bookingId);
      
      if (result['success'] == true && result['data'] != null) {
        _isPaymentInitiated = true;
        _paymentData = result['data'];
        
        // Simpan URL dan token untuk buka website Midtrans
        _snapToken = result['data']['snap_token'] ?? '';
        _redirectUrl = result['data']['redirect_url'] ?? '';
        
        _errorMessage = '';
      } else {
        _isPaymentInitiated = false;
        _errorMessage = result['message'] ?? 'Gagal menginisiasi pembayaran';
      }
      
      _isLoading = false;
      notifyListeners();
      
      return result;
    } catch (e) {
      _isLoading = false;
      _isPaymentInitiated = false;
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Cek status pembayaran booking
  Future<Map<String, dynamic>> checkPaymentStatus(int bookingId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      print('Mengecek status pembayaran untuk booking ID: $bookingId');
      final result = await MidtransService.checkPaymentStatus(bookingId);
      
      if (result['success'] == true && result['data'] != null) {
        _paymentData = result['data'];
        _paymentStatus = result['data']['payment_status'] ?? 'unpaid';
        
        // Log informasi pembayaran yang lebih lengkap
        print('Status pembayaran diterima: $_paymentStatus');
        print('Data pembayaran: $_paymentData');
        
        // Periksa apakah sudah dibayar
        if (_paymentStatus == 'settlement' || _paymentStatus == 'capture' || _paymentStatus == 'paid') {
          print('Pembayaran terdeteksi berhasil');
        } else {
          print('Pembayaran belum selesai, status: $_paymentStatus');
        }
        
        _errorMessage = '';
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengecek status pembayaran';
        print('Gagal mengecek status pembayaran: $_errorMessage');
      }
      
      _isLoading = false;
      notifyListeners();
      
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan: $e';
      print('Error saat mengecek status pembayaran: $e');
      notifyListeners();
      
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Paksa update status pembayaran menjadi "settlement"
  Future<void> forceUpdatePaymentStatus() async {
    _paymentStatus = 'settlement';
    notifyListeners();
  }
  
  // Membuka halaman pembayaran
  Future<void> openPaymentPage(BuildContext context) async {
    try {
      print('Membuka halaman pembayaran WebView dengan URL: $redirectUrl');
      
      // Url yang akan ditampilkan jika ada masalah dalam membuka WebView
      final fallbackUrl = redirectUrl;
      
      if (redirectUrl.isEmpty) {
        print('ERROR: URL pembayaran kosong');
        Future.microtask(() => notifyListeners()); // Gunakan microtask untuk notifyListeners
        return;
      }
      
      // Memastikan domain URL adalah yang diharapkan (Midtrans)
      if (!redirectUrl.contains('midtrans') && !redirectUrl.contains('gopay')) {
        print('WARNING: URL pembayaran bukan dari Midtrans: $redirectUrl');
      }
      
      // Buka WebView untuk pembayaran Midtrans
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MidtransWebView(
            url: redirectUrl,
            onUrlChanged: (String url) {
              print('URL saat ini: $url');
              
              // Deteksi URL yang menandakan pembayaran berhasil
              _checkSuccessIndicators(url);
            },
            onWebViewClosed: () {
              print('WebView ditutup');
              // Gunakan Future.microtask untuk mencegah notifyListeners saat widget tree terkunci
              Future.microtask(() {
                // Cek status pembayaran secara manual ketika WebView ditutup
                if (_bookingId != null) {
                  checkPaymentStatus(_bookingId!);
                }
              });
            },
          ),
        ),
      );
      
      print('Hasil dari WebView: $result');
      
      // WebView ditutup, gunakan microtask untuk notifyListeners
      Future.microtask(() => notifyListeners());
    } catch (e) {
      print('ERROR: Gagal membuka WebView: $e');
      // Set error dan notify listeners menggunakan microtask
      _errorMessage = 'Gagal membuka halaman pembayaran: $e';
      Future.microtask(() => notifyListeners());
    }
  }
  
  // Fungsi untuk mendeteksi indikator sukses dari URL
  void _checkSuccessIndicators(String url) {
    // Gunakan Future.microtask untuk memastikan notifyListeners dipanggil di frame berikutnya
    // sehingga tidak terjadi saat widget tree terkunci
    Future.microtask(() {
      // Deteksi URL yang menandakan pembayaran berhasil
      if (url.contains('transaction_status=settlement') || 
          url.contains('transaction_status=capture') || 
          url.contains('transaction_status=paid')) {
        print('Terdeteksi indikator sukses: ${url.split('transaction_status=')[1].split('&')[0]}');
        // Set status sebagai settlement sementara sampai diverifikasi oleh API
        _paymentStatus = 'settlement';
        notifyListeners();
      } else if (url.contains('transaction_status=pending')) {
        print('Terdeteksi status pending');
        _paymentStatus = 'pending';
        notifyListeners();
      } else if (url.contains('transaction_status=deny') || 
                url.contains('transaction_status=cancel') || 
                url.contains('transaction_status=expire')) {
        print('Terdeteksi status gagal: ${url.split('transaction_status=')[1].split('&')[0]}');
        _paymentStatus = url.split('transaction_status=')[1].split('&')[0];
        notifyListeners();
      }
    });
  }
  
  // Fungsi untuk memeriksa status pembayaran secara manual
  Future<Map<String, dynamic>> checkPaymentStatusManual(int bookingId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      print('Memeriksa status pembayaran secara manual untuk booking ID: $bookingId');
      final result = await MidtransService.checkPaymentStatusManual(bookingId);
      
      if (result['success'] == true && result['data'] != null) {
        _paymentData = result['data'];
        _paymentStatus = result['data']['payment_status'] ?? 'unpaid';
        
        // Log informasi pembayaran yang lebih lengkap
        print('Status pembayaran diterima: $_paymentStatus');
        print('Data pembayaran: $_paymentData');
        
        // Periksa apakah sudah dibayar
        if (_paymentStatus == 'settlement' || _paymentStatus == 'capture' || _paymentStatus == 'paid') {
          print('Pembayaran terdeteksi berhasil');
        } else {
          print('Pembayaran belum selesai, status: $_paymentStatus');
        }
        
        _errorMessage = '';
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengecek status pembayaran';
        print('Gagal mengecek status pembayaran: $_errorMessage');
      }
      
      _isLoading = false;
      notifyListeners();
      
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan: $e';
      print('Error saat mengecek status pembayaran: $e');
      notifyListeners();
      
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Reset state
  void reset() {
    _isLoading = false;
    _isPaymentInitiated = false;
    _errorMessage = '';
    _paymentData = {};
    _redirectUrl = '';
    _snapToken = '';
    _paymentStatus = 'unpaid';
    _bookingId = null;
    notifyListeners();
  }
}
