class SpecializationModel {
  final int? id;
  final String name;
  final String? category;
  final String? photo;
  final String? fullPhotoUrl;
  bool isSelected;

  SpecializationModel({
    this.id,
    required this.name,
    this.category,
    this.photo,
    this.fullPhotoUrl,
    this.isSelected = false,
  });

  // Create a copy of the model with updated selection state
  SpecializationModel copyWith({
    int? id,
    String? name,
    String? category,
    String? photo,
    String? fullPhotoUrl,
    bool? isSelected,
  }) {
    return SpecializationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      photo: photo ?? this.photo,
      fullPhotoUrl: fullPhotoUrl ?? this.fullPhotoUrl,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  // Factory constructor to create a SpecializationModel from JSON
  factory SpecializationModel.fromJson(Map<String, dynamic> json) {
    return SpecializationModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      category: json['category'] as String?,
      photo: json['photo'] as String?,
      fullPhotoUrl: json['full_photo_url'] as String?,
    );
  }

  // Convert the model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'photo': photo,
      'full_photo_url': fullPhotoUrl,
      'is_selected': isSelected,
    };
  }

  // Get the image path - returns fullPhotoUrl if available, otherwise returns default image
  String get imagePath {
    // Debug logging
    print('=== SpecializationModel Debug Info ===');
    print('Name: $name');
    print('Photo: $photo');
    print('FullPhotoUrl: $fullPhotoUrl');
    print('Is Network Image: $isNetworkImage');
    print('Selected: $isSelected');
    print('=============================');

    if (fullPhotoUrl != null && fullPhotoUrl!.isNotEmpty) {
      return fullPhotoUrl!;
    }
    if (photo != null && photo!.isNotEmpty) {
      return photo!;
    }
    return 'assets/images/tailor_default.png';
  }

  // Check if the image is from network
  bool get isNetworkImage {
    if (fullPhotoUrl != null && fullPhotoUrl!.isNotEmpty) {
      return fullPhotoUrl!.startsWith('http');
    }
    if (photo != null && photo!.isNotEmpty) {
      return photo!.startsWith('http');
    }
    return false;
  }

  @override
  String toString() {
    return 'SpecializationModel(id: $id, name: $name, category: $category, isSelected: $isSelected)';
  }
}
