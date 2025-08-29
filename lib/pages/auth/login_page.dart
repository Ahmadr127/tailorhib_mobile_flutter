import 'package:flutter/material.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/password_field.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/routes/routes.dart';
import 'login_tailor_page.dart';
import 'forgot_password_customer_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController _authController = AuthController();
  int _debugTapCount = 0;
  final int _requiredTapsForDebug = 7;
  DateTime? _lastTapTime;

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
      Navigator.pushNamed(context, '/debug');
    }
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background biru dengan logo
          Column(
            children: [
              Container(
                color: const Color(0xFF1A2552),
                height: MediaQuery.of(context).size.height * 0.5,
                width: double.infinity,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo mesin jahit
                      Image.asset(
                        'assets/images/LogoPutih.png',
                        width: 250,
                        height: 250,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Form Login - Di posisikan dengan Positioned di dalam Stack
          Positioned(
            top: MediaQuery.of(context).size.height * 0.43,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    // Judul Login
                    GestureDetector(
                      onTap: _handleDebugTap,
                      child: const Text(
                        'Login Pelanggan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Email field
                    CustomTextField(
                      controller: _authController.emailController,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),
                    // Password field
                    PasswordField(
                      controller: _authController.passwordController,
                      labelText: 'Password',
                    ),
                    const SizedBox(height: 10),
                    // Lupa Password & Login Penjahit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Lupa Password
                        GestureDetector(
                          onTap: () {
                            // Navigasi ke halaman lupa password customer
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordCustomerPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Lupa Password?',
                            style: TextStyle(
                              color: Color(0xFF1A2552),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Login Penjahit
                        GestureDetector(
                          onTap: () {
                            // Navigasi ke halaman login penjahit
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginTailorPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Login Penjahit',
                            style: TextStyle(
                              color: Color(0xFF1A2552),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Login button
                    CustomButton(
                      text: 'Login',
                      onPressed: () async {
                        if (_authController.validateLoginInputs(context)) {
                          // Implementasi login pelanggan
                          final success =
                              await _authController.loginCustomer(context);
                          if (success) {
                            // Navigasi ke halaman utama customer
                            Navigator.pushReplacementNamed(
                                context, AppRoutes.customerHome);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    // Daftar link
                    GestureDetector(
                      onTap: () {
                        // Navigate to register page
                        Navigator.pushNamed(
                            context, AppRoutes.registerCustomer);
                      },
                      child: const Text(
                        'Daftar?',
                        style: TextStyle(
                          color: Color(0xFF1A2552),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
