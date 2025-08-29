import 'package:flutter/material.dart';
import '../../pages/splash_screen.dart';
import '../../pages/onboarding_page.dart';
import '../../pages/register_option_page.dart';
import '../../pages/auth/login_page.dart';
import '../../pages/auth/register_customer_page.dart';
import '../../pages/auth/login_tailor_page.dart';
import '../../pages/costumer/main_page.dart' as customer;
import '../../pages/costumer/order/payment_page.dart';
import '../../pages/tailor/main_page.dart' as tailor;
import '../../pages/debug/debug_page.dart';
import '../../pages/costumer/home/booking_page.dart';

class AppRoutes {
  // Definisi nama route
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String registerOption = '/register-option';
  static const String login = '/login';
  static const String registerCustomer = '/register-customer';
  static const String loginTailor = '/login-tailor';
  static const String customerHome = '/customer-home';
  static const String tailorHome = '/tailor-home';
  static const String editProfile = '/edit-profile';
  static const String payment = '/payment';
  static const String debug = '/debug';
  static const String booking = '/booking';

  // Map untuk routes
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingPage(),
      registerOption: (context) => const RegisterOptionPage(),
      login: (context) => const LoginPage(),
      registerCustomer: (context) => const RegisterCustomerPage(),
      loginTailor: (context) => const LoginTailorPage(),
      customerHome: (context) => const customer.MainPage(),
      tailorHome: (context) => const tailor.MainPage(),
      payment: (context) {
        // Ambil parameter dari arguments route
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          // Jika tidak ada argumen, tampilkan halaman error
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Informasi pembayaran tidak lengkap')),
          );
        }
        
        // Ekstrak parameter yang diperlukan
        final bookingId = args['bookingId'] as int;
        final transactionCode = args['transactionCode'] as String? ?? 'N/A';
        
        // Konversi totalPrice ke integer untuk menghindari error
        int totalPrice = 0;
        if (args['totalPrice'] is int) {
          totalPrice = args['totalPrice'];
        } else if (args['totalPrice'] is String) {
          try {
            String numericString = (args['totalPrice'] as String).replaceAll(RegExp(r'[^0-9]'), '');
            if (numericString.isNotEmpty) {
              totalPrice = int.parse(numericString);
            }
          } catch (e) {
            print('Error parsing totalPrice in route: $e');
          }
        }
        
        // Kembalikan halaman payment dengan parameter yang benar
        return PaymentPage(
          bookingId: bookingId,
          transactionCode: transactionCode,
          totalPrice: totalPrice,
        );
      },
      debug: (context) => const DebugPage(),
      booking: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return BookingPage(
          tailorId: args['tailorId'],
          tailorName: args['tailorName'],
          tailorImage: args['tailorImage'],
        );
      },
    };
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Extract the route name from the settings
    final String? route = settings.name;

    // Check for specific pages with custom transitions or handlers
    switch (route) {
      // ... other routes

      case '/payment':
        // Pastikan argumen didapat dan dikonversi dengan benar
        final Map<String, dynamic>? args = settings.arguments as Map<String, dynamic>?;
        
        if (args != null && args['bookingId'] != null && args.containsKey('totalPrice')) {
          // Konversi totalPrice ke integer untuk menghindari error
          int bookingId = args['bookingId'] is int ? args['bookingId'] : 0;
          String transactionCode = args['transactionCode'] as String? ?? 'N/A';
          
          // Konversi totalPrice ke integer
          int totalPrice = 0;
          if (args['totalPrice'] is int) {
            totalPrice = args['totalPrice'];
          } else if (args['totalPrice'] is String) {
            try {
              String numericString = (args['totalPrice'] as String).replaceAll(RegExp(r'[^0-9]'), '');
              if (numericString.isNotEmpty) {
                totalPrice = int.parse(numericString);
              }
            } catch (e) {
              print('Error parsing totalPrice in route: $e');
            }
          }
          
          return MaterialPageRoute(
            builder: (_) => PaymentPage(
              bookingId: bookingId,
              transactionCode: transactionCode,
              totalPrice: totalPrice,
            ),
          );
        }
        
        // Jika tidak ada argumen yang valid, tampilkan halaman error
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text('No payment information provided'),
            ),
          ),
        );

      // ... other routes

      default:
        // Return the default route for unknown routes
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(
              child: Text('Page not found'),
            ),
          ),
        );
    }
  }
}
