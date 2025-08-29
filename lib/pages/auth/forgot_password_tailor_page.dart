import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/password_field.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/services/forgot_passowrd_service.dart';

class ForgotPasswordTailorPage extends StatefulWidget {
  const ForgotPasswordTailorPage({super.key});

  @override
  State<ForgotPasswordTailorPage> createState() =>
      _ForgotPasswordTailorPageState();
}

class _ForgotPasswordTailorPageState extends State<ForgotPasswordTailorPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = AuthController();
  final ForgotPasswordService _forgotPasswordService = ForgotPasswordService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();

  bool _isEmailSent = false;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isResetting = false;

  @override
  void dispose() {
    _authController.dispose();
    _pinController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    print('DEBUG: Memulai proses forgot password tailor');
    print('DEBUG: Email yang diinput: ${_authController.emailController.text}');

    if (!_authController.validateForgotPassword(context)) {
      print('DEBUG: Validasi email gagal');
      setState(() {
        _errorMessage = 'Email tidak boleh kosong';
        _isEmailSent = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('DEBUG: Mengirim request forgot password ke server');
      final result = await _forgotPasswordService.forgotPasswordTailor(
        _authController.emailController.text,
      );

      print('DEBUG: Response dari server: $result');

      setState(() {
        _isLoading = false;
        _isEmailSent = result['success'];
        if (!result['success']) {
          _errorMessage = result['message'];
          print('DEBUG: Gagal mengirim email: ${result['message']}');
        } else {
          print('DEBUG: Email berhasil dikirim');
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    } catch (e, stackTrace) {
      print('ERROR: Terjadi kesalahan saat forgot password:');
      print('ERROR: $e');
      print('ERROR: Stack trace:');
      print(stackTrace);

      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> _submitResetPassword() async {
    print('DEBUG: Memulai proses reset password tailor');

    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Validasi form gagal');
      return;
    }

    setState(() {
      _isResetting = true;
      _errorMessage = '';
    });

    try {
      print('DEBUG: Mengirim request reset password ke server');
      final result = await _forgotPasswordService.resetPasswordTailor(
        email: _authController.emailController.text,
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmationController.text,
        pin: _pinController.text,
      );

      print('DEBUG: Response dari server: $result');

      setState(() => _isResetting = false);

      if (!mounted) return;

      if (result['success']) {
        print('DEBUG: Reset password berhasil');
        // Tampilkan dialog sukses
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Berhasil'),
              ],
            ),
            content: const Text(
                'Password berhasil direset. Silakan login dengan password baru.'),
            actions: [
              TextButton(
                onPressed: () {
                  print('DEBUG: Menutup dialog dan kembali ke halaman login');
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.of(context).pop(); // Kembali ke halaman login
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        print('DEBUG: Reset password gagal: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('ERROR: Terjadi kesalahan saat reset password:');
      print('ERROR: $e');
      print('ERROR: Stack trace:');
      print(stackTrace);

      setState(() {
        _isResetting = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Lupa Password?',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Lupa Password?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2552),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isEmailSent
                        ? 'Masukkan PIN 6 digit yang telah dikirim ke email Anda'
                        : 'Masukkan Email yang sudah terdaftar sebagai Tailor',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),

                  if (!_isEmailSent) ...[
                    CustomTextField(
                      controller: _authController.emailController,
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!value.contains('@')) {
                          return 'Email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Kirim',
                      onPressed: _resetPassword,
                      isLoading: _isLoading,
                    ),
                  ] else ...[
                    CustomTextField(
                      controller: _pinController,
                      labelText: 'PIN',
                      hintText: 'Masukkan 6 digit PIN dari email',
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'PIN tidak boleh kosong';
                        }
                        if (value.length != 6) {
                          return 'PIN harus 6 digit';
                        }
                        if (!RegExp(r'^\d+$').hasMatch(value)) {
                          return 'PIN hanya boleh berisi angka';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    PasswordField(
                      controller: _passwordController,
                      labelText: 'Password Baru',
                      hintText: 'Minimal 8 karakter',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (value.length < 8) {
                          return 'Password minimal 8 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    PasswordField(
                      controller: _passwordConfirmationController,
                      labelText: 'Konfirmasi Password',
                      hintText: 'Masukkan ulang password baru',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Konfirmasi password tidak boleh kosong';
                        }
                        if (value != _passwordController.text) {
                          return 'Konfirmasi password tidak cocok';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Reset Password',
                      onPressed: _submitResetPassword,
                      isLoading: _isResetting,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Error message
                  if (_errorMessage.isNotEmpty)
                    _buildMessageContainer(
                      icon: Icons.error,
                      iconColor: Colors.red[400]!,
                      backgroundColor: Colors.red[100]!,
                      textColor: Colors.red[900]!,
                      message: _errorMessage,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContainer({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color textColor,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
