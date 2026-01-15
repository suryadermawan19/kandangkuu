import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kandangku/services/firebase_service.dart';
import 'package:kandangku/ui/theme/dark_theme.dart';

/// Login Screen - "Masuk" for PoultryVision (Kandangku)
/// Dark Industrial Green Theme - Bahasa Indonesia
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );

    final error = await firebaseService.signIn(
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (error != null) {
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(error)),
              ],
            ),
            backgroundColor: DarkTheme.statusDanger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      // If success (error == null), the StreamProvider will automatically
      // navigate to Dashboard via AuthWrapper
    }
  }

  /// Handle forgot password - shows dialog and sends reset email
  Future<void> _handleForgotPassword() async {
    // Use email from the field if available
    final initialEmail = _emailController.text.trim();

    final TextEditingController emailDialogController = TextEditingController(
      text: initialEmail,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DarkTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: DarkTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan email Anda untuk menerima link reset password.',
              style: TextStyle(
                color: DarkTheme.paleGreen.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailDialogController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: DarkTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: TextStyle(
                  color: DarkTheme.paleGreen.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: DarkTheme.backgroundPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: DarkTheme.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: DarkTheme.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: DarkTheme.neonGreen),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: DarkTheme.paleGreen)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, emailDialogController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: DarkTheme.neonGreen,
              foregroundColor: DarkTheme.deepForestBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final firebaseService = Provider.of<FirebaseService>(
        context,
        listen: false,
      );

      final error = await firebaseService.sendPasswordResetEmail(result);

      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(error)),
                ],
              ),
              backgroundColor: DarkTheme.statusDanger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: DarkTheme.neonGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Link reset password telah dikirim ke email Anda',
                    ),
                  ),
                ],
              ),
              backgroundColor: DarkTheme.cardBackground,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkTheme.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Icon
                  _buildLogo(),
                  const SizedBox(height: 32),

                  // Title & Subtitle
                  _buildHeader(),
                  const SizedBox(height: 48),

                  // Email Field
                  _buildEmailField(),
                  const SizedBox(height: 16),

                  // Password Field
                  _buildPasswordField(),
                  const SizedBox(height: 12),

                  // Forgot Password Button - UX Fix #8
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      child: Text(
                        'Lupa Password?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: DarkTheme.paleGreen.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Button
                  _buildLoginButton(),
                  const SizedBox(height: 24),

                  // Footer text
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DarkTheme.neonGreen,
            DarkTheme.neonGreen.withValues(alpha: 0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: DarkTheme.neonGreen.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: const Icon(
        Icons.sensors_rounded,
        size: 48,
        color: DarkTheme.deepForestBlack,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'PoultryVision',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: DarkTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masuk untuk memantau kandang',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: DarkTheme.paleGreen.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      enabled: !_isLoading,
      style: const TextStyle(color: DarkTheme.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(
          color: DarkTheme.paleGreen.withValues(alpha: 0.8),
        ),
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: DarkTheme.paleGreen,
        ),
        filled: true,
        fillColor: DarkTheme.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: DarkTheme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: DarkTheme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DarkTheme.neonGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DarkTheme.statusDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DarkTheme.statusDanger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Email tidak boleh kosong';
        }
        if (!value.contains('@')) {
          return 'Format email tidak valid';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      enabled: !_isLoading,
      style: const TextStyle(color: DarkTheme.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(
          color: DarkTheme.paleGreen.withValues(alpha: 0.8),
        ),
        prefixIcon: const Icon(Icons.lock_outlined, color: DarkTheme.paleGreen),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: DarkTheme.paleGreen,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: DarkTheme.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: DarkTheme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: DarkTheme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DarkTheme.neonGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DarkTheme.statusDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DarkTheme.statusDanger, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password tidak boleh kosong';
        }
        if (value.length < 6) {
          return 'Password minimal 6 karakter';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: DarkTheme.neonGreen,
          foregroundColor: DarkTheme.deepForestBlack,
          disabledBackgroundColor: DarkTheme.neonGreen.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DarkTheme.deepForestBlack,
                  ),
                ),
              )
            : const Text(
                'Masuk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'PoultryVision v1.0.0',
          style: TextStyle(
            fontSize: 13,
            color: DarkTheme.paleGreen.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sistem Pemantauan Kandang Cerdas',
          style: TextStyle(
            fontSize: 12,
            color: DarkTheme.paleGreen.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
