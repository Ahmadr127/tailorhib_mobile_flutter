class GalleryModel {
  final int id;
  final int userId;
  final String photo;
  final String title;
  final String description;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fullPhotoUrl;

  GalleryModel({
    required this.id,
    required this.userId,
    required this.photo,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.fullPhotoUrl,
  });

  factory GalleryModel.fromJson(Map<String, dynamic> json) {
    return GalleryModel(
      id: json['id'],
      userId: json['user_id'],
      photo: json['photo'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      fullPhotoUrl: json['full_photo_url'],
    );
  }
}
