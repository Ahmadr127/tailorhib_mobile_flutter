import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Utilitas untuk membantu penanganan URL dalam aplikasi
class UrlHelper {
  /// Base URL untuk API dari variabel lingkungan
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.tailorhub.my.id/api';

  /// Base URL untuk gambar dari variabel lingkungan
  static String get imageBaseUrl =>
      dotenv.env['API_IMAGE_BASE_URL'] ?? 'https://api.tailorhub.my.id';

  /// Mengubah path relatif menjadi URL lengkap
  static String getFullImageUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      print('UrlHelper: Photo path null atau kosong');
      return '';
    }

    // Jika sudah berupa URL lengkap, kembalikan apa adanya
    if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
      print('UrlHelper: URL sudah lengkap: $photoPath');
      return photoPath;
    }

    // Tambahkan base URL sesuai dengan format path
    String result;
    if (photoPath.startsWith('/')) {
      result = '$imageBaseUrl$photoPath';
      print('UrlHelper: Converted URL dengan / di awal: $result');
    } else {
      result = '$imageBaseUrl/$photoPath';
      print('UrlHelper: Converted URL tanpa / di awal: $result');
    }

    return result;
  }

  /// Mengkonversi path gambar menjadi URL lengkap yang valid
  static String getValidImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    // Jika sudah berupa URL lengkap, kembalikan apa adanya
    if (imagePath.startsWith('http')) {
      print('UrlHelper: URL sudah lengkap: $imagePath');
      return imagePath;
    }

    // Buat path yang standar dengan menghapus / di awal jika ada
    String path = imagePath;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // Periksa apakah path sudah mengandung 'storage/'
    if (path.startsWith('storage/')) {
      // Jika sudah ada storage/, gunakan langsung
      String url = '$imageBaseUrl/$path';
      print('UrlHelper: Converted URL dengan storage/ sudah ada: $url');
      return url;
    } else {
      // Jika tidak ada 'storage/', tambahkan
      String url = '$imageBaseUrl/storage/$path';
      print('UrlHelper: Converted URL dengan penambahan storage/: $url');
      return url;
    }
  }

  /// Mengecek jika URL gambar profil memerlukan perbaikan
  static bool needsUrlFix(String url) {
    return url.contains('/storage/storage/') ||
        (!url.contains('/storage/') && !url.startsWith('http'));
  }

  /// Mengembalikan URL gambar yang sudah diperbaiki
  static String fixImageUrl(String url) {
    // Jika URL sudah lengkap dengan http, kembalikan apa adanya
    if (url.startsWith('http')) {
      // Periksa duplikasi /storage/storage/
      if (url.contains('/storage/storage/')) {
        return url.replaceAll('/storage/storage/', '/storage/');
      }
      return url;
    }

    // Jika tidak ada /storage/ sama sekali, tambahkan
    if (!url.contains('/storage/')) {
      if (url.startsWith('/')) {
        return '$imageBaseUrl/storage$url';
      } else {
        return '$imageBaseUrl/storage/$url';
      }
    }

    // Jika sudah ada /storage/ tetapi bukan URL lengkap
    if (!url.startsWith('http')) {
      if (url.startsWith('/')) {
        return '$imageBaseUrl$url';
      } else {
        return '$imageBaseUrl/$url';
      }
    }

    return url;
  }
}
