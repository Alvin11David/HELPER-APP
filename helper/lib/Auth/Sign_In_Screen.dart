import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'OTP_Verification_Screen.dart';

class _UgandaPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the text is empty or doesn't start with "+256 ", reset to "+256 "
    if (newValue.text.isEmpty || !newValue.text.startsWith('+256 ')) {
      return const TextEditingValue(
        text: '+256 ',
        selection: TextSelection.collapsed(offset: 5),
      );
    }

    // Extract the digits after "+256 "
    final digitsOnly = newValue.text
        .substring(5)
        .replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 9 digits
    final limitedDigits = digitsOnly.length > 9
        ? digitsOnly.substring(0, 9)
        : digitsOnly;

    // Construct the final text
    final formattedText = '+256 $limitedDigits';

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) => false;
}

enum _AuthMode { phone, email }

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const _brandOrange = Color(0xFFFFA10D);
  static const _pureWhite = Color(0xFFFFFFFF);

  _AuthMode _mode = _AuthMode.phone;

  final _formKey = GlobalKey<FormState>();

  final _phoneCtrl = TextEditingController(text: '+256 ');
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  String? _verificationId; // For phone verification

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode m) {
    if (_mode == m) return;
    FocusScope.of(context).unfocus();
    setState(() => _mode = m);
  }

  String _generateOTP() {
    Random random = Random();
    return (100000 + random.nextInt(900000))
        .toString(); // Generates 6-digit code
  }

  Future<void> _onContinue() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    if (_mode == _AuthMode.phone) {
      // Check if phone number exists in Sign Up collection
      try {
        String phoneNumber = _phoneCtrl.text.trim();

        // Validate phone number format
        if (!phoneNumber.startsWith('+256 ') || phoneNumber.length != 14) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please enter a valid phone number in format +256 XXXXXXXXX',
              ),
            ),
          );
          setState(() => _loading = false);
          return;
        }

        // Remove space for Firebase Auth (should be +256XXXXXXXXX)
        phoneNumber = phoneNumber.replaceAll(' ', '');
        print('Formatted phone number: $phoneNumber');

        // Check if phone number is valid for Uganda
        if (!phoneNumber.startsWith('+256') || phoneNumber.length != 13) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid phone number format')),
          );
          setState(() => _loading = false);
          return;
        }

        // Check if user exists
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('Sign Up')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .get();

        if (userQuery.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number not found. Please sign up first.'),
            ),
          );
          setState(() => _loading = false);
          return;
        }

        // User exists, proceed with OTP verification
        // Send OTP via Firebase Auth (SMS)
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification (Android only)
            print('Auto-verification completed');
            // You can automatically sign in here if desired
          },
          verificationFailed: (FirebaseAuthException e) {
            print('Phone verification failed: ${e.message}');
            print('Error code: ${e.code}');
            print('Phone number attempted: $phoneNumber');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'SMS verification failed: ${e.message ?? "Unknown error"}',
                  ),
                ),
              );
              setState(() => _loading = false);
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            print('SMS code sent to $phoneNumber');
            _verificationId = verificationId;

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SMS sent to your phone!')),
              );

              // Navigate to OTP Verification Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OTPVerificationScreen(
                    isPhoneVerification: true,
                    emailOrPhone: phoneNumber,
                    initialVerificationId:
                        verificationId, // Pass verification ID
                  ),
                ),
              ).then((_) {
                // Reset loading when returning from verification screen
                if (mounted) setState(() => _loading = false);
              });
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            print('Auto-retrieval timeout');
            _verificationId = verificationId;
          },
          timeout: const Duration(seconds: 60),
        );

        // Don't set loading to false here - it will be handled in callbacks
        return;
      } catch (e) {
        // Handle error, maybe show a snackbar
        print('Error initiating phone verification: $e');
        print('Error type: ${e.runtimeType}');
        if (e is FirebaseAuthException) {
          print('Firebase Auth error code: ${e.code}');
          print('Firebase Auth error message: ${e.message}');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending SMS: ${e.toString()}')),
        );
        setState(() => _loading = false);
        return;
      }
    } else {
      // Check if email and password match in Sign Up collection
      try {
        String email = _emailCtrl.text.trim();
        String password = _passwordCtrl.text.trim();

        // Check if user exists with matching email and password
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('Sign Up')
            .where('email', isEqualTo: email)
            .where('password', isEqualTo: password)
            .get();

        if (userQuery.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid email or password. Please check your credentials.',
              ),
            ),
          );
          setState(() => _loading = false);
          return;
        }

        // User exists, proceed with OTP verification
        String otpCode = _generateOTP();

        // Generate and store OTP code
        await FirebaseFirestore.instance.collection('OTP Codes').doc(email).set(
          {
            'email': email,
            'otpCode': otpCode,
            'timestamp': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(minutes: 10)),
            ), // OTP expires in 10 minutes
          },
        );

        // Send OTP code to email address via Firebase Cloud Function
        try {
          final result = await FirebaseFunctions.instance
              .httpsCallable('sendOTPEmail')
              .call({'email': email, 'otpCode': otpCode});
          print('OTP email sent successfully: ${result.data}');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent to your email!')),
          );
        } catch (e) {
          print('Error sending OTP email: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send OTP email: $e')),
          );
          // Still proceed to verification screen, as OTP is stored
        }

        // Navigate to OTP Verification Screen
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              isPhoneVerification: false,
              emailOrPhone: email,
              initialVerificationId: '',
            ),
          ),
        );
        return;
      } catch (e) {
        // Handle error, maybe show a snackbar
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging in: $e')));
        setState(() => _loading = false);
        return;
      }
    }
  }

  void _onGoogle() {
    // TODO: google sign-in
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final sidePad = w * 0.045;

    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: sidePad),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: h * 0.02),

                      // Top bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/logo.png',
                            width: w * 0.09,
                            height: w * 0.09,
                          ),
                          SizedBox(width: w * 0.02),
                          Text(
                            'Helper',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: w * 0.05,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: h * 0.05),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.09,
                            fontFamily: 'AbrilFatface',
                            height: 1.05,
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.018),

                      _StepIndicator(
                        width: w,
                        activeIndex: 0,
                        labels: const [
                          'Phone/Email',
                          'Verify',
                          'Payment Details',
                        ],
                        accent: _brandOrange,
                      ),

                      SizedBox(height: h * 0.03),

                      _GlassPill(
                        radius: 30,
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.05,
                          vertical: h * 0.006,
                        ),
                        child: Text(
                          _mode == _AuthMode.phone
                              ? 'Enter your Phone Number'
                              : 'Enter your Email Address',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.02),

                      _SmoothAuthSwitch(
                        height: h * 0.065,
                        mode: _mode,
                        onChanged: _switchMode,
                      ),

                      SizedBox(height: h * 0.02),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) {
                          final slide =
                              Tween<Offset>(
                                begin: const Offset(0.02, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOut,
                                ),
                              );
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                        child: _mode == _AuthMode.phone
                            ? _PhoneBlock(
                                key: const ValueKey('phoneBlock'),
                                phoneCtrl: _phoneCtrl,
                              )
                            : _EmailBlock(
                                key: const ValueKey('emailBlock'),
                                emailCtrl: _emailCtrl,
                                passwordCtrl: _passwordCtrl,
                                obscure: _obscure,
                                onToggleObscure: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                      ),

                      SizedBox(height: h * 0.025),

                      // Continue (white)
                      SizedBox(
                        width: double.infinity,
                        height: h * 0.062,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pureWhite,
                            disabledBackgroundColor: _pureWhite.withOpacity(
                              0.6,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _loading
                              ? SizedBox(
                                  width: h * 0.03,
                                  height: h * 0.03,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.black,
                                  ),
                                )
                              : Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontSize: w * 0.045,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      SizedBox(width: w * 0.02),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.black,
                                        size: h * 0.035,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),

                      if (_mode == _AuthMode.email) ...[
                        SizedBox(height: h * 0.02),
                        _OrDivider(),
                        SizedBox(height: h * 0.02),

                        SizedBox(
                          width: double.infinity,
                          height: h * 0.062,
                          child: ElevatedButton(
                            onPressed: _onGoogle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pureWhite,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _GoogleIconSlot(size: w * 0.065),
                                SizedBox(width: w * 0.025),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: w * 0.042,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Inter',
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: h * 0.07),

                      if (_mode == _AuthMode.phone)
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: w * 0.045,
                              vertical: h * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              'Your phone number is safe and will not be shared. Standard SMS charges may apply.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: w * 0.032,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),

                      SizedBox(height: h * 0.03),
                    ],
                  ),
                ),
              ),

              // Back button overlay
              Positioned(
                top: h * 0.04,
                left: w * 0.04,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: w * 0.13,
                    height: w * 0.13,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.black,
                        size: w * 0.10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------- Blocks ---------------------

class _PhoneBlock extends StatelessWidget {
  final TextEditingController phoneCtrl;

  const _PhoneBlock({super.key, required this.phoneCtrl});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone Number
        Text(
          'Phone Number',
          style: TextStyle(
            color: Colors.white,
            fontSize: w * 0.040,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: h * 0.012),
        _PillInput(
          controller: phoneCtrl,
          hint: '+256 712345678',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [_UgandaPhoneFormatter()],
          contentFontSize: w * 0.038,
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Phone number is required';
            if (!t.startsWith('+256 '))
              return 'Phone number must start with +256';
            final digits = t.substring(5);
            if (digits.length != 9) return 'Enter exactly 9 digits after +256';
            if (!RegExp(r'^[0-9]{9}$').hasMatch(digits))
              return 'Enter valid 9-digit number';
            return null;
          },
        ),
        SizedBox(height: h * 0.014),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Referral Code?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: w * 0.035,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailBlock extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;

  const _EmailBlock({
    super.key,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email
        Text(
          'Email',
          style: TextStyle(
            color: Colors.white,
            fontSize: w * 0.040,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: h * 0.012),
        _PillInput(
          controller: emailCtrl,
          hint: 'Enter Your Email Address',
          icon: Icons.mail_rounded,
          keyboardType: TextInputType.emailAddress,
          contentFontSize: w * 0.038,
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Email is required';
            final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
            if (!ok) return 'Enter a valid email';
            return null;
          },
        ),
        SizedBox(height: h * 0.018),

        // Password
        Text(
          'Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: w * 0.040,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: h * 0.012),
        _PillInput(
          controller: passwordCtrl,
          hint: 'Enter Your Password',
          icon: Icons.lock_rounded,
          keyboardType: TextInputType.visiblePassword,
          obscure: obscure,
          contentFontSize: w * 0.038,
          suffix: IconButton(
            onPressed: onToggleObscure,
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          validator: (v) {
            final t = (v ?? '');
            if (t.trim().isEmpty) return 'Password is required';
            if (t.length < 6) return 'Min 6 characters';
            return null;
          },
        ),

        SizedBox(height: h * 0.014),
        Row(
          children: [
            Text(
              'Referral Code?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: w * 0.035,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                // TODO: forgot password
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: w * 0.035,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --------------------- Indicator / Switch ---------------------

class _StepIndicator extends StatelessWidget {
  final double width;
  final int activeIndex;
  final List<String> labels;
  final Color accent;

  const _StepIndicator({
    required this.width,
    required this.activeIndex,
    required this.labels,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final dot = width * 0.02;
    final lineW = width * 0.18;

    Widget dotW(bool active) {
      return Container(
        width: dot * 1.45,
        height: dot * 1.45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? accent : Colors.transparent,
          border: Border.all(color: accent, width: 2),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
      );
    }

    Widget dashed() {
      return SizedBox(
        width: lineW,
        child: CustomPaint(painter: DashedLinePainter(color: accent)),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            dotW(activeIndex >= 0),
            SizedBox(width: width * 0.02),
            dashed(),
            SizedBox(width: width * 0.02),
            dotW(activeIndex >= 1),
            SizedBox(width: width * 0.02),
            dashed(),
            SizedBox(width: width * 0.02),
            dotW(activeIndex >= 2),
          ],
        ),
        SizedBox(height: width * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (t) => Expanded(
                  child: Text(
                    t,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accent,
                      fontSize: width * 0.032,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SmoothAuthSwitch extends StatelessWidget {
  final double height;
  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

  const _SmoothAuthSwitch({
    required this.height,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final radius = height / 2;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentW = constraints.maxWidth / 2;

          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 230),
                curve: Curves.easeOut,
                alignment: mode == _AuthMode.phone
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: segmentW,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(radius),
                      onTap: () => onChanged(_AuthMode.phone),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: w * 0.06,
                              color: mode == _AuthMode.phone
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            SizedBox(width: w * 0.02),
                            Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: w * 0.044,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Inter',
                                color: mode == _AuthMode.phone
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(radius),
                      onTap: () => onChanged(_AuthMode.email),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mail_rounded,
                              size: w * 0.06,
                              color: mode == _AuthMode.email
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            SizedBox(width: w * 0.02),
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: w * 0.044,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Inter',
                                color: mode == _AuthMode.email
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// --------------------- Input ---------------------

class _PillInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  final double contentFontSize;

  const _PillInput({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    required this.contentFontSize,
    this.obscure = false,
    this.suffix,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final fieldH = h * 0.065;
    final radius = fieldH / 2;

    return Container(
      height: fieldH,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        children: [
          SizedBox(width: w * 0.04),
          Icon(icon, color: Colors.white, size: w * 0.06),
          SizedBox(width: w * 0.025),
          Container(
            width: 1.2,
            height: fieldH * 0.55,
            color: Colors.white.withOpacity(0.6),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              style: TextStyle(
                color: Colors.white,
                fontSize: contentFontSize,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
              cursorColor: const Color(0xFFFFA10D),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: contentFontSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.only(
                  top: fieldH * 0.20,
                  bottom: fieldH * 0.20,
                ),
              ),
            ),
          ),
          if (suffix != null)
            Padding(
              padding: EdgeInsets.only(right: w * 0.02),
              child: suffix!,
            )
          else
            SizedBox(width: w * 0.02),
        ],
      ),
    );
  }
}

// --------------------- OR divider ---------------------

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.25)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.03),
          child: Text(
            'Or',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: w * 0.035,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.25)),
        ),
      ],
    );
  }
}

// --------------------- Google icon slot (safe placeholder) ---------------------

class _GoogleIconSlot extends StatelessWidget {
  final double size;
  const _GoogleIconSlot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/google.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
    );
  }
}

// --------------------- Glass pill ---------------------

class _GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const _GlassPill({
    required this.child,
    required this.padding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: size * 0.45),
        ),
      ),
    );
  }
}
