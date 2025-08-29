import 'package:flutter/material.dart';
import '../../../core/models/review_model.dart';
import '../../../core/services/api_service.dart';

class ReviewPage extends StatefulWidget {
  final List<RatingModel> reviews;

  const ReviewPage({super.key, required this.reviews});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int? _selectedRating; // null = semua

  List<RatingModel> get _filteredReviews {
    if (_selectedRating == null) return widget.reviews;
    return widget.reviews.where((r) {
      final ratingDouble = double.tryParse(r.rating) ?? 0.0;
      return ratingDouble.round() == _selectedRating;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Ulasan'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A2552),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF6F7FB),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<int?>(
                    value: _selectedRating,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua')),
                      DropdownMenuItem(value: 5, child: Text('5 Bintang')),
                      DropdownMenuItem(value: 4, child: Text('4 Bintang')),
                      DropdownMenuItem(value: 3, child: Text('3 Bintang')),
                      DropdownMenuItem(value: 2, child: Text('2 Bintang')),
                      DropdownMenuItem(value: 1, child: Text('1 Bintang')),
                    ],
                    onChanged: (val) => setState(() => _selectedRating = val),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filteredReviews.isEmpty
                    ? const Center(child: Text('Belum ada ulasan.'))
                    : ListView.builder(
                        itemCount: _filteredReviews.length,
                        itemBuilder: (context, index) {
                          final review = _filteredReviews[index];
                          final customer = review.customer;
                          final customerName = customer?.name ?? '-';
                          final customerPhoto = customer?.profilePhoto;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (customerPhoto != null && customerPhoto.isNotEmpty)
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage: NetworkImage(ApiService.getFullImageUrl(customerPhoto)),
                                          backgroundColor: Colors.grey[200],
                                        )
                                      else
                                        const CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.grey,
                                          child: Icon(Icons.person, color: Colors.white, size: 20),
                                        ),
                                      const SizedBox(width: 12),
                                      Text(
                                        customerName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1A2552)),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.star, color: Colors.amber, size: 20),
                                      const SizedBox(width: 2),
                                      Text(
                                        review.rating,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _formatDate(review.createdAt),
                                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    review.review,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return '-';
  try {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  } catch (e) {
    return dateString ?? '-';
  }
} 