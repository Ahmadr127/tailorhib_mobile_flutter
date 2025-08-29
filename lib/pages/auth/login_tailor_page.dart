import 'package:flutter/material.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/password_field.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/routes/routes.dart';
import 'forgot_password_tailor_page.dart';

class LoginTailorPage extends StatefulWidget {
  const LoginTailorPage({super.key});

  @override
  State<LoginTailorPage> createState() => _LoginTailorPageState();
}

class _LoginTailorPageState extends State<LoginTailorPage> {
  final AuthController _authController = AuthController();
  bool _isLoading = false;

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  Future<void> _loginTailor(BuildContext context) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authController.loginTailor(context);

      if (!mounted) return;

      if (result) {
        // Navigasi ke halaman utama penjahit setelah login
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.tailorHome,
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return false;
      },
      child: Scaffold(
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
                    const Text(
                      'Login Penjahit',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                    // Lupa Password & Login Pelanggan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Lupa Password
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordTailorPage(),
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
                        // Login Pelanggan
                        GestureDetector(
                          onTap: () {
                              Navigator.pushReplacementNamed(
                              context,
                                AppRoutes.login,
                            );
                          },
                          child: const Text(
                            'Login Pelanggan',
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
                        onPressed: _isLoading 
                          ? () {} 
                          : () => _loginTailor(context),
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 20),
                    // Daftar link
                    GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.registerOption,
                                );
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
      ),
    );
  }
}
