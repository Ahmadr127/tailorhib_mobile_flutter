import '../utils/url_helper.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String phoneNumber;
  final String address;
  final String? latitude;
  final String? longitude;
  final String? shopDescription;
  final String? profilePhoto;
  final String? emailVerifiedAt;
  final String createdAt;
  final String updatedAt;
  final List<Specialization>? preferredSpecializations;
  final List<String>? gallery;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.address,
    this.latitude,
    this.longitude,
    this.shopDescription,
    this.profilePhoto,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.preferredSpecializations,
    this.gallery,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<Specialization>? specializations;

    // Parsing specializations jika ada
    if (json['preferred_specializations'] != null) {
      specializations = (json['preferred_specializations'] as List)
          .map((item) => Specialization.fromJson(item))
          .toList();
    }

    // Parsing gallery jika ada
    List<String>? galleryList;
    if (json['gallery'] != null) {
      galleryList =
          (json['gallery'] as List).map((item) => item.toString()).toList();
    }

    // Process profile photo URL - ensure it's a complete URL
    String? profilePhoto = json['profile_photo'];

    // Konversi URL foto profil jika ada
    if (profilePhoto != null && profilePhoto.isNotEmpty) {
      // Gunakan UrlHelper yang aman dari import cycle
      profilePhoto = UrlHelper.getFullImageUrl(profilePhoto);
      print('DEBUG: URL foto profil: $profilePhoto');
    }

    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      shopDescription: json['shop_description'],
      profilePhoto: profilePhoto,
      emailVerifiedAt: json['email_verified_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      preferredSpecializations: specializations,
      gallery: galleryList,
    );
  }

  bool isPenjahit() {
    return role == 'penjahit';
  }

  bool isPelanggan() {
    return role == 'pelanggan';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone_number': phoneNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'shop_description': shopDescription,
      'profile_photo': profilePhoto,
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'preferred_specializations':
          preferredSpecializations?.map((s) => s.toJson()).toList(),
      'gallery': gallery,
    };
  }
}

class Specialization {
  final int id;
  final String name;
  final String category;
  final String? icon;
  final String? photo;
  final String? createdAt;
  final String? updatedAt;
  final Pivot? pivot;

  Specialization({
    required this.id,
    required this.name,
    required this.category,
    this.icon,
    this.photo,
    this.createdAt,
    this.updatedAt,
    this.pivot,
  });

  factory Specialization.fromJson(Map<String, dynamic> json) {
    return Specialization(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      icon: json['icon'],
      photo: json['photo'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      pivot: json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'icon': icon,
      'photo': photo,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'pivot': pivot?.toJson(),
    };
  }
}

class Pivot {
  final int userId;
  final int tailorSpecializationId;

  Pivot({
    required this.userId,
    required this.tailorSpecializationId,
  });

  factory Pivot.fromJson(Map<String, dynamic> json) {
    return Pivot(
      userId: json['user_id'],
      tailorSpecializationId: json['tailor_specialization_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'tailor_specialization_id': tailorSpecializationId,
    };
  }
}
