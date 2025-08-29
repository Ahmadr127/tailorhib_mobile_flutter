import 'package:flutter/material.dart';
import 'dart:async';
import 'home/home_page.dart';
import 'profile/profile_page.dart';
import 'order/order_page.dart';
import '../../core/services/api_service.dart';
import '../../core/routes/routes.dart';
import '../../core/utils/logger.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  // Daftar halaman yang akan ditampilkan dalam TabBar
  final List<Widget> _pages = [
    const HomePage(),
    const OrderPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Periksa apakah token tersedia saat halaman dimuat
    final token = await ApiService.getToken();
    if (token == null) {
      AppLogger.warning('Halaman utama diakses tanpa token');
      // Redirect ke login
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  // Fungsi untuk menangani tombol back
  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    
    if (_lastBackPressTime == null || 
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      // Update waktu terakhir tekan back
      _lastBackPressTime = now;
      
      // Tampilkan pesan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tekan sekali lagi untuk keluar'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Jangan keluar dari aplikasi
      return false;
    }
    
    // Keluar dari aplikasi
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _pages[_currentIndex], // Tampilkan halaman sesuai index
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: const Color(0xFF1A2552),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 8,
          type: BottomNavigationBarType
              .fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), // Menggunakan versi outline
              activeIcon: Icon(Icons.home), // Versi filled saat aktif
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                  Icons.receipt_outlined), // Ganti dengan icon dokumen outline
              activeIcon: Icon(Icons.receipt), // Versi filled saat aktif
              label: 'Pesanan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), // Menggunakan versi outline
              activeIcon: Icon(Icons.person), // Versi filled saat aktif
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
