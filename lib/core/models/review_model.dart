class CustomerReview {
  final String? name;
  final String? profilePhoto;

  CustomerReview({this.name, this.profilePhoto});

  factory CustomerReview.fromJson(Map<String, dynamic> json) {
    return CustomerReview(
      name: json['name'],
      profilePhoto: json['profile_photo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'profile_photo': profilePhoto,
    };
  }
}

class RatingModel {
  final String rating;
  final String review;
  final String createdAt;
  final CustomerReview? customer;

  RatingModel({
    required this.rating,
    required this.review,
    required this.createdAt,
    this.customer,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      rating: json['rating'].toString(),
      review: json['review'] ?? '',
      createdAt: json['created_at'] ?? '',
      customer: json['customer'] != null
          ? CustomerReview.fromJson(json['customer'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'review': review,
      'created_at': createdAt,
      'customer': customer?.toJson(),
    };
  }
} 