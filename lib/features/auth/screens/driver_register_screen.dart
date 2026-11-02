import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/driver_colors.dart';
import '../../dashboard/screens/dashboard_screen.dart';
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
          MaterialPageRoute(builder: (ctx) => const DashboardScreen()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverColors.bgDark,
      appBar: AppBar(
        backgroundColor: DriverColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: _prevStep,
        ),
        title: const Text(
          'Fleet Partner Registration',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _fillDemoRegistration,
            icon: const Icon(Icons.flash_on, color: DriverColors.enRouteAmber, size: 16),
            label: const Text(
              'Demo Fill',
              style: TextStyle(color: DriverColors.enRouteAmber, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: DriverColors.cardDark,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: DriverColors.borderDark),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
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
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: DriverColors.borderDark),
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
                            backgroundColor: DriverColors.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 4,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already an authorized driver? ',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: DriverColors.primaryOrangeLight,
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
    final steps = ['Info', 'OTP Verification ', 'Commercial CDL ', 'Fleet Truck'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = index ~/ 2;
          final isPassed = _currentStep > stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isPassed ? DriverColors.primaryOrange : DriverColors.borderDark,
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isActive = _currentStep == stepIndex;
        final isCompleted = _currentStep > stepIndex;

        return Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? DriverColors.onlineGreen
                    : isActive
                        ? DriverColors.primaryOrange
                        : DriverColors.cardDark,
                border: Border.all(
                  color: isCompleted
                      ? DriverColors.onlineGreen
                      : isActive
                          ? DriverColors.primaryOrange
                          : DriverColors.borderDark,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 15)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive || isCompleted ? Colors.white : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              steps[stepIndex],
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
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
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your contact information for dispatch notifications',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
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
              color: Colors.white54,
              size: 20,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
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
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_isOtpVerified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DriverColors.onlineGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: DriverColors.onlineGreen, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'VERIFIED',
                      style: TextStyle(color: DriverColors.onlineGreen, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13, height: 1.4),
            children: [
              const TextSpan(text: 'We sent a 6-digit confirmation code to\n'),
              TextSpan(
                text: email.isNotEmpty ? email : 'your email address',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 6-Digit Pin Input Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 46,
              height: 52,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: DriverColors.bgDark,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DriverColors.borderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DriverColors.borderDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DriverColors.primaryOrange, width: 2),
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
            );
          }),
        ),
        const SizedBox(height: 18),

        // Quick Demo Auto-Fill Box for Testing
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: DriverColors.enRouteAmber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: DriverColors.enRouteAmber.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: DriverColors.enRouteAmber, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demo OTP: $_activeOtpCode',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
                    color: DriverColors.enRouteAmber,
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
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
            TextButton(
              onPressed: _otpCountdown == 0 ? _resendOtp : null,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                'Resend Code',
                style: TextStyle(
                  color: _otpCountdown == 0
                      ? DriverColors.primaryOrangeLight
                      : Colors.white24,
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
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'DOT verified licenses are required for dispatch approval',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
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
          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: DriverColors.bgDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DriverColors.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLicenseClass,
              dropdownColor: DriverColors.cardDark,
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: _licenseClasses
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
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
          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
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
                    color: isSel ? DriverColors.primaryOrange.withValues(alpha: 0.2) : DriverColors.bgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel ? DriverColors.primaryOrange : DriverColors.borderDark,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      exp,
                      style: TextStyle(
                        color: isSel ? DriverColors.primaryOrange : Colors.white70,
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
          title: const Text('DOT Medical Card Active', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text('Valid physical certification', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          activeThumbColor: Colors.white,
          activeTrackColor: DriverColors.onlineGreen,
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
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Specify your vehicle specs to receive matching roadside jobs',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
        ),
        const SizedBox(height: 20),

        const Text(
          'TOW TRUCK TYPE',
          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: DriverColors.bgDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DriverColors.borderDark),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTruckType,
              dropdownColor: DriverColors.cardDark,
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: _truckTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
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
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    decoration: BoxDecoration(
                      color: DriverColors.bgDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: DriverColors.borderDark),
                    ),
                    child: Text(
                      _selectedCapacity,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
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
                activeColor: DriverColors.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'I confirm my vehicle holds valid DOT safety inspection and is covered under \$1,000,000+ Commercial Roadside Liability Insurance.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, height: 1.4),
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
            color: Colors.white70,
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
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(icon, color: DriverColors.primaryOrange, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: DriverColors.bgDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: DriverColors.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: DriverColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: DriverColors.primaryOrange, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
