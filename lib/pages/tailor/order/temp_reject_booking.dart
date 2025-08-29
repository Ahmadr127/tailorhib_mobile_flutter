import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/booking_model.dart';

// Copy metode ini ke OrderDetailPage.dart untuk menggantikan metode _rejectBooking yang ada
Future<void> improvedRejectBooking(BuildContext context, BookingModel? booking,
    String reason, Function(bool) setState, bool mounted) async {
  if (!mounted || booking == null) return;

  if (reason.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alasan penolakan harus diisi'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Validasi status booking
  final status = booking.status.toLowerCase();
  if (status != 'reservasi') {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tidak Dapat Menolak Pesanan'),
          content: Text(
              'Pesanan dengan status "${booking.getStatusText()}" tidak dapat ditolak. Hanya pesanan dengan status "Menunggu Konfirmasi" yang dapat ditolak.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    );
    return;
  }

  setState(true); // Set _isProcessing = true

  try {
    final result = await ApiService.rejectBooking(booking.id, reason);

    if (!mounted) return;

    setState(false); // Set _isProcessing = false

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      // Kembali ke halaman sebelumnya
      Navigator.pop(context, true);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Gagal Menolak Pesanan'),
            content: Text(result['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      );
    }
  } catch (e) {
    if (!mounted) return;

    setState(false); // Set _isProcessing = false

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Terjadi kesalahan: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Implementasi di OrderDetailPage.dart:
/*
Future<void> _rejectBooking(String reason) async {
  setState(() {
    _isProcessing = true;
  });
  
  await improvedRejectBooking(
    context, 
    _booking, 
    reason,
    (bool isProcessing) => setState(() { _isProcessing = isProcessing; }),
    mounted
  );
}
*/ 