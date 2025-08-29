import 'package:flutter/material.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/controllers/auth_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final AuthController _authController = AuthController();
  bool _isEmailSent = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    if (!_authController.validateForgotPassword(context)) {
      setState(() {
        _errorMessage = 'Email tidak boleh kosong';
        _isEmailSent = false;
      });
      return;
    }

    // Simulasi kirim email reset password
    setState(() {
      _isEmailSent = true;
      _errorMessage = '';
    });

    // Di implementasi nyata, di sini akan memanggil API untuk reset password
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
                const Text(
                  'Masukkan Email yang sudah terdaftar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                // Email field
                CustomTextField(
                  controller: _authController.emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                // Kirim button
                CustomButton(
                  text: 'Kirim',
                  onPressed: _resetPassword,
                ),
                const SizedBox(height: 20),
                // Success or Error message
                if (_isEmailSent)
                  _buildMessageContainer(
                    icon: Icons.check_circle,
                    iconColor: Colors.pink[400]!,
                    backgroundColor: Colors.pink[100]!,
                    textColor: Colors.pink[900]!,
                    message:
                        'Email reset password akan dikirim jika email terdaftar',
                  ),
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
