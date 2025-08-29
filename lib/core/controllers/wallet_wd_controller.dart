import 'package:flutter/material.dart';
import '../services/wallet_wd_service.dart';
import '../models/wallet_model.dart';
import 'dart:developer' as developer;

class WalletWDController extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  WalletModel? _walletInfo;
  List<BankAccount> _bankAccounts = [];
  List<Map<String, dynamic>> _withdrawalHistory = [];
  bool _isDisposed = false;
  
  // Debug info - tambahan untuk keperluan debugging
  final Map<String, dynamic> _lastApiResponse = {};
  final bool _debugMode = true;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  WalletModel? get walletInfo => _walletInfo;
  List<BankAccount> get bankAccounts => _bankAccounts;
  List<Map<String, dynamic>> get withdrawalHistory => _withdrawalHistory;
  Map<String, dynamic> get lastApiResponse => _lastApiResponse; // Getter untuk debug info

  // Helper method untuk safe notification
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      Future.microtask(() {
        if (!_isDisposed) {
          notifyListeners();
        }
      });
    }
  }

  // Helper method untuk set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    _safeNotifyListeners();
  }

  // Helper method untuk set error message
  void _setError(String message) {
    _errorMessage = message;
    _safeNotifyListeners();
  }

  // Helper method untuk debugging
  void _logDebug(String message) {
    if (_debugMode) {
      developer.log('[WALLET_CONTROLLER] $message', name: 'TailorHub');
      print('[WALLET_CONTROLLER] $message');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> fetchWalletInfo() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _setError('');

    try {
      _logDebug('Memanggil WalletWDService.getWalletInfo()');
      final result = await WalletWDService.getWalletInfo();
      
      // Simpan respons untuk debugging
      _lastApiResponse['getWalletInfo'] = result;
      _logDebug('Hasil getWalletInfo: ${result['success']}');
      
      if (result['success']) {
        _walletInfo = WalletModel.fromJson(result['data']);
        _logDebug('WalletInfo berhasil dimuat. Balance: ${_walletInfo?.balance}');
      } else {
        _setError(result['message']);
        _logDebug('Error getWalletInfo: ${result['message']}');
      }
    } catch (e) {
      _logDebug('Exception getWalletInfo: $e');
      _setError('Terjadi kesalahan: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchBankAccounts() async {
    if (_isLoading) return;

    _setLoading(true);
    _setError('');

    try {
      _logDebug('Memanggil WalletWDService.getBankAccounts()');
      final result = await WalletWDService.getBankAccounts();
      
      // Simpan respons untuk debugging
      _lastApiResponse['getBankAccounts'] = result;
      _logDebug('Hasil getBankAccounts: ${result['success']}');
      
      if (result['success']) {
        _bankAccounts = (result['data'] as List)
            .map((json) => BankAccount.fromJson(json))
            .toList();
        _logDebug('BankAccounts berhasil dimuat. Jumlah: ${_bankAccounts.length}');
      } else {
        _setError(result['message']);
        _logDebug('Error getBankAccounts: ${result['message']}');
      }
    } catch (e) {
      _logDebug('Exception getBankAccounts: $e');
      _setError('Terjadi kesalahan: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> registerBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    if (_isLoading) {
      return {'success': false, 'message': 'Proses sedang berlangsung'};
    }

    _setLoading(true);
    _setError('');

    try {
      _logDebug('Memanggil WalletWDService.registerBankAccount()');
      final result = await WalletWDService.registerBankAccount(
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
      );

      // Simpan respons untuk debugging
      _lastApiResponse['registerBankAccount'] = result;
      _logDebug('Hasil registerBankAccount: ${result['success']}');

      if (result['success']) {
        await fetchBankAccounts();
        _logDebug('registerBankAccount berhasil: ${result['message']}');
      } else {
        _setError(result['message']);
        _logDebug('Error registerBankAccount: ${result['message']}');
      }
      return result;
    } catch (e) {
      _logDebug('Exception registerBankAccount: $e');
      _setError('Terjadi kesalahan: $e');
      return {
        'success': false,
        'message': _errorMessage,
      };
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required int bankAccountId,
    required double amount,
  }) async {
    if (_isLoading) {
      return {'success': false, 'message': 'Proses sedang berlangsung'};
    }

    _setLoading(true);
    _setError('');

    try {
      _logDebug('Memanggil WalletWDService.requestWithdrawal()');
      final result = await WalletWDService.requestWithdrawal(
        bankAccountId: bankAccountId,
        amount: amount,
      );

      // Simpan respons untuk debugging
      _lastApiResponse['requestWithdrawal'] = result;
      _logDebug('Hasil requestWithdrawal: ${result['success']}');

      if (result['success']) {
        // Update wallet info dari respons API jika tersedia
        if (result['data'] != null && result['data']['wallet'] != null) {
          _logDebug('Update wallet info dari respons API: ${result['data']['wallet']}');
          updateWalletInfoFromApiResponse(result['data']['wallet']);
          
          // Tambahkan entry penarikan baru ke riwayat penarikan
          if (result['data']['withdrawal'] != null) {
            _withdrawalHistory.insert(0, result['data']['withdrawal']);
            _logDebug('Added new withdrawal to history: ${result['data']['withdrawal']}');
          }
        } else {
          // Jika data wallet tidak tersedia dalam respons, ambil dari API
          await Future.wait([
            fetchWalletInfo(),
            fetchWithdrawalHistory(),
          ]);
        }
        
        _logDebug('requestWithdrawal berhasil: ${result['message']}');
      } else {
        // Jika gagal namun ada info wallet baru, update juga
        if (result['wallet_info'] != null) {
          updateWalletInfoFromApiResponse(result['wallet_info']);
        }
        
        _setError(result['message']);
        _logDebug('Error requestWithdrawal: ${result['message']}');
      }
      return result;
    } catch (e) {
      _logDebug('Exception requestWithdrawal: $e');
      _setError('Terjadi kesalahan: $e');
      return {
        'success': false,
        'message': _errorMessage,
      };
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchWithdrawalHistory({String? status}) async {
    if (_isLoading) return;

    _setLoading(true);
    _setError('');

    try {
      _logDebug('Memanggil WalletWDService.getWithdrawalHistory(status: $status)');
      final result = await WalletWDService.getWithdrawalHistory(status: status);
      
      // Simpan respons untuk debugging
      _lastApiResponse['getWithdrawalHistory'] = result;
      _logDebug('Hasil getWithdrawalHistory: ${result['success']}');
      
      if (result['success']) {
        _withdrawalHistory = List<Map<String, dynamic>>.from(result['data']);
        _logDebug('WithdrawalHistory berhasil dimuat. Jumlah: ${_withdrawalHistory.length}');
        
        // Log detail data untuk debugging
        if (_debugMode) {
          _logDebug('Detail data withdrawal:');
          _logDebug('Raw response: ${result['data']}');
          
          if (_withdrawalHistory.isEmpty) {
            _logDebug('Data withdrawal kosong!');
          } else {
            for (int i = 0; i < _withdrawalHistory.length; i++) {
              _logDebug('Withdrawal #${i+1}: ${_withdrawalHistory[i]}');
            }
          }
        }
      } else {
        _setError(result['message']);
        _logDebug('Error getWithdrawalHistory: ${result['message']}');
      }
    } catch (e, stackTrace) {
      _logDebug('Exception getWithdrawalHistory: $e');
      _logDebug('StackTrace: $stackTrace');
      _setError('Terjadi kesalahan: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper method untuk mendapatkan status text penarikan
  String getWithdrawalStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Proses';
      case 'processing':
        return 'Sedang Diproses';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  // Helper method untuk mendapatkan warna status penarikan
  Color getWithdrawalStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA000); // Orange
      case 'processing':
        return const Color(0xFF1976D2); // Biru
      case 'completed':
        return const Color(0xFF34A853); // Hijau
      case 'rejected':
        return const Color(0xFFEA4335); // Merah
      default:
        return const Color(0xFF9AA0A6); // Abu-abu
    }
  }

  // Reset state
  void reset() {
    _setLoading(false);
    _setError('');
    _walletInfo = null;
    _bankAccounts = [];
    _withdrawalHistory = [];
    _safeNotifyListeners();
  }
  
  // Method untuk pengujian - cek koneksi
  Future<bool> testConnection() async {
    try {
      _logDebug('Testing connection to wallet API');
      final result = await WalletWDService.getWalletInfo();
      _lastApiResponse['testConnection'] = result;
      _logDebug('Test koneksi: ${result['success']}');
      return result['success'];
    } catch (e) {
      _logDebug('Test koneksi gagal: $e');
      return false;
    }
  }
  
  // Metode untuk mengupdate wallet info dari respons API
  void updateWalletInfoFromApiResponse(Map<String, dynamic> walletData) {
    try {
      _logDebug('Updating wallet info from API response: $walletData');
      
      // Perbarui wallet info dari data API
      _walletInfo = WalletModel.fromJson(walletData);
      _logDebug('Wallet info updated: balance=${_walletInfo?.balance}, pending=${_walletInfo?.pendingWithdrawals}, available=${_walletInfo?.availableBalance}');
      _safeNotifyListeners();
        } catch (e) {
      _logDebug('Error updating wallet info: $e');
    }
  }
}
