import 'package:flutter/material.dart';
import 'wallet_transaction_model.dart';

class WalletModel {
  final String balance;
  final String pendingWithdrawals;
  final String availableBalance;
  final List<WalletTransaction> transactions;

  WalletModel({
    required this.balance,
    required this.pendingWithdrawals,
    required this.availableBalance,
    required this.transactions,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: json['balance']?.toString() ?? '0',
      pendingWithdrawals: json['pending_withdrawals']?.toString() ?? '0',
      availableBalance: json['available_balance']?.toString() ?? '0',
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((transaction) => WalletTransaction.fromJson(transaction))
              .toList() ??
          [],
    );
  }

  // Helper method untuk mendapatkan balance dalam format double
  double getBalanceAsDouble() {
    try {
      return double.parse(balance);
    } catch (e) {
      return 0.0;
    }
  }
  
  // Helper method untuk mendapatkan pending withdrawals dalam format double
  double getPendingWithdrawalsAsDouble() {
    try {
      return double.parse(pendingWithdrawals);
    } catch (e) {
      return 0.0;
    }
  }
  
  // Helper method untuk mendapatkan available balance dalam format double
  double getAvailableBalanceAsDouble() {
    try {
      return double.parse(availableBalance);
    } catch (e) {
      return 0.0;
    }
  }
}

class BankAccount {
  final int id;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final String status;
  final String? verifiedAt;
  final String? rejectionReason;
  final String createdAt;
  final String updatedAt;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    required this.status,
    this.verifiedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'],
      bankName: json['bank_name'],
      accountNumber: json['account_number'],
      accountHolderName: json['account_holder_name'],
      status: json['status'],
      verifiedAt: json['verified_at'],
      rejectionReason: json['rejection_reason'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  // Helper method untuk mendapatkan status dalam bahasa Indonesia
  String getStatusText() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'active':
        return 'Aktif';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  // Helper method untuk mendapatkan warna status
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA000); // Orange
      case 'active':
        return const Color(0xFF34A853); // Hijau
      case 'rejected':
        return const Color(0xFFEA4335); // Merah
      default:
        return const Color(0xFF9AA0A6); // Abu-abu
    }
  }
}
