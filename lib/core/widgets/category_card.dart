import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class CategoryCard extends StatelessWidget {
  final String imagePath;
  final String categoryName;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isNetworkImage;

  // Cache gambar yang berhasil dibuat
  static final Map<String, ui.Image> _imageCache = {};
  // Cache gambar yang gagal, untuk menghindari percobaan berulang
  static final Set<String> _failedImageUrls = {};

  const CategoryCard({
    super.key,
    required this.imagePath,
    required this.categoryName,
    required this.isSelected,
    required this.onTap,
    this.isNetworkImage = false,
  });

  @override
  Widget build(BuildContext context) {
    print('\n=== CategoryCard Debug Info ===');
    print('Category Name: $categoryName');
    print('Image Path: $imagePath');
    print('Is Network Image: $isNetworkImage');
    print('Selected: $isSelected');
    print('=============================\n');

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFF1A2552).withOpacity(0.1)
                  : Colors.grey[200],
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF1A2552) : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _buildImage(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            categoryName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF1A2552) : Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    // Cek apakah URL sudah gagal sebelumnya
    if (isNetworkImage && _failedImageUrls.contains(imagePath)) {
      print('⚠️ URL gambar sudah diketahui gagal sebelumnya: $imagePath');
      return _buildDefaultCategoryIcon();
    }

    if (isNetworkImage) {
      // Verifikasi URL yang valid
      if (!_isValidUrl(imagePath)) {
        print('⚠️ URL gambar tidak valid: $imagePath');
        _failedImageUrls.add(imagePath);
        return _buildDefaultCategoryIcon();
      }

      // Gunakan FutureBuilder untuk memungkinkan lebih banyak kontrol selama loading
      return FutureBuilder<http.Response>(
        future: _fetchImage(imagePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A2552),
                strokeWidth: 2,
              ),
            );
          } else if (snapshot.hasError) {
            print('❌ Error loading image: ${snapshot.error}');
            _failedImageUrls.add(imagePath);
            return _buildDefaultCategoryIcon();
          } else if (snapshot.hasData) {
            final response = snapshot.data!;
            if (response.statusCode == 200) {
              // Periksa content-type
              final contentType = response.headers['content-type'];
              if (contentType != null && contentType.startsWith('image/')) {
                print('✅ Image loaded successfully: $imagePath');
                // Gunakan Image.memory untuk memuat dari bytes
                return Image.memory(
                  response.bodyBytes,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Error rendering image: $error');
                    _failedImageUrls.add(imagePath);
                    return _buildDefaultCategoryIcon();
                  },
                );
              } else {
                print(
                    '❌ URL tidak menghasilkan gambar: Content-Type = $contentType');
                _failedImageUrls.add(imagePath);
                return _buildDefaultCategoryIcon();
              }
            } else {
              print(
                  '❌ Failed to load image. Status code: ${response.statusCode}');
              _failedImageUrls.add(imagePath);
              return _buildDefaultCategoryIcon();
            }
          } else {
            print('❌ No data received for image');
            _failedImageUrls.add(imagePath);
            return _buildDefaultCategoryIcon();
          }
        },
      );
    } else {
      // For asset images
      try {
        // Check if it already has the full path or just the filename
        final String assetPath = _getAssetPath(imagePath);

        print('🖼️ Loading asset from: $assetPath');

        return Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error loading asset image: $assetPath');
            print('   Error: $error');
            // Coba gunakan tailor_default.png sebagai fallback
            if (assetPath != 'assets/images/tailor_default.png') {
              print(
                  '🔄 Mencoba menggunakan tailor_default.png sebagai fallback');
              return Image.asset(
                'assets/images/tailor_default.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Fallback image juga gagal: $error');
                  return _buildDefaultCategoryIcon();
                },
              );
            }
            return _buildDefaultCategoryIcon();
          },
        );
      } catch (e) {
        print('❌ Exception in _buildImage for asset: $e');
        return _buildDefaultCategoryIcon();
      }
    }
  }

  // Helper untuk menentukan path asset yang benar
  String _getAssetPath(String path) {
    // Daftar gambar default yang mungkin sudah terpasang di aplikasi
    final knownAssets = {
      'tailor_default.png': 'assets/images/tailor_default.png',
      'avatar_default.png':
          'assets/images/tailor_default.png', // Fallback jika avatar_default tidak ada
      'default_profile.png': 'assets/images/tailor_default.png',
    };

    // Jika path adalah salah satu nama file default, gunakan path lengkap yang diketahui
    if (knownAssets.containsKey(path)) {
      return knownAssets[path]!;
    }

    // Jika sudah memiliki path lengkap assets/
    if (path.startsWith('assets/')) {
      return path;
    }

    // Default pattern untuk assets
    return 'assets/images/$path';
  }

  // Widget default untuk menampilkan ikon kategori
  Widget _buildDefaultCategoryIcon() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              categoryName.toLowerCase().contains('gaun') ||
                      categoryName.toLowerCase().contains('dress')
                  ? Icons.checkroom
                  : categoryName.toLowerCase().contains('celana') ||
                          categoryName.contains('pants')
                      ? Icons.accessibility_new
                      : categoryName.toLowerCase().contains('kemeja') ||
                              categoryName.toLowerCase().contains('shirt')
                          ? Icons.add_box_outlined
                          : Icons.category,
              color: Colors.grey[500],
              size: 30,
            ),
            const SizedBox(height: 2),
            Text(
              categoryName.length > 3
                  ? categoryName.substring(0, 3)
                  : categoryName,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk memeriksa apakah URL valid
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme.isNotEmpty && uri.host.isNotEmpty;
    } catch (e) {
      print('Invalid URL: $e');
      return false;
    }
  }

  // Helper untuk fetch image dengan HTTP request
  Future<http.Response> _fetchImage(String url) async {
    try {
      // Tambahkan header untuk cache control
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'image/*',
          'Cache-Control': 'max-age=3600', // Cache satu jam
        },
      );
      return response;
    } catch (e) {
      print('Error fetching image: $e');
      rethrow;
    }
  }

  /// Metode untuk menampilkan dialog debug saat ada masalah dengan gambar
  static Future<void> showImageDebugDialog(
      BuildContext context, String url) async {
    try {
      // Periksa URL terlebih dahulu
      final validationResult = await CategoryCard.debugImageUrl(url);

      // Tampilkan dialog dengan detail debug
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Image Debug Info'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('URL: $url',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                const Text('Diagnostic results:'),
                Text(validationResult.toString()),
                const SizedBox(height: 10),
                const Text('Troubleshooting steps:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('1. Cek koneksi internet'),
                const Text('2. Pastikan URL gambar benar'),
                const Text('3. Periksa izin akses ke file'),
                const Text('4. Periksa ukuran gambar (tidak terlalu besar)'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Coba perbaiki URL gambar secara otomatis
                ApiService.fixDesignPhotoUrl(url).then((fixedUrl) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(fixedUrl != url
                          ? 'URL berhasil diperbaiki: $fixedUrl'
                          : 'Tidak dapat memperbaiki URL'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                });
              },
              child: const Text('Coba Perbaiki'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing debug dialog: $e');
    }
  }

  /// Metode untuk melakukan debug URL gambar
  static Future<Map<String, dynamic>> debugImageUrl(String url) async {
    try {
      print('\n====== DEBUG IMAGE URL ======');
      print('URL: $url');

      // Validasi format URL
      Uri? uri;
      try {
        uri = Uri.parse(url);
        print(
            'URL valid dengan scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path}');
      } catch (e) {
        print('❌ URL tidak valid: $e');
        return {'success': false, 'error': 'URL tidak valid: $e', 'url': url};
      }

      // Coba ambil header untuk memeriksa status
      try {
        final headResponse = await http.head(uri);
        print('HEAD response status: ${headResponse.statusCode}');
        print('HEAD response headers: ${headResponse.headers}');

        if (headResponse.statusCode >= 400) {
          return {
            'success': false,
            'error':
                'HEAD request gagal dengan status ${headResponse.statusCode}',
            'status': headResponse.statusCode,
            'url': url
          };
        }
      } catch (e) {
        print('❌ Error melakukan HEAD request: $e');
      }

      // Coba ambil gambar untuk memeriksa content
      try {
        final getResponse = await http.get(uri);
        print('GET response status: ${getResponse.statusCode}');
        print('GET content-type: ${getResponse.headers['content-type']}');
        print('GET content-length: ${getResponse.headers['content-length']}');

        if (getResponse.statusCode == 200) {
          final contentType = getResponse.headers['content-type'];
          if (contentType != null && contentType.startsWith('image/')) {
            print(
                '✅ URL berisi gambar valid (${getResponse.bodyBytes.length} bytes)');
            return {
              'success': true,
              'message': 'URL berisi gambar valid',
              'contentType': contentType,
              'size': getResponse.bodyBytes.length,
              'url': url
            };
          } else {
            print(
                '❌ URL tidak berisi konten gambar. Content-type: $contentType');
            return {
              'success': false,
              'error': 'URL tidak berisi konten gambar',
              'contentType': contentType,
              'url': url
            };
          }
        } else {
          print('❌ GET request gagal dengan status: ${getResponse.statusCode}');
          return {
            'success': false,
            'error':
                'GET request gagal dengan status ${getResponse.statusCode}',
            'status': getResponse.statusCode,
            'url': url
          };
        }
      } catch (e) {
        print('❌ Error melakukan GET request: $e');
        return {'success': false, 'error': 'Error GET request: $e', 'url': url};
      }
    } catch (e) {
      print('❌ Error debugging image URL: $e');
      return {'success': false, 'error': 'Error debugging: $e', 'url': url};
    }
  }
}
