import 'dart:ui';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:helper/Intro/Role_Selection_Screen.dart';
import 'package:helper/Amount.dart';
import 'package:url_launcher/url_launcher.dart';
import 'OTP_Verification_Screen.dart';
import 'Sign_In_Screen.dart';
import 'Referral_Code_Screen.dart';
import 'Forgot_Password_Screen.dart';

class _UgandaPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty || !newValue.text.startsWith('+256 ')) {
      return const TextEditingValue(
        text: '+256 ',
        selection: TextSelection.collapsed(offset: 5),
      );
    }

    final digitsOnly = newValue.text
        .substring(5)
        .replaceAll(RegExp(r'[^0-9]'), '');

    final limitedDigits = digitsOnly.length > 9
        ? digitsOnly.substring(0, 9)
        : digitsOnly;

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

class PhoneNumberEmailAddressScreen extends StatefulWidget {
  const PhoneNumberEmailAddressScreen({super.key});

  @override
  State<PhoneNumberEmailAddressScreen> createState() =>
      _PhoneNumberEmailAddressScreenState();
}

class _PhoneNumberEmailAddressScreenState
    extends State<PhoneNumberEmailAddressScreen> {
  static const _brandOrange = Color(0xFFFFA10D);
  static const _pureWhite = Color(0xFFFFFFFF);

  _AuthMode _mode = _AuthMode.phone;

  final _formKey = GlobalKey<FormState>();

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+256 ');
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String _referralCode =
      ''; // <-- Store referral code passed from ReferralCodeScreen

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture referral code from navigation arguments if provided
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['referralCode'] != null) {
      _referralCode = args['referralCode'] as String;
    }
  }

  void _switchMode(_AuthMode m) {
    if (_mode == m) return;
    FocusScope.of(context).unfocus();
    setState(() => _mode = m);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: Colors.black.withOpacity(0.85),
      ),
    );
  }

  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  String _generateReferralCode() {
    final random = Random();
    final digits1 = (100 + random.nextInt(900)).toString(); // 3 digits
    final letters = String.fromCharCodes([
      65 + random.nextInt(26), // A-Z
      65 + random.nextInt(26),
    ]);
    final digits2 = (100 + random.nextInt(900)).toString(); // 3 digits
    return 'UG$digits1$letters$digits2';
  }

  Future<void> _onContinue() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    if (_mode == _AuthMode.phone) {
      try {
        final fullName = _fullNameCtrl.text.trim();
        String phoneNumber = _phoneCtrl.text.trim();

        if (!phoneNumber.startsWith('+256 ') || phoneNumber.length != 14) {
          _toast('Please enter a valid phone number in format +256 XXXXXXXXX');
          setState(() => _loading = false);
          return;
        }

        // Convert "+256 712345678" -> "+256712345678"
        phoneNumber = phoneNumber.replaceAll(' ', '');

        if (!phoneNumber.startsWith('+256') || phoneNumber.length != 13) {
          _toast('Invalid phone number format');
          setState(() => _loading = false);
          return;
        }

        // ✅ Prevent duplicates (this checks if any verified user already has this phone)
        final already = await FirebaseFirestore.instance
            .collection('Sign Up')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .where('verified', isEqualTo: true)
            .limit(1)
            .get();

        if (already.docs.isNotEmpty) {
          _toast('Phone number already registered. Please sign in.');
          setState(() => _loading = false);
          return;
        }

        // Generate OTP
        final otpCode = _generateOTP();

        // Store OTP in 'OTP Codes' collection
        await FirebaseFirestore.instance
            .collection('OTP Codes')
            .doc(phoneNumber)
            .set({
              'phoneNumber': phoneNumber,
              'otpCode': otpCode,
              'timestamp': FieldValue.serverTimestamp(),
              'expiresAt': Timestamp.fromDate(
                DateTime.now().add(const Duration(minutes: 10)),
              ),
            });

        // Get FCM token
        final fcmToken = await FirebaseMessaging.instance.getToken();

        if (fcmToken != null) {
          try {
            // Send OTP via push notification
            await FirebaseFunctions.instance.httpsCallable('sendOTPPhone').call(
              {
                'phoneNumber': phoneNumber,
                'otpCode': otpCode,
                'fcmToken': fcmToken,
              },
            );
            _toast('OTP sent via push notification!');
          } catch (e) {
            _toast('Failed to send OTP push (OTP still saved).');
          }
        } else {
          _toast('Unable to get FCM token.');
        }

        // Navigate to OTP screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              isPhoneVerification: true,
              emailOrPhone: phoneNumber,
              verificationId: '', // empty for custom OTP
              fullName: fullName,
              password: '',
              referralCode: _referralCode, // <-- Pass the referral code
            ),
          ),
        ).then((_) {
          if (mounted) setState(() => _loading = false);
        });

        return;

        return;
      } catch (e) {
        _toast('Error sending SMS: $e');
        setState(() => _loading = false);
        return;
      }
    } else {
      // EMAIL SIGN UP
      try {
        final fullName = _fullNameCtrl.text.trim();
        final email = _emailCtrl.text.trim();
        final password = _passwordCtrl.text.trim();

        // ✅ prevent duplicates
        final already = await FirebaseFirestore.instance
            .collection('Sign Up')
            .where('email', isEqualTo: email)
            .where('verified', isEqualTo: true)
            .limit(1)
            .get();

        if (already.docs.isNotEmpty) {
          _toast('Email already registered. Please sign in.');
          setState(() => _loading = false);
          return;
        }

        final otpCode = _generateOTP();

        // ✅ Save OTP only (NOT Sign Up .add())
        await FirebaseFirestore.instance
            .collection('OTP Codes')
            .doc(email)
            .set({
              'email': email,
              'otpCode': otpCode,
              'timestamp': FieldValue.serverTimestamp(),
              'expiresAt': Timestamp.fromDate(
                DateTime.now().add(const Duration(minutes: 10)),
              ),
            });

        try {
          await FirebaseFunctions.instance.httpsCallable('sendOTPEmail').call({
            'email': email,
            'otpCode': otpCode,
          });
          if (!mounted) return;
          _toast('OTP sent to your email!');
        } catch (e) {
          if (!mounted) return;
          _toast('Failed to send OTP email (still saved OTP).');
        }

        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              isPhoneVerification: false,
              emailOrPhone: email,
              verificationId: '', // not used for email
              fullName: fullName,
              password: password,
              referralCode: _referralCode, // <-- Pass the referral code
            ),
          ),
        );
        return;
      } catch (e) {
        _toast('Error sending OTP: $e');
        setState(() => _loading = false);
        return;
      }
    }
  }

  // ==========================================================
  // ✅ GOOGLE SIGN UP / SIGN IN (ANDROID + WEB) using FirebaseAuth
  // Saves to Firestore "Sign Up" collection (provider="google")
  // Then navigates to WorkersDashboardScreen()
  // ==========================================================
  Future<void> _onGoogle() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      UserCredential userCred;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.setCustomParameters({'prompt': 'select_account'});
        userCred = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          setState(() => _loading = false);
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final user = userCred.user;
      if (user == null) throw Exception('Google sign-in failed (no user).');

      await _saveGoogleUserToFirestore(user);

      // Apply referral rewards if referral code is provided (Google signup)
      if (_referralCode.isNotEmpty) {
        await AmountService.applyReferralRewards(
          referredUserId: user.uid,
          referralCode: _referralCode,
        );
      }

      if (!mounted) return;
      setState(() => _loading = false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _toast('Google sign-in failed: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveGoogleUserToFirestore(User user) async {
    final col = FirebaseFirestore.instance.collection('Sign Up');

    final docRef = col.doc(user.uid);
    final snap = await docRef.get();

    // 🔒 Anti-fraud check: Prevent duplicate Google accounts with referral code
    if (_referralCode.isNotEmpty) {
      final email = user.email ?? '';
      if (email.isNotEmpty) {
        final existingEmail = await col
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (existingEmail.docs.isNotEmpty) {
          throw Exception(
            'This email has already been registered. Each email can only be invited once.',
          );
        }
      }
    }

    // Get FCM token
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      // Handle error if needed, but continue without FCM token
      fcmToken = null;
    }

    final payload = <String, dynamic>{
      'uid': user.uid,
      'provider': 'google',
      'email': user.email ?? '',
      'fullName': user.displayName ?? '',
      'photoUrl': user.photoURL ?? '',
      'phoneNumber': user.phoneNumber ?? '',
      'role': '',
      'referralCode': _referralCode.isNotEmpty
          ? _referralCode
          : _generateReferralCode(),
      'verified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (fcmToken != null) {
      payload['fcmToken'] = fcmToken;
    }

    if (!snap.exists) {
      await docRef.set({...payload, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await docRef.set(payload, SetOptions(merge: true));
    }
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
                            'C-Helper',
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
                          'Get Started Now',
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
                                fullNameCtrl: _fullNameCtrl,
                                phoneCtrl: _phoneCtrl,
                              )
                            : _EmailBlock(
                                key: const ValueKey('emailBlock'),
                                fullNameCtrl: _fullNameCtrl,
                                emailCtrl: _emailCtrl,
                                passwordCtrl: _passwordCtrl,
                                obscure: _obscure,
                                onToggleObscure: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                      ),

                      SizedBox(height: h * 0.014),

                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ReferralCodeScreen(),
                                ),
                              );
                              if (result != null && result.isNotEmpty) {
                                setState(() {
                                  _referralCode = result;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Referral code accepted: $result',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      backgroundColor: Colors.black.withOpacity(
                                        0.85,
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.card_giftcard,
                                  color: Colors.white.withOpacity(0.85),
                                  size: w * 0.045,
                                ),
                                SizedBox(width: w * 0.018),
                                Text(
                                  'Use Referral Code',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: w * 0.035,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotYourPasswordScreen(),
                                ),
                              );
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

                      SizedBox(height: h * 0.025),

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
                              : Row(
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

                      if (_mode == _AuthMode.email) ...[
                        SizedBox(height: h * 0.02),
                        _OrDivider(),
                        SizedBox(height: h * 0.02),

                        SizedBox(
                          width: double.infinity,
                          height: h * 0.062,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _onGoogle,
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: w * 0.037,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: w * 0.02),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignInScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: _brandOrange,
                                fontSize: w * 0.032,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: h * 0.03),
                    ],
                  ),
                ),
              ),

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

              // --- Download App Button (Visible on Web) ---
              if (kIsWeb)
                Positioned(
                  top: 50,
                  right: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async {
                            // Pointing to the file you will place in the 'web' folder
                            const url =
                                'https://helperapp-46849.web.app/app-release.apk';
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              _toast('Could not launch download link');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _brandOrange,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.android,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Download the App',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9.5,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Small text below the button, only on web
                      Text(
                        'Download the apk for better performance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
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
  final TextEditingController fullNameCtrl;
  final TextEditingController phoneCtrl;

  const _PhoneBlock({
    super.key,
    required this.fullNameCtrl,
    required this.phoneCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Names',
          style: TextStyle(
            color: Colors.white,
            fontSize: w * 0.040,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: h * 0.012),
        _PillInput(
          controller: fullNameCtrl,
          hint: 'Enter Your Full Names',
          icon: Icons.person_rounded,
          keyboardType: TextInputType.name,
          contentFontSize: w * 0.038,
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Full names are required';
            if (t.length < 3) return 'Enter valid names';
            return null;
          },
        ),
        SizedBox(height: h * 0.018),
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
            if (!t.startsWith('+256 ')) {
              return 'Phone number must start with +256';
            }
            final digits = t.substring(5);
            if (digits.length != 9) return 'Enter exactly 9 digits after +256';
            if (!RegExp(r'^[0-9]{9}$').hasMatch(digits)) {
              return 'Enter valid 9-digit number';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _EmailBlock extends StatelessWidget {
  final TextEditingController fullNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;

  const _EmailBlock({
    super.key,
    required this.fullNameCtrl,
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
        Text(
          'Full Names',
          style: TextStyle(
            color: Colors.white,
            fontSize: w * 0.040,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: h * 0.012),
        _PillInput(
          controller: fullNameCtrl,
          hint: 'Enter Your Full Names',
          icon: Icons.person_rounded,
          keyboardType: TextInputType.name,
          contentFontSize: w * 0.038,
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Full names are required';
            if (t.length < 3) return 'Enter valid names';
            return null;
          },
        ),
        SizedBox(height: h * 0.018),
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

// --------------------- Google icon slot ---------------------

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
