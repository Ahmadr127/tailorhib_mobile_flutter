import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/routes.dart' as app_routes;
import 'package:google_fonts/google_fonts.dart';
import 'core/providers/user_provider.dart';
import 'core/services/api_service.dart';
import 'core/utils/logger.dart';
import 'core/controllers/booking_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/controllers/midtrans_controller.dart';
import 'core/controllers/wallet_wd_controller.dart';
import 'pages/tailor/wallet/withdrawal_page.dart';
import 'pages/tailor/wallet/wallet_history_page.dart';
import 'pages/tailor/wallet/add_bank_account_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Tangkap semua error yang tidak tertangani
  runZonedGuarded(() async {
    // Pastikan Flutter diinisialisasi terlebih dahulu
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Load konfigurasi dari .env file
      await dotenv.load(fileName: ".env");
      print("✅ Berhasil memuat .env dari root");
    } catch (e) {
      print("⚠️ Gagal memuat .env: $e");
      
      // Set nilai default untuk development lokal
      dotenv.env['API_BASE_URL'] = 'https://api-tailorhub.my.id/api'; // Android emulator -> localhost
      dotenv.env['API_IMAGE_BASE_URL'] = 'https://api-tailorhub.my.id/';
      
      print("🔧 Menggunakan URL lokal untuk development");
    }

    // Inisialisasi locale formatting untuk date/time
    await initializeDateFormatting('id', null);

    // Cetak nilai variabel lingkungan untuk debugging
    print("👉 API_BASE_URL: ${dotenv.env['API_BASE_URL']}");
    print("👉 API_IMAGE_BASE_URL: ${dotenv.env['API_IMAGE_BASE_URL']}");

    // Aktifkan verbose logging di mode debug
    AppLogger.enableVerboseLogging(true);
    AppLogger.info('Starting TailorHub Application');

    // Inisialisasi API Service
    await ApiService.init();

    // Tangkap Flutter error
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      AppLogger.error(
        'Flutter error',
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    // Selalu mulai dari splash screen untuk UX yang lebih baik
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => WalletWDController()),
          ChangeNotifierProvider(create: (_) => BookingController()),
          ChangeNotifierProvider(create: (_) => MidtransController()),
        ],
        child: const MyApp(initialRoute: AppRoutes.splash),
      ),
    );
  }, (error, stackTrace) {
    // Tangkap error pada Zone
    AppLogger.error(
      'Uncaught error in app',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String withdrawal = '/withdrawal';
  static const String walletHistory = '/wallet-history';
  static const String addBankAccount = '/add-bank-account';
  // ... existing routes ...
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({
    super.key,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TailorHub',
      theme: ThemeData(
        primaryColor: const Color(0xFF1A2552),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A2552),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: app_routes.AppRoutes.getRoutes(),
      onGenerateRoute: (settings) {
        // Handle wallet related routes
        switch (settings.name) {
          case AppRoutes.withdrawal:
            return MaterialPageRoute(
              builder: (context) => const WithdrawalPage(),
            );
          case AppRoutes.walletHistory:
            return MaterialPageRoute(
              builder: (context) => const WalletHistoryPage(),
            );
          case AppRoutes.addBankAccount:
            return MaterialPageRoute(
              builder: (context) => const AddBankAccountPage(),
            );
          default:
            // Use the default route generator from routes.dart
            return app_routes.AppRoutes.onGenerateRoute(settings);
        }
      },
    );
  }
}
