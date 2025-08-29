import 'package:flutter/material.dart';
import 'dart:io';
import '../services/booking_service.dart';
import '../models/booking_model.dart';

class BookingController extends ChangeNotifier {
  List<BookingModel> _bookings = [];
  List<BookingModel> _filteredBookings = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  String _currentFilter = 'Semua';

  List<BookingModel> get bookings => _filteredBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_currentFilter.toLowerCase() == 'semua') {
      _filteredBookings = List.from(_bookings);
      return;
    }

    _filteredBookings = _bookings.where((booking) {
      String status = booking.status.toLowerCase();
      String filter = _currentFilter.toLowerCase();

      switch (filter) {
        case 'reservasi':
          return status == 'reservasi';
        case 'diproses':
          return status == 'diproses';
        case 'selesai':
          return status == 'selesai';
        case 'dibatalkan':
          return status == 'dibatalkan';
        default:
          return true;
      }
    }).toList();
  }

  Future<void> loadBookings([String? status]) async {
    if (_disposed) return;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('DEBUG: Loading all bookings from BookingService');

      // Gunakan metode yang dipindahkan ke BookingService
      final result = await BookingService.getCustomerBookings();

      if (result['success']) {
        _bookings = [];
        if (result['data'] != null && result['data'] is List) {
          for (var item in result['data']) {
            try {
              _bookings.add(BookingModel.fromJson(item));
            } catch (e) {
              print('ERROR: Gagal parsing booking: $e');
              print('ERROR: JSON data: $item');
            }
          }
        }

        // Terapkan filter
        if (status != null && status.isNotEmpty) {
          setFilter(status);
        } else {
          _applyFilter();
        }

        _isLoading = false;
        _errorMessage = null;
      } else {
        _bookings = [];
        _filteredBookings = [];
        _errorMessage = result['message'] ?? 'Gagal memuat data booking';
        _isLoading = false;
      }

      notifyListeners();
    } catch (e, stackTrace) {
      print('ERROR: Gagal memuat bookings: $e');
      print('Stack trace: $stackTrace');
      _bookings = [];
      _filteredBookings = [];
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearBookings() {
    _bookings = [];
    _filteredBookings = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> createBooking({
    required int tailorId,
    required String appointmentDate,
    required String appointmentTime,
    required String serviceType,
    required String category,
    String notes = '',
    String paymentMethod = 'transfer_bank',
    File? image,
  }) async {
    try {
      print('DEBUG: Membuat booking baru via controller');
      
      // Kirim data booking ke API melalui BookingService
      final result = await BookingService.createBooking(
        tailorId: tailorId,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        serviceType: serviceType,
        category: category,
        notes: notes,
        paymentMethod: paymentMethod,
        image: image,
      );

      // Jika booking berhasil dibuat, muat ulang daftar booking
      if (result['success'] && !_disposed) {
        await loadBookings('reservasi');
      }

      return result;
    } catch (e, stackTrace) {
      print('ERROR: Gagal membuat booking: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> rateBooking(
      int bookingId, int rating, String review) async {
    try {
      print(
          'DEBUG: Attempting to rate booking #$bookingId with rating $rating');
      final result =
          await BookingService.rateBooking(bookingId, rating, review);

      if (result['success'] && !_disposed) {
        await loadBookings();
      }

      return result;
    } catch (e) {
      print('ERROR: Gagal memberikan rating: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> completeBooking(
    int bookingId,
    String completionNotes,
    String? completionPhoto,
    String? pickupDate,
  ) async {
    try {
      print('DEBUG: Menyelesaikan booking #$bookingId melalui controller');
      final result = await BookingService.completeBooking(
        bookingId,
        completionNotes,
        completionPhoto,
        pickupDate,
      );

      if (result['success'] && !_disposed) {
        // Jika berhasil, muat ulang booking dengan filter 'diproses'
        await loadBookings('diproses');
      }

      return result;
    } catch (e) {
      print('ERROR: Gagal menyelesaikan pesanan: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
