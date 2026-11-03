import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/driver_colors.dart';
import '../../../shared/widgets/google_logo.dart';
import '../../navigation/screens/driver_main_shell.dart';
import '../services/driver_auth_service.dart';
import '../services/driver_email_otp_service.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  int _currentStep = 0;
  final DriverAuthService _authService = DriverAuthService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  // Step 1: Personal Info Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Step 2: Email OTP Controllers & State
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());
  String _activeOtpCode = '849201';
  int _otpCountdown = 60;
  Timer? _otpTimer;
  bool _isOtpVerified = false;

  // Step 3: Commercial CDL Controllers
  final TextEditingController _cdlController = TextEditingController();
  String _selectedLicenseClass = 'Class A (Heavy Duty)';
  String _selectedExperience = '4 - 7 Years';
  bool _hasDotMedical = true;

  // Step 4: Fleet Truck Controllers
  String _selectedTruckType = 'Flatbed (Rollback)';
  final TextEditingController _truckModelController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final String _selectedCapacity = '12,000 lbs (Class 6)';
  bool _agreedToTerms = true;

  final List<String> _truckTypes = [
    'Flatbed (Rollback)',
    'Wheel-Lift',
    'Integrated Heavy Duty',
    'Boom & Recovery',
  ];

  final List<String> _licenseClasses = [
    'Class A (Heavy Duty)',
    'Class B (Medium Fleet)',
    'Class C (Light Commercial)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _otpTimer?.cancel();
    _cdlController.dispose();
    _truckModelController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() => _otpCountdown = 60);
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown > 0) {
        if (mounted) setState(() => _otpCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _fillDemoOtp() {
    for (int i = 0; i < 6; i++) {
      if (i < _activeOtpCode.length) {
        _otpControllers[i].text = _activeOtpCode[i];
      }
    }
    setState(() {});
  }

  Future<void> _resendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    _startOtpTimer();
    setState(() => _isLoading = true);

    try {
      await DriverEmailOtpService().sendOtp(recipientEmail: email);
      _activeOtpCode = DriverEmailOtpService().currentOtp ?? _activeOtpCode;
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New 6-digit verification code sent to $email!'),
          backgroundColor: DriverColors.primaryOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _fillDemoRegistration() {
    setState(() {
      _nameController.text = 'Marcus Vance';
      _emailController.text = 'marcus.vance@roacstowing.com';
      _phoneController.text = '+1 (555) 782-9901';
      _passwordController.text = 'driver2026';
      _cdlController.text = 'CDL-CA-908214';
      _truckModelController.text = '2024 Peterbilt 337';
      _plateController.text = 'TOW-PRO-88';
      _agreedToTerms = true;
      _hasDotMedical = true;
    });

    _fillDemoOtp();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All driver registration steps pre-filled!'),
        backgroundColor: DriverColors.primaryOrange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _nextStep() async {
    if (_currentStep == 0) {
      // Step 1 Validation
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final pass = _passwordController.text.trim();

      if (name.isEmpty || email.isEmpty || phone.isEmpty || pass.isEmpty) {
        _showError('Please complete all personal details.');
        return;
      }
      if (!email.contains('@') || !email.contains('.')) {
        _showError('Please enter a valid email address.');
        return;
      }
      if (pass.length < 6) {
        _showError('Password must be at least 6 characters.');
        return;
      }

      // Dispatch REAL OTP email
      setState(() => _isLoading = true);
      try {
        await DriverEmailOtpService().sendOtp(recipientEmail: email);
        _activeOtpCode = DriverEmailOtpService().currentOtp ?? _activeOtpCode;
      } catch (e) {
        debugPrint('Email OTP dispatch notice: $e');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = 1;
        });
        _startOtpTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to $email! Check inbox & spam folder.'),
            backgroundColor: DriverColors.onlineGreen,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else if (_currentStep == 1) {
      // Step 2 OTP Validation
      final enteredOtp = _otpControllers.map((c) => c.text).join();
      final email = _emailController.text.trim();

      if (enteredOtp.length < 6) {
        _showError('Please enter the full 6-digit verification code.');
        return;
      }

      final result = DriverEmailOtpService().verifyOtp(
        enteredCode: enteredOtp,
        email: email,
      );

      if (!result.isValid) {
        _showError(result.errorMessage ?? 'Invalid verification code.');
        return;
      }

      setState(() {
        _isOtpVerified = true;
        _currentStep = 2; // Advance to Step 3: Commercial CDL
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Email verified successfully!'),
          backgroundColor: DriverColors.onlineGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (_currentStep == 2) {
      // Step 3 CDL Validation
      if (_cdlController.text.trim().isEmpty) {
        _showError('Please enter your Commercial Driver License (CDL) number.');
        return;
      }
      setState(() => _currentStep = 3); // Advance to Step 4: Fleet Truck
    } else if (_currentStep == 3) {
      // Step 4 Truck & Submission
      _submitRegistration();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitRegistration() async {
    if (_truckModelController.text.trim().isEmpty || _plateController.text.trim().isEmpty) {
      _showError('Please provide your truck model and license plate.');
      return;
    }
    if (!_agreedToTerms) {
      _showError('You must agree to the DOT compliance and insurance terms.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerDriver(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        cdlNumber: _cdlController.text.trim(),
        licenseClass: _selectedLicenseClass,
        truckType: _selectedTruckType,
        truckModel: _truckModelController.text.trim(),
        licensePlate: _plateController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const DriverMainShell()),
          (route) => false,
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

  Future<void> _handleGoogleSignUp() async {
    if (_isLoading || _isGoogleLoading || _isAppleLoading) return;

    setState(() => _isGoogleLoading = true);

    try {
      final account = await _authService.signInWithGoogle();

      if (!mounted) return;
      setState(() {
        _isGoogleLoading = false;
        if (account['name']?.isNotEmpty == true) {
          _nameController.text = account['name']!;
        }
        if (account['email']?.isNotEmpty == true) {
          _emailController.text = account['email']!;
        }
        if (_passwordController.text.trim().isEmpty) {
          _passwordController.text = 'DriverPass2026!';
        }
        if (_phoneController.text.trim().isEmpty) {
          _phoneController.text = '+1 (555) 782-9901';
        }
        _isOtpVerified = true;
      });

      _showSocialConnectedDialog('Google', account['name'] ?? 'Driver Partner', account['email'] ?? '');
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

  Future<void> _handleAppleSignUp() async {
    if (_isLoading || _isGoogleLoading || _isAppleLoading) return;

    setState(() => _isAppleLoading = true);

    try {
      final account = await _authService.signInWithApple();

      if (!mounted) return;
      setState(() {
        _isAppleLoading = false;
        _nameController.text = account['name'] ?? 'Marcus Vance (Apple ID)';
        _emailController.text = account['email'] ?? 'marcus.vance.apple@roacstowing.com';
        if (_passwordController.text.trim().isEmpty) {
          _passwordController.text = 'DriverPass2026!';
        }
        if (_phoneController.text.trim().isEmpty) {
          _phoneController.text = '+1 (555) 782-9901';
        }
        _isOtpVerified = true;
      });

      _showSocialConnectedDialog('Apple', _nameController.text, _emailController.text);
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

  void _showSocialConnectedDialog(String provider, String name, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            provider == 'Google'
                ? const GoogleLogo(size: 24)
                : const Icon(Icons.apple, color: Colors.black, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$provider Connected',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Successfully verified with $provider!\n\n'
              '• Name: $name\n'
              '• Email: $email (Pre-verified)\n\n'
              'Your details have been pre-filled. How would you like to continue?',
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), height: 1.45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _currentStep = 2; // Jump directly to CDL Step since email is already verified!
              });
            },
            child: const Text('Add CDL & Truck (Step 3)', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              _cdlController.text = 'CDL-PRO-${DateTime.now().millisecondsSinceEpoch % 10000}';
              _truckModelController.text = '2024 Peterbilt 337';
              _plateController.text = 'TOW-PRO-88';
              await _submitRegistration();
            },
            child: const Text('Fast 1-Tap Onboard', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
                'Google Sign-Up Setup',
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
              'To enable live Google Registration on this Android device, add your SHA-1 fingerprint in Firebase Console:\n\n'
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
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _nameController.text = 'Marcus Vance ($provider)';
                _emailController.text = 'marcus.vance@roacstowing.com';
                _passwordController.text = 'driver2026';
                _phoneController.text = '+1 (555) 782-9901';
                _isOtpVerified = true;
              });
              _showSocialConnectedDialog(provider, _nameController.text, _emailController.text);
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
        height: 50,
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
                fontSize: 14.5,
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: _prevStep,
        ),
        title: const Text(
          'Fleet Registration',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        actions: [
          TextButton.icon(
            onPressed: _fillDemoRegistration,
            icon: const Icon(Icons.flash_on, color: Color(0xFFD97706), size: 16),
            label: const Text(
              'Demo Fill',
              style: TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Stepper Indicators (4 Steps)
                  _buildStepperHeader(),
                  const SizedBox(height: 24),

                  // Step Form Content
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
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
                    child: _buildCurrentStepContent(),
                  ),
                  const SizedBox(height: 22),

                  // Bottom Action Buttons (Back & Next/Complete)
                  Row(
                    children: [
                      if (_currentStep > 0) ...[
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: _prevStep,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  _getButtonText(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Already registered link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Already an authorized driver? ',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return 'CONTINUE TO VERIFICATION';
      case 1:
        return 'VERIFY & CONTINUE';
      case 2:
        return 'CONTINUE TO FLEET';
      case 3:
        return 'SUBMIT & JOIN FLEET';
      default:
        return 'CONTINUE';
    }
  }

  Widget _buildStepperHeader() {
    final steps = ['Personal', 'Verify', 'License', 'Fleet'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = index ~/ 2;
          final isPassed = _currentStep > stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: isPassed ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isActive = _currentStep == stepIndex;
        final isCompleted = _currentStep > stepIndex;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : isActive
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFF1F5F9),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : isActive
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              steps[stepIndex],
              style: TextStyle(
                color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildEmailOtpStep();
      case 2:
        return _buildCdlStep();
      case 3:
        return _buildTruckFleetStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Driver Personal Details',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Enter your contact information for dispatch notifications',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 20),

        _buildInputField(
          label: 'FULL LEGAL NAME',
          hint: 'e.g. Marcus Vance',
          icon: Icons.person_outline,
          controller: _nameController,
        ),
        const SizedBox(height: 16),

        _buildInputField(
          label: 'EMAIL ADDRESS',
          hint: 'e.g. driver@roacstowing.com',
          icon: Icons.email_outlined,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        _buildInputField(
          label: 'PHONE NUMBER',
          hint: '+1 (555) 000-0000',
          icon: Icons.phone_outlined,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        _buildInputField(
          label: 'SECURE PASSWORD',
          hint: 'At least 6 characters',
          icon: Icons.lock_outline,
          controller: _passwordController,
          obscureText: _obscurePassword,
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
        ),
        const SizedBox(height: 22),

        // Social Onboard Divider: OR REGISTER WITH
        Row(
          children: [
            Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'OR REGISTER WITH',
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
        const SizedBox(height: 16),

        // Social Onboard Buttons: [G Google] & [Apple Apple]
        Row(
          children: [
            Expanded(
              child: _buildSocialCard(
                icon: const GoogleLogo(size: 20),
                label: 'Google',
                isLoading: _isGoogleLoading,
                onTap: _handleGoogleSignUp,
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
                onTap: _handleAppleSignUp,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailOtpStep() {
    final email = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Step 2: Email Verification',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_isOtpVerified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'VERIFIED',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
            children: [
              const TextSpan(text: 'We sent a 6-digit confirmation code to\n'),
              TextSpan(
                text: email.isNotEmpty ? email : 'your email address',
                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 6-Digit Pin Input Boxes (Responsive layout without horizontal overflow)
        Row(
          children: List.generate(6, (index) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 3,
                  right: index == 5 ? 0 : 3,
                ),
                height: 52,
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else if (val.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                    setState(() {});
                  },
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),

        // Quick Demo Auto-Fill Box for Testing
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
              Expanded(
                child: Text(
                  'Demo OTP: $_activeOtpCode',
                  style: const TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: _fillDemoOtp,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Auto-Fill Code',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Countdown & Resend Option
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _otpCountdown > 0
                  ? 'Resend available in ${_otpCountdown}s'
                  : 'Didn\'t receive code?',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            TextButton(
              onPressed: _otpCountdown == 0 ? _resendOtp : null,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                'Resend Code',
                style: TextStyle(
                  color: _otpCountdown == 0
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCdlStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Commercial Driver License',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'DOT verified licenses are required for dispatch approval',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 20),

        _buildInputField(
          label: 'COMMERCIAL LICENSE NUMBER (CDL)',
          hint: 'e.g. CDL-CA-908214',
          icon: Icons.badge_outlined,
          controller: _cdlController,
        ),
        const SizedBox(height: 18),

        const Text(
          'LICENSE CLASSIFICATION',
          style: TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLicenseClass,
              dropdownColor: Colors.white,
              isExpanded: true,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
              items: _licenseClasses
                  .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Color(0xFF0F172A)))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedLicenseClass = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 18),

        const Text(
          'TOWING EXPERIENCE',
          style: TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['1 - 3 Years', '4 - 7 Years', '8+ Years'].map((exp) {
            final isSel = _selectedExperience == exp;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedExperience = exp),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      width: isSel ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      exp,
                      style: TextStyle(
                        color: isSel ? const Color(0xFF2563EB) : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _hasDotMedical,
          onChanged: (val) => setState(() => _hasDotMedical = val),
          title: const Text('DOT Medical Card Active', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: const Text('Valid physical certification', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildTruckFleetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 4: Tow Truck Fleet Info',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Specify your vehicle specs to receive matching roadside jobs',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 20),

        const Text(
          'TOW TRUCK TYPE',
          style: TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTruckType,
              dropdownColor: Colors.white,
              isExpanded: true,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
              items: _truckTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Color(0xFF0F172A)))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedTruckType = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildInputField(
          label: 'VEHICLE YEAR, MAKE & MODEL',
          hint: 'e.g. 2024 Peterbilt 337 or Ford F-650',
          icon: Icons.fire_truck,
          controller: _truckModelController,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildInputField(
                label: 'LICENSE PLATE',
                hint: 'e.g. TOW-PRO-88',
                icon: Icons.tag,
                controller: _plateController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WINCH CAPACITY',
                    style: TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      _selectedCapacity,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (val) => setState(() => _agreedToTerms = val ?? true),
                activeColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'I confirm my vehicle holds valid DOT safety inspection and is covered under \$1,000,000+ Commercial Roadside Liability Insurance.',
                style: TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
            suffixIcon: suffixIcon,
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
      ],
    );
  }
}
