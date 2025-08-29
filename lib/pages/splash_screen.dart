import 'package:flutter/material.dart';
import 'dart:async';
import '../core/routes/routes.dart'; // Import untuk menggunakan konstanta rute
import '../core/services/auth_service.dart';
import '../core/providers/user_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _debugTapCount = 0;
  final int _requiredTapsForDebug = 7;
  DateTime? _lastTapTime;
  bool _timerCompleted = false;

  void _handleDebugTap() {
    final now = DateTime.now();

    // Reset counter jika taps terlalu lambat (lebih dari 3 detik)
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 3) {
      _debugTapCount = 0;
    }

    _lastTapTime = now;
    _debugTapCount++;

    if (_debugTapCount >= _requiredTapsForDebug) {
      _debugTapCount = 0; // Reset counter

      // Buka halaman debug
      Navigator.pushNamed(context, AppRoutes.debug);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Tunggu 3 detik untuk menampilkan splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Periksa status autentikasi
    final authData = await AuthService.getAuthData();

    if (!mounted) return;

    setState(() {
      _timerCompleted = true;
    });

    if (authData != null) {
      // Muat data user sebelum navigasi
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.loadUserFromPrefs();

      if (!mounted) return;

      if (success) {
        // Jika berhasil memuat data user, arahkan ke halaman yang sesuai
        final route = authData['role'] == 'pelanggan'
            ? AppRoutes.customerHome
            : AppRoutes.tailorHome;
        Navigator.pushReplacementNamed(context, route);
      } else {
        // Jika gagal memuat data user, arahkan ke login
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } else {
      // Jika belum login, arahkan ke onboarding
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2552),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _timerCompleted
                  ? null
                  : _handleDebugTap, // Hanya aktif sebelum timer selesai
              child: Image.asset(
                'assets/images/LogoPutih.png',
                width: 350,
                height: 350,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
