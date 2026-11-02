import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/driver_colors.dart';
import '../../../shared/widgets/google_logo.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../services/driver_auth_service.dart';
import 'driver_register_screen.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final TextEditingController _idController =
      TextEditingController(text: 'marcus.vance@roacstowing.com');
  final TextEditingController _passwordController =
      TextEditingController(text: 'driver2026');
  final DriverAuthService _authService = DriverAuthService();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials() {
    setState(() {
      _idController.text = 'marcus.vance@roacstowing.com';
      _passwordController.text = 'driver2026';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo driver partner credentials loaded!'),
        backgroundColor: DriverColors.primaryOrange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final identifier = _idController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty) {
      _showError('Please enter your Driver ID or Email.');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(
        identifier: identifier,
        password: password,
        rememberMe: _rememberMe,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: DriverColors.offlineRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || _isGoogleLoading || _isAppleLoading) return;

    setState(() => _isGoogleLoading = true);

    try {
      await _authService.signInWithGoogle();

      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (ctx) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      final errorMsg = e.toString().replaceFirst('Exception: ', '').trim();
      if (errorMsg.contains('cancelled') || errorMsg.contains('canceled')) {
        return;
      }

      if (errorMsg.contains('SHA-1') ||
          errorMsg.contains('certificate hash') ||
          errorMsg.contains('CERT_HASH') ||
          errorMsg.contains('ApiException: 10') ||
          errorMsg.contains('sign_in_failed') ||
          errorMsg.contains('DEVELOPER_ERROR') ||
          errorMsg.contains('Assertion') ||
          errorMsg.contains('ClientID') ||
          errorMsg.contains('appClientId') ||
          errorMsg.contains('web origin') ||
          errorMsg.contains('configuration required')) {
        _showSha1ConfigDialog(context, 'Google');
        return;
      }

      _showError(errorMsg);
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading || _isGoogleLoading || _isAppleLoading) return;

    setState(() => _isAppleLoading = true);

    try {
      await _authService.signInWithApple();

      if (!mounted) return;
      setState(() => _isAppleLoading = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (ctx) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAppleLoading = false);

      final errorMsg = e.toString().replaceFirst('Exception: ', '').trim();
      if (errorMsg.contains('cancelled') || errorMsg.contains('canceled')) {
        return;
      }

      _showError(errorMsg);
    }
  }

  void _showSha1ConfigDialog(BuildContext context, String provider) {
    const sha1 = 'D2:41:10:B1:38:0F:79:BD:8A:88:B4:D1:78:9E:95:3E:45:74:86:8B';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: Color(0xFF2563EB), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Google Sign-In Setup',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To enable live Google Sign-In on this Android device, add your SHA-1 fingerprint in Firebase Console:\n\n'
              '1. Open Firebase Console > Project Settings\n'
              '2. Select Android App (com.roacs.towing.towing_driver)\n'
              '3. Click "Add Fingerprint" & paste SHA-1 below:\n\n'
              'Or test instantly with a Driver Partner Demo account:',
              style: TextStyle(fontSize: 13, color: Color(0xFF0F172A), height: 1.45),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const SelectableText(
                sha1,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              Navigator.of(ctx).pop();
              await _authService.completeSocialDriverAuth(
                name: 'Marcus Vance ($provider)',
                email: 'marcus.vance@roacstowing.com',
                provider: provider,
              );
              if (!mounted) return;
              nav.pushReplacement(
                MaterialPageRoute(builder: (c) => const DashboardScreen()),
              );
            },
            child: const Text('Use Demo Driver', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: sha1));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SHA-1 fingerprint copied to clipboard!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy SHA-1', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCard({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: (isLoading || _isLoading) ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: Color(0xFF2563EB),
                ),
              )
            else
              icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Logo & Badge
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fire_truck_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Titles
                  const Text(
                    'ROACS DISPATCH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Driver Partner Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to access live customer tow requests',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 3. Login Input Form Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Driver ID / Email Label
                        const Text(
                          'DRIVER ID / EMAIL',
                          style: TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _idController,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. DRV-7701 or email',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF2563EB), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Password Label
                        const Text(
                          'PASSWORD',
                          style: TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2563EB), size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF64748B),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Remember Me & Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (val) {
                                      setState(() => _rememberMe = val ?? true);
                                    },
                                    activeColor: const Color(0xFF2563EB),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(color: Color(0xFF475569), fontSize: 12),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Contact your fleet dispatcher or email support@roacs.com'),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Quick Demo Fill Banner inside the card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flash_on_rounded, color: Color(0xFFD97706), size: 16),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Demo: Marcus Vance (Ready)',
                                  style: TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              TextButton(
                                onPressed: _fillDemoCredentials,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Re-fill',
                                  style: TextStyle(
                                    color: Color(0xFFB45309),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'SIGN IN TO DISPATCH',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 22),

                        // Social Login Divider: OR CONTINUE WITH
                        Row(
                          children: [
                            Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Social Login Buttons: [G Google] & [Apple Apple]
                        Row(
                          children: [
                            Expanded(
                              child: _buildSocialCard(
                                icon: const GoogleLogo(size: 20),
                                label: 'Google',
                                isLoading: _isGoogleLoading,
                                onTap: _handleGoogleSignIn,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildSocialCard(
                                icon: const Icon(
                                  Icons.apple,
                                  color: Colors.black,
                                  size: 24,
                                ),
                                label: 'Apple',
                                isLoading: _isAppleLoading,
                                onTap: _handleAppleSignIn,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 5. Apply as Partner Link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'New tow driver or fleet owner? ',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => const DriverRegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Join Fleet',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
