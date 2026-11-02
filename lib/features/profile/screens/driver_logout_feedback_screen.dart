import 'package:flutter/material.dart';
import '../../auth/screens/driver_login_screen.dart';
import '../../auth/services/driver_auth_service.dart';

class DriverLogoutFeedbackScreen extends StatefulWidget {
  const DriverLogoutFeedbackScreen({super.key});

  @override
  State<DriverLogoutFeedbackScreen> createState() =>
      _DriverLogoutFeedbackScreenState();
}

class _DriverLogoutFeedbackScreenState extends State<DriverLogoutFeedbackScreen> {
  String? _selectedReason;
  final TextEditingController _otherController = TextEditingController();
  bool _isLoggingOut = false;

  final List<String> _reasons = [
    'No complaints, I am happy.',
    "Can't able to understand the payment structure",
    'No orders in my area',
    'Phone/Tech Issues',
    'Payment Delay',
    'Team Leader is not responding',
    'Penalty Issues',
    "Other's",
  ];

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _processLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    // Provide quick user feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your feedback. Logging out...'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));
    await DriverAuthService().logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Heading
            const Text(
              'Any Complaints ? Please help us to resolve it -',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                height: 1.35,
              ),
            ),

            const SizedBox(height: 24),

            // 2. Concerned Emoji Illustration matching Image 1
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.2, -0.3),
                    colors: [
                      Color(0xFFFFDF00),
                      Color(0xFFFF9900),
                      Color(0xFFE65100),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Eyes
                    Positioned(
                      top: 22,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Left Eye
                          Container(
                            width: 24,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Right Eye
                          Container(
                            width: 24,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Worried mouth
                    Positioned(
                      bottom: 18,
                      child: Container(
                        width: 28,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF422006),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Complaint Questions List (White Card with Shadow)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reasons.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF3F4F6),
                  ),
                  itemBuilder: (context, idx) {
                    final reason = _reasons[idx];
                    final isSelected = _selectedReason == reason;

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedReason = reason);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        color: isSelected
                            ? const Color(0xFFFFFBEB)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFFB800)
                                      : const Color(0xFFD1D5DB),
                                  width: 2,
                                ),
                                color: isSelected
                                    ? const Color(0xFFFFB800)
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.black,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            if (_selectedReason == "Other's") ...[
              const SizedBox(height: 14),
              TextField(
                controller: _otherController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Please describe your complaint...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFB800), width: 1.5),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 26),

            // 4. Submit & Confirm Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedReason == null || _isLoggingOut
                    ? null
                    : _processLogout,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFFFC000),
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  disabledForegroundColor: const Color(0xFF9CA3AF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isLoggingOut
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Submit & Logout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
