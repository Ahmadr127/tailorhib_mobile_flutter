import '../services/api_service.dart';
import 'review_model.dart';

class SpecializationModel {
  final int id;
  final String name;
  final String category;
  final String? icon;
  final String? photo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SpecializationModel({
    required this.id,
    required this.name,
    required this.category,
    this.icon,
    this.photo,
    this.createdAt,
    this.updatedAt,
  });

  factory SpecializationModel.fromJson(Map<String, dynamic> json) {
    return SpecializationModel(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      icon: json['icon'],
      photo: json['photo'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'icon': icon,
      'photo': photo,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class TailorModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String phoneNumber;
  final String address;
  final String? shopDescription;
  final String? profilePhoto;
  final List<dynamic> gallery;
  final int totalOrders;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<dynamic> specializations;
  final double? average_rating;
  final int? completed_orders;
  final String? latitude;
  final String? longitude;
  double? distance;
  final List<RatingModel> ratings;

  TailorModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.address,
    this.shopDescription,
    this.profilePhoto,
    required this.gallery,
    required this.totalOrders,
    required this.createdAt,
    required this.updatedAt,
    required this.specializations,
    this.average_rating,
    this.completed_orders,
    this.latitude,
    this.longitude,
    this.distance,
    this.ratings = const [],
  });

  factory TailorModel.fromJson(Map<String, dynamic> json) {
    var avgRating = 0.0;
    var completedOrders = 0;
    
    // Cek apakah ada rating_info dalam respons
    if (json['rating_info'] != null && json['rating_info'] is Map<String, dynamic>) {
      var ratingInfo = json['rating_info'] as Map<String, dynamic>;
      
      // Ambil average_rating dari rating_info
      if (ratingInfo.containsKey('average_rating')) {
        if (ratingInfo['average_rating'] is int) {
          avgRating = (ratingInfo['average_rating'] as int).toDouble();
        } else if (ratingInfo['average_rating'] is double) {
          avgRating = ratingInfo['average_rating'];
        } else if (ratingInfo['average_rating'] is String) {
          avgRating = double.tryParse(ratingInfo['average_rating']) ?? 0.0;
        }
      }
      
      // Ambil total_reviews dari rating_info sebagai completed_orders
      if (ratingInfo.containsKey('total_reviews')) {
        if (ratingInfo['total_reviews'] is int) {
          completedOrders = ratingInfo['total_reviews'];
        } else if (ratingInfo['total_reviews'] is String) {
          completedOrders = int.tryParse(ratingInfo['total_reviews']) ?? 0;
        }
      }
    } else {
      // Jika tidak ada rating_info, coba ambil dari field average_rating langsung (fallback)
      if (json['average_rating'] != null) {
        if (json['average_rating'] is int) {
          avgRating = (json['average_rating'] as int).toDouble();
        } else if (json['average_rating'] is double) {
          avgRating = json['average_rating'];
        } else if (json['average_rating'] is String) {
          avgRating = double.tryParse(json['average_rating']) ?? 0.0;
        }
      }
      
      // Ambil completed_orders langsung jika tersedia
      if (json['completed_orders'] != null) {
        if (json['completed_orders'] is int) {
          completedOrders = json['completed_orders'];
        } else if (json['completed_orders'] is String) {
          completedOrders = int.tryParse(json['completed_orders']) ?? 0;
        }
      }
    }
    
    // Debug log untuk rating dan review
    print('DEBUG TailorModel: Parsing tailor ID ${json['id']} - Name: ${json['name']}');
    print('DEBUG TailorModel: Rating info present: ${json['rating_info'] != null}');
    if (json['rating_info'] != null) {
      print('DEBUG TailorModel: Rating info content: ${json['rating_info']}');
    }
    print('DEBUG TailorModel: Final average_rating: $avgRating');
    print('DEBUG TailorModel: Final completed_orders/reviews: $completedOrders');
    
    return TailorModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      shopDescription: json['shop_description'],
      profilePhoto: json['profile_photo'],
      gallery: json['gallery'] ?? [],
      totalOrders: json['total_orders'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      specializations: json['specializations'] ?? [],
      average_rating: avgRating,
      completed_orders: completedOrders,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      distance: json['distance']?.toDouble(),
      ratings: (json['ratings'] as List<dynamic>?)?.map((e) => RatingModel.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone_number': phoneNumber,
      'address': address,
      'shop_description': shopDescription,
      'profile_photo': profilePhoto,
      'gallery': gallery,
      'total_orders': totalOrders,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'specializations': specializations,
      'average_rating': average_rating,
      'completed_orders': completed_orders,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'ratings': ratings.map((e) => e.toJson()).toList(),
    };
  }

  // Mengembalikan kategori spesialisasi yang dikelompokkan
  Map<String, List<SpecializationModel>> get specializationsByCategory {
    final Map<String, List<SpecializationModel>> result = {};

    for (var spec in specializations) {
      if (!result.containsKey(spec.category)) {
        result[spec.category] = [];
      }
      result[spec.category]!.add(spec);
    }

    return result;
  }

  // Mendapatkan URL lengkap untuk foto profil
  String getFullProfilePhotoUrl() {
    if (profilePhoto == null || profilePhoto!.isEmpty) {
      return '';
    }

    return ApiService.getFullImageUrl(profilePhoto!);
  }

  // Mendapatkan jarak dalam format yang lebih mudah dibaca
  String getFormattedDistance() {
    if (distance == null) {
      return 'Tidak diketahui';
    } else if (distance! < 1) {
      return '${(distance! * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distance!.toStringAsFixed(1)} km';
    }
  }

  // Tambahkan method untuk memperbarui jarak
  void updateDistance(double newDistance) {
    distance = newDistance;
  }

  // Method untuk mengecek apakah model memiliki data lokasi valid
  bool hasValidLocation() {
    return latitude != null &&
        longitude != null &&
        latitude!.isNotEmpty &&
        longitude!.isNotEmpty;
  }
}

class RatingInfo {
  final double averageRating;
  final int totalReviews;

  RatingInfo({
    required this.averageRating,
    required this.totalReviews,
  });

  factory RatingInfo.fromJson(Map<String, dynamic> json) {
    return RatingInfo(
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average_rating': averageRating,
      'total_reviews': totalReviews,
    };
  }
}
