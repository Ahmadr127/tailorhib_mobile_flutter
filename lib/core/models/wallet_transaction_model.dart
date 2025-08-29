import 'package:flutter/material.dart';

class WalletTransaction {
  final int id;
  final int walletId;
  final int? bookingId;
  final String type;
  final String amount;
  final String description;
  final String status;
  final String createdAt;
  final String updatedAt;
  final BookingTransaction? booking;

  WalletTransaction({
    required this.id,
    required this.walletId,
    this.bookingId,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.booking,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      walletId: json['wallet_id'],
      bookingId: json['booking_id'],
      type: json['type'],
      amount: json['amount'],
      description: json['description'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      booking: json['booking'] != null
          ? BookingTransaction.fromJson(json['booking'])
          : null,
    );
  }

  // Helper method untuk mendapatkan amount dalam format double
  double getAmountAsDouble() {
    try {
      return double.parse(amount);
    } catch (e) {
      return 0.0;
    }
  }

  // Helper method untuk mendapatkan tipe transaksi dalam bahasa Indonesia
  String getTypeText() {
    switch (type.toLowerCase()) {
      case 'credit':
        return 'Masuk';
      case 'debit':
        return 'Keluar';
      default:
        return 'Tidak Diketahui';
    }
  }

  // Helper method untuk mendapatkan warna berdasarkan tipe transaksi
  Color getTypeColor() {
    switch (type.toLowerCase()) {
      case 'credit':
        return const Color(0xFF34A853); // Hijau
      case 'debit':
        return const Color(0xFFEA4335); // Merah
      default:
        return const Color(0xFF9AA0A6); // Abu-abu
    }
  }

  // Helper method untuk mendapatkan icon berdasarkan tipe transaksi
  IconData getTypeIcon() {
    switch (type.toLowerCase()) {
      case 'credit':
        return Icons.arrow_downward;
      case 'debit':
        return Icons.arrow_upward;
      default:
        return Icons.swap_horiz;
    }
  }
}

class BookingTransaction {
  final int id;
  final String transactionCode;
  final int customerId;
  final int tailorId;
  final String appointmentDate;
  final String appointmentTime;
  final String serviceType;
  final String category;
  final String? designPhoto;
  final String? notes;
  final String status;
  final String totalPrice;
  final String paymentStatus;
  final Map<String, dynamic>? measurements;
  final String? repairDetails;
  final String? repairPhoto;
  final String? repairNotes;
  final String? completionPhoto;
  final String? completionNotes;
  final String? acceptedAt;
  final String? rejectedAt;
  final String? completedAt;
  final String? pickupDate;
  final String? rejectionReason;
  final String paymentMethod;
  final String? midtransSnapToken;
  final String createdAt;
  final String updatedAt;

  BookingTransaction({
    required this.id,
    required this.transactionCode,
    required this.customerId,
    required this.tailorId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.serviceType,
    required this.category,
    this.designPhoto,
    this.notes,
    required this.status,
    required this.totalPrice,
    required this.paymentStatus,
    this.measurements,
    this.repairDetails,
    this.repairPhoto,
    this.repairNotes,
    this.completionPhoto,
    this.completionNotes,
    this.acceptedAt,
    this.rejectedAt,
    this.completedAt,
    this.pickupDate,
    this.rejectionReason,
    required this.paymentMethod,
    this.midtransSnapToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingTransaction.fromJson(Map<String, dynamic> json) {
    return BookingTransaction(
      id: json['id'],
      transactionCode: json['transaction_code'],
      customerId: json['customer_id'],
      tailorId: json['tailor_id'],
      appointmentDate: json['appointment_date'],
      appointmentTime: json['appointment_time'],
      serviceType: json['service_type'],
      category: json['category'],
      designPhoto: json['design_photo'],
      notes: json['notes'],
      status: json['status'],
      totalPrice: json['total_price'],
      paymentStatus: json['payment_status'],
      measurements: json['measurements'] != null
          ? Map<String, dynamic>.from(json['measurements'])
          : null,
      repairDetails: json['repair_details'],
      repairPhoto: json['repair_photo'],
      repairNotes: json['repair_notes'],
      completionPhoto: json['completion_photo'],
      completionNotes: json['completion_notes'],
      acceptedAt: json['accepted_at'],
      rejectedAt: json['rejected_at'],
      completedAt: json['completed_at'],
      pickupDate: json['pickup_date'],
      rejectionReason: json['rejection_reason'],
      paymentMethod: json['payment_method'],
      midtransSnapToken: json['midtrans_snap_token'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
