import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../models/gallery_item_model.dart';
import '../utils/logger.dart';
import '../services/profile_service.dart';

class ProfileController {
  bool isLoading = false;

  // Memperbarui data pengguna dari respons JSON API
  Future<bool> updateUserFromJson(
      BuildContext context, Map<String, dynamic> userData) async {
    try {
      AppLogger.info('Memperbarui data pengguna dari JSON',
          tag: 'ProfileController');

      // Dapatkan UserProvider
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Perbarui data pengguna menggunakan metode di UserProvider
      await userProvider.updateUserFromJson(userData);

      AppLogger.info('Data pengguna berhasil diperbarui',
          tag: 'ProfileController');
      return true;
    } catch (e) {
      AppLogger.error('Gagal memperbarui data pengguna dari JSON',
          error: e, tag: 'ProfileController');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Terjadi kesalahan saat memperbarui data pengguna: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Load user profile dari API
  Future<bool> loadUserProfile(BuildContext context) async {
    try {
      isLoading = true;
      AppLogger.info('Memuat profil pengguna', tag: 'ProfileController');

      final result = await ProfileService.getProfile();

      if (result['success'] && result['data'] != null) {
        // Update UserProvider dengan data terbaru
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.updateUserFromJson(result['data']);

        AppLogger.info('Profil berhasil dimuat dan diperbarui',
            tag: 'ProfileController');
        isLoading = false;
        return true;
      } else {
        AppLogger.error('Gagal memuat profil: ${result['message']}',
            tag: 'ProfileController');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal memuat profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
        isLoading = false;
        return false;
      }
    } catch (e) {
      isLoading = false;
      AppLogger.error('Exception saat memuat profil',
          error: e, tag: 'ProfileController');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Upload foto profil
  Future<bool> uploadProfilePhoto(BuildContext context, File photo) async {
    isLoading = true;
    AppLogger.info('Mulai upload foto profil', tag: 'ProfileController');

    try {
      // Menggunakan ProfileService daripada ApiService untuk upload foto
      final result = await ProfileService.uploadProfilePhoto(photo);

      isLoading = false;
      AppLogger.api('Respons upload foto profil:',
          data: result, tag: 'ProfileController');

      if (result['success']) {
        // Update profile photo in UserProvider if data is returned
        if (result.containsKey('data') && result['data'] != null) {
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          if (userProvider.user != null) {
            // Dapatkan URL foto dari respons API
            String? photoUrl;
            if (result['data'] is Map && result['data'].containsKey('photo')) {
              photoUrl = result['data']['photo'];
              AppLogger.debug('URL foto profil baru: $photoUrl',
                  tag: 'ProfileController');
            }

            // Update foto profil di UserProvider
            if (photoUrl != null) {
              await userProvider.updateUserPhoto(photoUrl);
              AppLogger.info('Foto profil berhasil diperbarui di UserProvider',
                  tag: 'ProfileController');
            }
          }
        }

        // Memuat ulang profil lengkap setelah upload foto
        await loadUserProfile(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        AppLogger.error('Gagal upload foto profil: ${result['message']}',
            tag: 'ProfileController');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      isLoading = false;
      AppLogger.error('Exception saat upload foto profil',
          error: e, tag: 'ProfileController');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Upload foto galeri
  Future<bool> uploadGalleryPhoto(BuildContext context, File photo,
      {String title = '',
      String description = '',
      String category = 'umum'}) async {
    isLoading = true;
    AppLogger.info('Mulai upload foto galeri', tag: 'Gallery');

    try {
      // Gunakan API untuk upload foto galeri
      AppLogger.debug('Mengirim file: ${photo.path} dengan judul: $title',
          tag: 'Gallery');

      final result = await ApiService.addTailorGalleryItem(
        photo: photo,
        title: title.isEmpty ? 'Karya Baru' : title,
        description:
            description.isEmpty ? 'Karya yang baru ditambahkan' : description,
        category: category.isEmpty ? 'umum' : category,
      );

      isLoading = false;
      AppLogger.api('Respons upload galeri', data: result, tag: 'Gallery');

      if (result['success']) {
        // Update gallery in UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.user != null) {
          // Pastikan data dalam format yang benar
          if (result['data'] != null) {
            try {
              // Buat objek GalleryItem dari respons
              final galleryItem = GalleryItem.fromJson(result['data']);

              // Ambil URL foto dengan prioritas fullPhotoUrl jika tersedia
              final photoUrl = galleryItem.fullPhotoUrl.isNotEmpty
                  ? galleryItem.fullPhotoUrl
                  : galleryItem.photo;

              AppLogger.debug('URL foto yang ditambahkan: $photoUrl',
                  tag: 'Gallery');

              // Buat list galeri baru dengan foto yang baru ditambahkan
              List<String> currentGallery =
                  List<String>.from(userProvider.user!.gallery ?? []);

              // Tambahkan URL baru jika belum ada dalam list
              if (!currentGallery.contains(photoUrl) && photoUrl.isNotEmpty) {
                currentGallery.add(photoUrl);

                // Update galeri di UserProvider
                userProvider.updateUserGallery(currentGallery);
                AppLogger.info(
                    'Galeri berhasil diperbarui. Total: ${currentGallery.length} foto',
                    tag: 'Gallery');
              } else {
                AppLogger.warning('Foto sudah ada dalam galeri atau URL kosong',
                    tag: 'Gallery');
              }
            } catch (parseError) {
              AppLogger.error('Error parsing data galeri',
                  error: parseError, tag: 'Gallery');
              AppLogger.debug('Data asli: ${result['data']}', tag: 'Gallery');
            }
          } else {
            AppLogger.warning('Data galeri kosong dari API', tag: 'Gallery');
          }
        }

        // Memuat ulang profil lengkap setelah upload foto galeri
        await loadUserProfile(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                result['message'] ?? 'Foto berhasil ditambahkan ke galeri'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        AppLogger.error('Gagal upload galeri: ${result['message']}',
            tag: 'Gallery');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] ?? 'Gagal menambahkan foto ke galeri'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      isLoading = false;
      AppLogger.error('Exception saat upload galeri', error: e, tag: 'Gallery');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan foto galeri: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Hapus foto dari galeri
  Future<bool> deleteGalleryPhoto(BuildContext context, String photoUrl,
      {int? galleryId}) async {
    isLoading = true;
    AppLogger.info('Mulai hapus foto galeri: $photoUrl', tag: 'Gallery');

    // Simpan referensi ke UserProvider di awal method
    UserProvider? userProvider;
    if (context.mounted) {
      try {
        userProvider = Provider.of<UserProvider>(context, listen: false);
      } catch (e) {
        AppLogger.error('Tidak dapat mengakses UserProvider',
            error: e, tag: 'Gallery');
      }
    }

    try {
      // Ekstrak ID dari URL foto jika tidak disediakan galleryId
      int? photoId = galleryId;
      if (photoId == null) {
        photoId = extractPhotoIdFromUrl(photoUrl);
        AppLogger.debug('ID diekstrak dari URL: $photoId', tag: 'Gallery');
      }

      if (photoId == null) {
        AppLogger.error(
            'Tidak dapat mengidentifikasi ID galeri dari URL: $photoUrl',
            tag: 'Gallery');

        // Hanya tampilkan SnackBar jika context masih valid
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Tidak dapat mengidentifikasi ID galeri dari URL foto'),
              backgroundColor: Colors.red,
            ),
          );
        }
        isLoading = false;
        return false;
      }

      // Gunakan API untuk menghapus foto galeri
      AppLogger.debug('Menghapus foto dengan ID: $photoId dan URL: $photoUrl',
          tag: 'Gallery');

      final result = await ApiService.deleteTailorGalleryItem(photoId);
      AppLogger.api('Respons hapus galeri', data: result, tag: 'Gallery');

      isLoading = false;

      if (result['success']) {
        // Update gallery in UserProvider jika tersedia
        if (userProvider != null && userProvider.user != null) {
          // Buat list galeri baru tanpa foto yang dihapus
          List<String> currentGallery =
              List<String>.from(userProvider.user!.gallery ?? []);

          AppLogger.debug(
              'Galeri sebelum dihapus: ${currentGallery.length} item',
              tag: 'Gallery');

          currentGallery.removeWhere((item) => item == photoUrl);

          AppLogger.debug(
              'Galeri setelah dihapus: ${currentGallery.length} item',
              tag: 'Gallery');

          // Update galeri di UserProvider
          await userProvider.updateUserGallery(currentGallery);
          AppLogger.info('Galeri berhasil diperbarui setelah penghapusan',
              tag: 'Gallery');
        } else {
          AppLogger.warning(
              'UserProvider atau user tidak tersedia, tidak dapat memperbarui galeri',
              tag: 'Gallery');
        }

        // Memuat ulang profil lengkap setelah hapus foto galeri
        await loadUserProfile(context);

        // Hanya tampilkan SnackBar jika context masih valid
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  result['message'] ?? 'Foto berhasil dihapus dari galeri'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        AppLogger.error('Gagal menghapus foto: ${result['message']}',
            tag: 'Gallery');

        // Cek apakah error terkait model tidak ditemukan
        bool isNotFoundError =
            result['message']?.toString().contains('No query results') ?? false;

        // Jika error adalah "record tidak ditemukan", hapus item dari UserProvider
        if (isNotFoundError) {
          AppLogger.warning(
              'Foto dengan ID $photoId tidak ditemukan di server, tapi akan dihapus dari UI',
              tag: 'Gallery');

          // Update galeri di UserProvider jika tersedia
          if (userProvider != null && userProvider.user != null) {
            List<String> currentGallery =
                List<String>.from(userProvider.user!.gallery ?? []);

            currentGallery.removeWhere((item) => item == photoUrl);
            await userProvider.updateUserGallery(currentGallery);
            AppLogger.info(
                'Galeri diperbarui untuk menghapus item yang tidak ada di server',
                tag: 'Gallery');

            // Hanya tampilkan SnackBar jika context masih valid
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Foto dihapus dari galeri lokal (tidak ada di server)'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return true;
          }
        }

        // Hanya tampilkan SnackBar jika context masih valid
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Gagal menghapus foto dari galeri'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      isLoading = false;
      AppLogger.error('Exception saat menghapus foto',
          error: e, tag: 'Gallery');

      // Hanya tampilkan SnackBar jika context masih valid
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus foto galeri: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Fungsi pembantu untuk mengekstrak ID dari URL foto jika diperlukan
  int? extractPhotoIdFromUrl(String url) {
    try {
      AppLogger.info('Mencoba ekstrak ID dari URL: $url', tag: 'Gallery');

      // Log URL lengkap untuk debugging
      if (url.isEmpty) {
        AppLogger.error('URL kosong tidak dapat diekstrak', tag: 'Gallery');
        return null;
      }

      // Coba beberapa pola URL yang mungkin

      // Pola 1: URL dengan format /storage/gallery/ID.jpg
      RegExp regexStorage = RegExp(r'/storage/gallery/(\d+)\.(jpg|jpeg|png)');
      var matchStorage = regexStorage.firstMatch(url);
      if (matchStorage != null && matchStorage.groupCount >= 1) {
        int id = int.parse(matchStorage.group(1)!);
        AppLogger.info('ID ditemukan dari pola storage: $id', tag: 'Gallery');
        return id;
      }

      // Pola 2: URL dengan ID sebagai bagian terakhir path /gallery/ID
      RegExp regexEndpoint = RegExp(r'/gallery/(\d+)(?:\.(jpg|jpeg|png))?');
      var matchEndpoint = regexEndpoint.firstMatch(url);
      if (matchEndpoint != null && matchEndpoint.groupCount >= 1) {
        int id = int.parse(matchEndpoint.group(1)!);
        AppLogger.info('ID ditemukan dari pola endpoint: $id', tag: 'Gallery');
        return id;
      }

      // Pola 3: URL dengan pattern /api/penjahit/gallery/ID
      RegExp regexApiEndpoint = RegExp(r'/api/penjahit/gallery/(\d+)');
      var matchApiEndpoint = regexApiEndpoint.firstMatch(url);
      if (matchApiEndpoint != null && matchApiEndpoint.groupCount >= 1) {
        int id = int.parse(matchApiEndpoint.group(1)!);
        AppLogger.info('ID ditemukan dari pola API endpoint: $id',
            tag: 'Gallery');
        return id;
      }

      // Pola 4: URL dengan ID sebelum ekstensi (namafile_ID.jpg)
      RegExp regexFilename = RegExp(r'_(\d+)\.(jpg|jpeg|png)$');
      var matchFilename = regexFilename.firstMatch(url);
      if (matchFilename != null && matchFilename.groupCount >= 1) {
        int id = int.parse(matchFilename.group(1)!);
        AppLogger.info('ID ditemukan dari pola filename: $id', tag: 'Gallery');
        return id;
      }

      // Pola 5: Coba ekstrak angka terakhir dari URL sebagai fallback
      RegExp regexLastNumber = RegExp(r'(\d+)(?:[^\d/]*)?$');
      var matchLastNumber = regexLastNumber.firstMatch(url);
      if (matchLastNumber != null) {
        int id = int.parse(matchLastNumber.group(1)!);
        AppLogger.warning(
            'ID ditemukan dari angka terakhir (fallback): $id - ini mungkin tidak akurat!',
            tag: 'Gallery');
        return id;
      }

      // Jika tidak ada pola yang cocok, periksa jika ada parameter ID dalam URL (e.g. ?id=123)
      RegExp regexQueryParam = RegExp(r'[?&]id=(\d+)');
      var matchQueryParam = regexQueryParam.firstMatch(url);
      if (matchQueryParam != null && matchQueryParam.groupCount >= 1) {
        int id = int.parse(matchQueryParam.group(1)!);
        AppLogger.info('ID ditemukan dari query parameter: $id',
            tag: 'Gallery');
        return id;
      }

      AppLogger.error('Tidak dapat mengekstrak ID dari URL: $url',
          tag: 'Gallery');
      return null;
    } catch (e) {
      AppLogger.error('Error saat mengekstrak photo ID',
          error: e, tag: 'Gallery');
      return null;
    }
  }

  Future<bool> updateProfile(
      BuildContext context, Map<String, dynamic> userData) async {
    try {
      AppLogger.info('Memulai proses update profil', tag: 'ProfileController');

      final result = await ProfileService.updateProfile(userData);

      if (result['success']) {
        // Update data di UserProvider
        if (result['data'] != null) {
          await updateUserFromJson(context, result['data']);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Profil berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal memperbarui profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      AppLogger.error('Exception saat update profil',
          error: e, tag: 'ProfileController');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}
