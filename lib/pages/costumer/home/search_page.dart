import 'package:flutter/material.dart';
import '../../../core/models/tailor_model.dart';
import '../../../core/services/search_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/tailor_card.dart';
import 'description_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  List<TailorModel> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasSearched = false;

  Future<void> _searchTailors(String query) async {
    if (!mounted) return;

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await _searchService.searchTailors(query);

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isLoading = false;
        _hasSearched = true;
        _errorMessage = '';
      });
    } catch (e) {
      AppLogger.error('Error saat mencari penjahit', error: e);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasSearched = true;
        _searchResults = [];
        _errorMessage = 'Terjadi kesalahan saat mencari penjahit';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Cari Penjahit',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF1A2552),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Color(0xFF1A2552)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama penjahit...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchTailors('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1A2552)),
                ),
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && _searchController.text == value) {
                    _searchTailors(value);
                  }
                });
              },
            ),
          ),

          // Search Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : !_hasSearched
                        ? const Center(
                            child: Text(
                              'Cari penjahit berdasarkan nama',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : _searchResults.isEmpty
                            ? const Center(
                                child: Text(
                                  'Tidak ada penjahit yang ditemukan',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : _buildSearchResultsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final tailor = _searchResults[index];
          return SizedBox(
            height: 180,
            width: 150,
            child: TailorCard(
              name: tailor.name,
              subtitle: tailor.shopDescription?.isNotEmpty ?? false
                  ? tailor.shopDescription!
                  : tailor.address,
              imagePath: tailor.profilePhoto != null
                  ? ApiService.getFullImageUrl(tailor.profilePhoto!)
                  : 'assets/images/tailor_default.png',
              rating: tailor.average_rating,
              reviewCount: tailor.completed_orders,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DescriptionPage(
                      tailor: tailor,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
