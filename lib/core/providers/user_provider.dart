import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../utils/logger.dart';

class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  bool get isLoggedIn => _user != null;

  // Mengatur user dari data json
  Future<void> setUser(Map<String, dynamic> userData) async {
    try {
      print(
          'DEBUG PROVIDER: Menerima data user untuk disimpan. Keys: ${userData.keys.join(', ')}');

      // Log profile photo jika ada
      if (userData.containsKey('profile_photo')) {
        print(
            'DEBUG PROVIDER: profile_photo yang diterima: ${userData['profile_photo']}');
      } else {
        print('DEBUG PROVIDER: Tidak ada profile_photo dalam data user');
      }

      _user = User.fromJson(userData);

      // Log data user setelah konversi
      print(
          'DEBUG PROVIDER: User setelah konversi. Profile photo: ${_user?.profilePhoto}');

      // Simpan data user ke SharedPreferences
      await _saveUserToPrefs();

      notifyListeners();
    } catch (e) {
      print('Error setting user: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Memperbarui user dari data json dari API profile
  Future<void> updateUserFromJson(Map<String, dynamic> userData) async {
    try {
      AppLogger.info('Memperbarui data pengguna dari profil API',
          tag: 'UserProvider');
      AppLogger.debug('Data profil yang diterima: ${userData.keys.join(', ')}',
          tag: 'UserProvider');

      // Konversi data ke model User
      final updatedUser = User.fromJson(userData);

      // Update data user yang ada dengan data terbaru
      _user = updatedUser;

      // Simpan perubahan ke SharedPreferences
      await _saveUserToPrefs();

      AppLogger.info('Data pengguna berhasil diperbarui dari profil API',
          tag: 'UserProvider');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Gagal memperbarui data pengguna dari profil API',
          error: e, tag: 'UserProvider');
    }
  }

  // Menyimpan data user ke SharedPreferences
  Future<void> _saveUserToPrefs() async {
    if (_user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(_user!.toJson());
      await prefs.setString('user_data', userJson);
      print('Data user berhasil disimpan ke SharedPreferences');
    } catch (e) {
      print('Error saving user to SharedPreferences: $e');
    }
  }

  // Memuat data user dari SharedPreferences
  Future<bool> loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');

      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error loading user from SharedPreferences: $e');
      return false;
    }
  }

  // Menghapus data user saat logout
  Future<void> clearUser() async {
    try {
      _user = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');

      notifyListeners();
    } catch (e) {
      print('Error clearing user: $e');
    }
  }

  // Update data user
  Future<void> updateUser(Map<String, dynamic> updatedData) async {
    if (_user == null) return;

    try {
      // Gabungkan data user yang ada dengan data yang diupdate
      final Map<String, dynamic> currentData = _user!.toJson();
      final Map<String, dynamic> newData = {...currentData, ...updatedData};

      _user = User.fromJson(newData);

      // Simpan perubahan ke SharedPreferences
      await _saveUserToPrefs();

      notifyListeners();
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  // Update foto profil user
  Future<void> updateUserPhoto(String photoUrl) async {
    if (_user == null) return;

    try {
      _user = User(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        phoneNumber: _user!.phoneNumber,
        address: _user!.address,
        emailVerifiedAt: _user!.emailVerifiedAt,
        profilePhoto: photoUrl, // Update foto profil
        latitude: _user!.latitude,
        longitude: _user!.longitude,
        role: _user!.role,
        createdAt: _user!.createdAt,
        updatedAt: _user!.updatedAt,
        preferredSpecializations: _user!.preferredSpecializations,
        shopDescription: _user!.shopDescription,
        gallery: _user!.gallery,
      );

      // Simpan perubahan ke SharedPreferences
      await _saveUserToPrefs();

      notifyListeners();
    } catch (e) {
      print('Error updating user photo: $e');
    }
  }

  // Update galeri foto user
  Future<void> updateUserGallery(List<String> galleryUrls) async {
    if (_user == null) return;

    try {
      _user = User(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        phoneNumber: _user!.phoneNumber,
        address: _user!.address,
        emailVerifiedAt: _user!.emailVerifiedAt,
        profilePhoto: _user!.profilePhoto,
        latitude: _user!.latitude,
        longitude: _user!.longitude,
        role: _user!.role,
        createdAt: _user!.createdAt,
        updatedAt: _user!.updatedAt,
        preferredSpecializations: _user!.preferredSpecializations,
        shopDescription: _user!.shopDescription,
        gallery: galleryUrls, // Update gallery
      );

      // Simpan perubahan ke SharedPreferences
      await _saveUserToPrefs();

      notifyListeners();
    } catch (e) {
      print('Error updating user gallery: $e');
    }
  }
}
