class GalleryItem {
  final int id;
  final String title;
  final String description;
  final String category;
  final String photo;
  final String fullPhotoUrl;
  final String createdAt;
  final String updatedAt;

  GalleryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.photo,
    required this.fullPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      photo: json['photo'] ?? '',
      fullPhotoUrl: json['full_photo_url'] ?? json['photo'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'photo': photo,
      'full_photo_url': fullPhotoUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
