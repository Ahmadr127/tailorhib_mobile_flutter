import '../services/api_service.dart';

class BookingModel {
  final int id;
  final String? transactionCode;
  final int? customerId;
  final int? tailorId;
  final String appointmentDate;
  final String appointmentTime;
  final String serviceType;
  final String category;
  final String? designPhoto;
  final String? image;
  final String? notes;
  final String status;
  final String? totalPrice;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? measurements;
  final String? repairDetails;
  final String? repairPhoto;
  final String? repairNotes;
  final String? completionPhoto;
  final String? completionNotes;
  final String? completionDate;
  final String? acceptedAt;
  final String? rejectedAt;
  final String? completedAt;
  final String? pickupDate;
  final String? rejectionReason;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? tailor;
  final dynamic rating;
  final String? review;
  final String? ratingDate;
  final String? tailorName;
  final String? tailorImage;
  final String? customerName;
  final String? customerImage;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerAddress;
  final String? tailorPhone;
  final String? tailorEmail;
  final String? tailorAddress;
  final String? price;

  String get statusDetail => getStatusText();

  BookingModel({
    required this.id,
    this.transactionCode,
    this.customerId,
    this.tailorId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.serviceType,
    required this.category,
    this.designPhoto,
    this.image,
    this.notes,
    required this.status,
    this.totalPrice,
    this.paymentMethod,
    this.paymentStatus,
    this.measurements,
    this.repairDetails,
    this.repairPhoto,
    this.repairNotes,
    this.completionPhoto,
    this.completionNotes,
    this.completionDate,
    this.acceptedAt,
    this.rejectedAt,
    this.completedAt,
    this.pickupDate,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.tailor,
    this.rating,
    this.review,
    this.ratingDate,
    this.tailorName,
    this.tailorImage,
    this.customerName,
    this.customerImage,
    this.customerPhone,
    this.customerEmail,
    this.customerAddress,
    this.tailorPhone,
    this.tailorEmail,
    this.tailorAddress,
    this.price,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    try {
      // Jika ada measurements, konversi ke string
      String? measurementsStr;
      if (json['measurements'] != null) {
        if (json['measurements'] is String) {
          measurementsStr = json['measurements'];
        } else {
          measurementsStr = json['measurements'].toString();
        }
      }

      // Jika ada repair_details, konversi ke string
      String? repairDetailsStr;
      if (json['repair_details'] != null) {
        if (json['repair_details'] is String) {
          repairDetailsStr = json['repair_details'];
        } else {
          repairDetailsStr = json['repair_details'].toString();
        }
      }

      // Jika ada tailor, konversi ke Map
      Map<String, dynamic>? tailorData;
      if (json['tailor'] != null) {
        if (json['tailor'] is Map) {
          tailorData = Map<String, dynamic>.from(json['tailor']);
        }
      }

      return BookingModel(
        id: json['id'] ?? 0,
        transactionCode: json['transaction_code'],
        customerId: json['customer_id'],
        tailorId: json['tailor_id'],
        appointmentDate: json['appointment_date'] ?? '',
        appointmentTime: json['appointment_time'] ?? '',
        serviceType: json['service_type'] ?? 'Jahit Baru',
        category: json['category'] ?? 'Atasan',
        designPhoto: json['design_photo'],
        image: json['image'],
        notes: json['notes'] ?? '',
        status: json['status'] ?? 'reservasi',
        totalPrice: json['total_price']?.toString(),
        paymentMethod: json['payment_method'],
        paymentStatus: json['payment_status'],
        measurements: measurementsStr,
        repairDetails: repairDetailsStr,
        repairPhoto: json['repair_photo'],
        repairNotes: json['repair_notes'],
        completionPhoto: json['completion_photo'],
        completionNotes: json['completion_notes'],
        completionDate: json['completion_date'],
        acceptedAt: json['accepted_at'],
        rejectedAt: json['rejected_at'],
        completedAt: json['completed_at'],
        pickupDate: json['pickup_date'],
        rejectionReason: json['rejection_reason'],
        createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
        updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
        customer: json['customer'],
        tailor: tailorData,
        rating: json['rating'],
        review: json['review'],
        ratingDate: json['rating_date'],
        tailorName: json['tailor_name'] ?? json['tailor']?['name'],
        tailorImage: json['tailor_image'] ?? json['tailor']?['image'],
        customerName: json['customer_name'] ?? json['customer']?['name'],
        customerImage: json['customer_image'] ?? json['customer']?['image'],
        customerPhone: json['customer_phone'],
        customerEmail: json['customer_email'],
        customerAddress: json['customer_address'],
        tailorPhone: json['tailor_phone'],
        tailorEmail: json['tailor_email'],
        tailorAddress: json['tailor_address'],
        price: json['price']?.toString(),
      );
    } catch (e, stackTrace) {
      print('ERROR: Failed to parse booking JSON: $e');
      print('ERROR: Stack trace: $stackTrace');
      print('ERROR: JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_code': transactionCode,
      'customer_id': customerId,
      'tailor_id': tailorId,
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
      'service_type': serviceType,
      'category': category,
      'status': status,
      'statusDetail': statusDetail,
      'totalPrice': totalPrice,
      'paymentStatus': paymentStatus,
      'rating': rating,
      'review': review,
      'designPhoto': designPhoto,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'payment_method': paymentMethod,
      'price': price,
    };
  }

  String getStatusText() {
    switch (status.toLowerCase()) {
      case 'reservasi':
        return 'Menunggu konfirmasi dari penjahit';
      case 'diproses':
        return 'Sedang dikerjakan oleh penjahit';
      case 'selesai':
        return 'Pesanan telah selesai';
      case 'dibatalkan':
        return 'Pesanan dibatalkan: ${rejectionReason ?? "Tidak ada alasan"}';
      default:
        return 'Status tidak diketahui';
    }
  }

  // Mendapatkan nama pelanggan
  String getCustomerName() {
    return customerName ?? customer?['name'] ?? 'Pelanggan';
  }

  // Mendapatkan nama penjahit
  String getTailorName() {
    return tailorName ?? tailor?['name'] ?? 'Penjahit';
  }

  // Mendapatkan foto profil penjahit
  String? getTailorPhoto() {
    // Debug informasi
    print('DEBUG: Getting tailor photo');
    print('DEBUG: Tailor object: $tailor');

    // Cek dari objek tailor
    if (tailor != null &&
        tailor!.containsKey('profile_photo') &&
        tailor!['profile_photo'] != null &&
        tailor!['profile_photo'].toString().isNotEmpty) {
      String photo = tailor!['profile_photo'].toString();
      print('DEBUG: Found profile_photo in tailor object: $photo');
      return photo;
    }

    // Cek field tailor_photo dari objek tailor (alternativ nama)
    if (tailor != null && tailor!.containsKey('tailor_photo')) {
      String? photo = tailor!['tailor_photo']?.toString();
      if (photo != null && photo.isNotEmpty) {
        print('DEBUG: Found tailor_photo in booking: $photo');
        return photo;
      }
    }

    print('DEBUG: No tailor photo found');
    return null;
  }

  // Mendapatkan foto profil pelanggan atau penjahit (tergantung konteks)
  String? getProfilePhoto() {
    // Dalam konteks customer app, kita prioritaskan foto penjahit
    String? photo = getTailorPhoto();
    if (photo != null) {
      print('DEBUG: Using tailor photo as profile photo: $photo');
      return photo;
    }

    // Fallback ke foto customer jika tidak ada foto penjahit
    photo = getCustomerPhoto();
    if (photo != null) {
      print('DEBUG: Using customer photo as profile photo: $photo');
      return photo;
    }

    print('DEBUG: No profile photo found');
    return null;
  }

  // Mendapatkan foto profil pelanggan
  String? getCustomerPhoto() {
    // Debug informasi
    print('DEBUG: Customer object in BookingModel: $customer');

    // Cek foto di objek customer
    if (customer != null &&
        customer!.containsKey('profile_photo') &&
        customer!['profile_photo'] != null &&
        customer!['profile_photo'].toString().isNotEmpty) {
      print(
          'DEBUG: Found profile_photo in customer object: ${customer!['profile_photo']}');
      return customer!['profile_photo'];
    }

    // Periksa jika ada objek tailor dalam booking
    if (customer != null &&
        customer!.containsKey('tailor') &&
        customer!['tailor'] != null &&
        customer!['tailor'] is Map<String, dynamic>) {
      final tailor = customer!['tailor'] as Map<String, dynamic>;
      if (tailor.containsKey('profile_photo') &&
          tailor['profile_photo'] != null &&
          tailor['profile_photo'].toString().isNotEmpty) {
        print(
            'DEBUG: Found profile_photo in tailor object: ${tailor['profile_photo']}');
        return tailor['profile_photo'];
      }
    }

    print('DEBUG: No profile photo found in booking data');
    return null;
  }

  // Mendapatkan warna untuk status
  String getStatusColor() {
    switch (status.toLowerCase()) {
      case 'reservasi':
        return '#FFA726'; // Orange
      case 'accepted':
        return '#4CAF50'; // Green
      case 'rejected':
        return '#F44336'; // Red
      case 'in_progress':
        return '#2196F3'; // Blue
      case 'completed':
        return '#8BC34A'; // Light Green
      case 'delivered':
        return '#9C27B0'; // Purple
      default:
        return '#757575'; // Grey
    }
  }

  // Format tanggal dengan format yang lebih user-friendly
  String getFormattedDate() {
    try {
      print(
          'DEBUG: Getting formatted date for appointmentDate: $appointmentDate');

      if (appointmentDate.isEmpty) {
        print('DEBUG: appointmentDate is empty');
        return 'Belum ditentukan';
      }

      // Jika sudah dalam format yang benar (contoh: "26 April 2024")
      if (appointmentDate.contains(' ') &&
          !appointmentDate.contains('-') &&
          !appointmentDate.contains('T')) {
        print('DEBUG: Date is already in correct format: $appointmentDate');
        return appointmentDate;
      }

      DateTime date;
      try {
        // Coba parse format ISO dengan timezone (2024-04-26T00:00:00.000000Z)
        if (appointmentDate.contains('T')) {
          date = DateTime.parse(appointmentDate);
          print('DEBUG: Successfully parsed ISO date with timezone: $date');
        }
        // Coba parse format tanggal sederhana (2024-04-26)
        else if (appointmentDate.contains('-')) {
          final parts = appointmentDate.split('-');
          if (parts.length == 3) {
            date = DateTime(
                int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            print('DEBUG: Successfully parsed simple date: $date');
          } else {
            print('ERROR: Invalid date parts length: ${parts.length}');
            return 'Belum ditentukan';
          }
        }
        // Format tidak dikenal
        else {
          print('ERROR: Unknown date format: $appointmentDate');
          return 'Belum ditentukan';
        }

        // Format ke bahasa Indonesia
        List<String> months = [
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember'
        ];

        String formattedDate =
            '${date.day} ${months[date.month - 1]} ${date.year}';
        print('DEBUG: Successfully formatted date: $formattedDate');
        return formattedDate;
      } catch (parseError) {
        print(
            'ERROR: Failed to parse date: $parseError for date: $appointmentDate');
        return 'Belum ditentukan';
      }
    } catch (e, stackTrace) {
      print('ERROR: Exception in getFormattedDate: $e');
      print('ERROR: Stack trace: $stackTrace');
      print('ERROR: Original appointmentDate: $appointmentDate');
      return 'Belum ditentukan';
    }
  }

  // Format waktu dengan format yang lebih user-friendly
  String getFormattedTime() {
    try {
      print(
          'DEBUG: Getting formatted time for appointmentTime: $appointmentTime');

      if (appointmentTime.isEmpty) {
        print('DEBUG: appointmentTime is empty');
        return '-';
      }

      // Cek jika format sudah H:i
      if (appointmentTime.contains(':')) {
        final parts = appointmentTime.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          // Ambil menit saja tanpa detik jika ada
          String minutePart = parts[1];
          if (minutePart.contains(' ')) {
            minutePart = minutePart.split(' ')[0];
          }
          final minute = int.parse(minutePart);

          // Format 24 jam
          String formattedTime =
              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} WIB';
          print('DEBUG: Successfully formatted time: $formattedTime');
          return formattedTime;
        }
      }

      // Default fallback
      print('DEBUG: Using default time format: $appointmentTime WIB');
      return '$appointmentTime WIB';
    } catch (e) {
      print('ERROR: Failed to format time: $e for time: $appointmentTime');
      return appointmentTime;
    }
  }

  // Mendapatkan data lengkap untuk detail order
  Map<String, dynamic> getOrderDetails() {
    return {
      'id': id,
      'customer_id': customerId,
      'tailor_id': tailorId,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'serviceType': serviceType,
      'category': category,
      'designPhoto': designPhoto,
      'image': image,
      'notes': notes,
      'status': status,
      'statusDetail': statusDetail,
      'total_price': totalPrice,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'transaction_code': transactionCode,
      'measurements': measurements,
      'repair_details': repairDetails,
      'repair_photo': repairPhoto,
      'repair_notes': repairNotes,
      'completion_photo': completionPhoto,
      'completion_notes': completionNotes,
      'completion_date': completionDate,
      'accepted_at': acceptedAt,
      'rejected_at': rejectedAt,
      'completed_at': completedAt,
      'pickup_date': pickupDate,
      'rejection_reason': rejectionReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'customer': customer,
      'tailor': tailor,
      'rating': rating,
      'review': review,
      'rating_date': ratingDate,
      'tailorName': getTailorName(),
      'tailorImage': getTailorPhoto(),
      'customerName': getCustomerName(),
      'customerImage': getProfilePhoto(),
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'customerAddress': customerAddress,
      'tailorPhone': tailorPhone,
      'tailorEmail': tailorEmail,
      'tailorAddress': tailorAddress,
      'price': price,
    };
  }

  // Helper untuk format tanggal untuk tampilan
  String _formatDateForDisplay(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    } catch (e) {
      print('ERROR: Gagal memformat tanggal: $dateString, error: $e');
      return dateString;
    }
  }

  // Mendapatkan URL lengkap untuk foto desain
  Future<String?> getFullDesignPhotoUrl() async {
    if (designPhoto == null || designPhoto!.isEmpty) {
      print('DEBUG BOOKING: Design photo is null or empty');
      return null;
    }

    try {
      // Gunakan fungsi khusus untuk memperbaiki URL foto desain
      final fixedUrl = await ApiService.fixDesignPhotoUrl(designPhoto!);
      print('DEBUG BOOKING: Fixed design photo URL: $fixedUrl');
      return fixedUrl;
    } catch (e) {
      print('ERROR BOOKING: Failed to fix design photo URL: $e');
      return designPhoto;
    }
  }
}
