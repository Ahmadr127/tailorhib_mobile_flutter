import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/tailor_card.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/tailor_model.dart';
import '../../../core/services/api_service.dart';
import 'description_page.dart';
import '../../../core/utils/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  List<TailorModel> _nearbyTailors = [];
  List<TailorModel> _recommendedTailors = [];
  List<int> _userPreferred = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _getCurrentLocation();
    await _loadRecommendedTailors();
    await _loadNearbyTailors();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Layanan lokasi tidak aktif');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('Izin lokasi ditolak');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('Izin lokasi ditolak secara permanen');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
      AppLogger.debug(
          'Posisi saat ini: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      AppLogger.error('Error mendapatkan lokasi: $e');
    }
  }

  Future<void> _loadNearbyTailors() async {
    if (_currentPosition == null) {
      AppLogger.warning(
          'Tidak dapat memuat penjahit terdekat: lokasi tidak tersedia');
      if (mounted) {
        setState(() {
          _nearbyTailors = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final result = await ApiService.getNearbyTailors(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      AppLogger.debug('Nearby tailors response: $result');

      if (mounted) {
        setState(() {
          if (result['success'] == true && result['tailors'] != null) {
            _nearbyTailors = result['tailors'];
            AppLogger.debug(
                'Berhasil memuat ${_nearbyTailors.length} penjahit terdekat');
          } else {
            AppLogger.error(
                'Gagal memuat penjahit terdekat: ${result['message']}');
            _nearbyTailors = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error memuat penjahit terdekat', error: e);
      if (mounted) {
        setState(() {
          _nearbyTailors = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRecommendedTailors() async {
    try {
      final result = await ApiService.getRecommendedTailors();
      AppLogger.debug('Recommended tailors response: $result');

      if (result['success'] == true) {
        final tailors = result['tailors'] as List<TailorModel>;
        if (mounted) {
          setState(() {
            _recommendedTailors = tailors;
            _userPreferred = result['userPreferred'] as List<int>;
            _isLoading = false;
          });
        }
      } else {
        AppLogger.error(
            'Failed to load recommended tailors: ${result['message']}');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _recommendedTailors = [];
          });
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error loading recommended tailors',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _recommendedTailors = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final User? user = userProvider.user;

        // Jika tidak ada data user, tampilkan loading
        if (user == null) {
          AppLogger.warning('User data is null in HomePage');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            title: Row(
              children: [
                // Foto profil
                Container(
                  width: 35,
                  height: 35,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade300,
                    image: user.profilePhoto != null
                        ? DecorationImage(
                            image: NetworkImage(
                              ApiService.getFullImageUrl(user.profilePhoto!),
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                // Nama user
                Expanded(
                  child: Text(
                    'Hi, ${user.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0.5,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildHomeContent(),
                ),
        );
      },
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner dengan gambar dan teks "TEMUKAN PENJAHIT TERBAIK DI KOTAMU"
                SizedBox(
                  height: 150,
                  child: PageView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Banner pertama
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEF1FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/tailor_banner.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Banner kedua
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEF1FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/tailor_banner2.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Search bar
                TextField(
                  readOnly:
                      true, // Jadikan read-only agar berfungsi seperti button
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchPage(),
                      ),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari apa?',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0), width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF1A2552), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),

                const SizedBox(height: 20),

                // Gunakan section penjahit terdekat yang telah diperbarui
                _buildNearbyTailorsSection(),

                const SizedBox(height: 20),

                // Rekomendasi Penjahit
                const Text(
                  'Rekomendasi Penjahit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 12),

                // Daftar rekomendasi penjahit
                _recommendedTailors.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Text('Tidak ada rekomendasi penjahit'),
                        ),
                      )
                    : SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recommendedTailors.length,
                          itemBuilder: (context, index) {
                            final tailor = _recommendedTailors[index];

                            return TailorCard(
                              name: tailor.name,
                              subtitle: tailor.shopDescription?.isEmpty ?? true
                                  ? 'Penjahit profesional'
                                  : tailor.shopDescription!,
                              imagePath: tailor.profilePhoto != null
                                  ? ApiService.getFullImageUrl(
                                      tailor.profilePhoto!)
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
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyTailorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Penjahit Terdekat
        const Text(
          'Penjahit Terdekat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 12),

        // Daftar penjahit terdekat
        _nearbyTailors.isEmpty
            ? _buildEmptyNearbyTailors()
            : _buildNearbyTailorsList(),
      ],
    );
  }

  Widget _buildEmptyNearbyTailors() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 20.0,
        horizontal: 16.0,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/no_location.png',
            height: 80,
            width: 80,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tidak ada penjahit terdekat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aktifkan lokasi untuk menemukan penjahit di sekitar Anda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              setState(() => _isLoading = true);
              await _getCurrentLocation();
              await _loadNearbyTailors();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2552),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyTailorsList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _nearbyTailors.length,
        itemBuilder: (context, index) {
          final tailor = _nearbyTailors[index];
          final distance = tailor.distance != null
              ? '${tailor.distance!.toStringAsFixed(1)} km'
              : 'Jarak tidak diketahui';

          return TailorCard(
            name: tailor.name,
            subtitle: distance,
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
          );
        },
      ),
    );
  }

  // Helper method untuk memastikan URL lengkap
  String _getFullProfilePhotoUrl(String photoUrl) {
    // Jika URL sudah lengkap, kembalikan apa adanya
    if (photoUrl.startsWith('http')) {
      return photoUrl;
    }

    // Jika tidak, tambahkan base URL
    return ApiService.getFullImageUrl(photoUrl);
  }
}
