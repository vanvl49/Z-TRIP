import 'package:flutter/material.dart';
import 'package:rentalkuy/services/password_reset_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  // Step: 0 = email, 1 = otp, 2 = new password
  int _step = 0;
  bool _isLoading = false;
  String? _error;

  // Step 1
  final TextEditingController _emailController = TextEditingController();

  // Step 2
  final TextEditingController _otpController = TextEditingController();
  String? _resetToken;

  // Step 3
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _email; // Save email for next steps

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final email = _emailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        setState(() => _error = 'Email tidak valid');
        return;
      }
      final success = await PasswordResetService.requestPasswordReset(email);
      if (success) {
        setState(() {
          _step = 1;
          _email = email;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode OTP dikirim ke email')),
        );
      } else {
        setState(() => _error = 'Gagal mengirim permintaan reset');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final otp = _otpController.text.trim();
      if (otp.isEmpty) {
        setState(() => _error = 'OTP tidak boleh kosong');
        return;
      }
      final token = await PasswordResetService.verifyOTP(_email!, otp);
      if (token != null) {
        setState(() {
          _resetToken = token;
          _step = 2;
        });
      } else {
        setState(() => _error = 'OTP salah atau expired');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final newPass = _newPasswordController.text;
      final confirmPass = _confirmPasswordController.text;
      if (newPass.length < 6) {
        setState(() => _error = 'Password minimal 6 karakter');
        return;
      }
      if (newPass != confirmPass) {
        setState(() => _error = 'Konfirmasi password tidak sama');
        return;
      }
      final success = await PasswordResetService.resetPassword(
        _email!,
        _resetToken!,
        newPass,
        confirmPass,
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password berhasil direset! Silakan login.'),
            ),
          );
          Navigator.pop(context); // Kembali ke login
        }
      } else {
        setState(() => _error = 'Gagal reset password');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _step == 0
                    ? _buildEmailStep()
                    : _step == 1
                    ? _buildOtpStep()
                    : _buildNewPasswordStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Masukkan email akun Anda', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _requestReset,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Kirim OTP'),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Masukkan kode OTP yang dikirim ke email Anda',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _otpController,
          decoration: const InputDecoration(
            labelText: 'Kode OTP',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _verifyOtp,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Verifikasi OTP'),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Masukkan password baru Anda',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password Baru',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Konfirmasi Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _resetPassword,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset Password'),
          ),
        ),
      ],
    );
  }
}
