import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:helper/Payments/Registration_Payment_Screen.dart';
import 'Sign_In_Screen.dart';

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

class OTPVerificationScreen extends StatefulWidget {
  final bool isPhoneVerification; // true for phone, false for email
  final String? emailOrPhone; // Email or phone number
  final String verificationId; // ✅ for phone only (passed from signup/signin)
  final String fullName; // ✅ passed from signup (or '' if signin)
  final String password; // ✅ for email signup only (or '')

  const OTPVerificationScreen({
    super.key,
    required this.isPhoneVerification,
    required this.emailOrPhone,
    required this.verificationId,
    required this.fullName,
    required this.password,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  static const _brandOrange = Color(0xFFFFA10D);
  final int _otpLength = 6;

  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  int _countdown = 60;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  bool _verifying = false;

  Timer? _timer;

  String? _verificationId; // for phone
  String get otp => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());

    _verificationId = widget.verificationId;
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
      _isButtonEnabled = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        setState(() => _isButtonEnabled = true);
        timer.cancel();
      }
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _generateOTP() {
    // 6-digit OTP (simple)
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
  }

  // ✅ PHONE RESEND: use FirebaseAuth.verifyPhoneNumber (do NOT use "OTP Codes" or sendSMSOTP)
  Future<void> _resendPhoneOTP() async {
    final phone = widget.emailOrPhone;
    if (phone == null || phone.trim().isEmpty) {
      _snack('Missing phone number.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Keep user flow manual
        },
        verificationFailed: (FirebaseAuthException e) {
          _snack('Resend failed: ${e.message ?? e.code}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
          });
          _snack('OTP resent to your phone.');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );

      _startCountdown();
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    } catch (e) {
      _snack('Error resending OTP: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ EMAIL RESEND: regenerate OTP in Firestore + call sendOTPEmail
  Future<void> _resendEmailOTP() async {
    final email = widget.emailOrPhone;
    if (email == null || email.trim().isEmpty) {
      _snack('Missing email.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final otpCode = _generateOTP();

      await FirebaseFirestore.instance.collection('OTP Codes').doc(email).set({
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
        _snack('OTP email resent successfully!');
      } catch (e) {
        _snack('Failed to send OTP email (OTP still saved).');
      }

      _startCountdown();
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    } catch (e) {
      _snack('Error resending OTP: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resendOTP() async {
    if (!(_isButtonEnabled && !_isLoading)) return;

    if (widget.isPhoneVerification) {
      await _resendPhoneOTP();
    } else {
      await _resendEmailOTP();
    }
  }

  Future<void> _writeUserProfileDoc({
    required User user,
    required String provider,
    required String fullName,
    String email = '',
    String phoneNumber = '',
    String photoUrl = '',
  }) async {
    final doc = FirebaseFirestore.instance.collection('Sign Up').doc(user.uid);

    await doc.set({
      'uid': user.uid,
      'provider': provider,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'verified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ensure createdAt exists once
    final snap = await doc.get();
    final data = snap.data();
    if (data == null || !data.containsKey('createdAt')) {
      await doc.set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    }
  }

  Future<void> _cleanupOTPDoc(String key) async {
    await FirebaseFirestore.instance.collection('OTP Codes').doc(key).delete().catchError((_) {});
  }

  Future<void> _checkOTPAndNavigate() async {
    if (_verifying) return;

    final code = otp;
    if (code.length != _otpLength) return;

    final key = widget.emailOrPhone;
    if (key == null || key.trim().isEmpty) return;

    setState(() {
      _verifying = true;
    });

    try {
      if (widget.isPhoneVerification) {
        // =========================
        // PHONE: Firebase Auth OTP
        // =========================
        final vid = _verificationId;
        if (vid == null || vid.isEmpty) {
          _snack('No verification ID. Please resend OTP.');
          return;
        }

        final credential = PhoneAuthProvider.credential(
          verificationId: vid,
          smsCode: code,
        );

        final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
        final user = userCred.user;

        if (user == null) {
          throw Exception('Phone sign-in failed (no user).');
        }

        final fullName = widget.fullName.trim();
        if (fullName.isNotEmpty) {
          // optional (nice for profile)
          await user.updateDisplayName(fullName);
        }

        await _writeUserProfileDoc(
          user: user,
          provider: 'phone',
          fullName: fullName.isNotEmpty ? fullName : (user.displayName ?? ''),
          phoneNumber: key,
          email: user.email ?? '',
          photoUrl: user.photoURL ?? '',
        );

        if (!mounted) return;
        _snack('Phone number verified successfully!');

        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const RegistrationPaymentScreen()),
        );
        return;
      }

      // =========================
      // EMAIL: Firestore OTP check
      // then create FirebaseAuth user
      // =========================
      final otpDoc = await FirebaseFirestore.instance.collection('OTP Codes').doc(key).get();

      if (!otpDoc.exists) {
        _snack('OTP not found. Please request a new one.');
        return;
      }

      final storedOTP = (otpDoc.data()?['otpCode'] ?? '').toString();
      final expiresAt = otpDoc.data()?['expiresAt'];

      if (expiresAt is Timestamp) {
        if (expiresAt.toDate().isBefore(DateTime.now())) {
          _snack('OTP has expired. Please request a new one.');
          return;
        }
      }

      if (code != storedOTP) {
        _snack('Invalid OTP. Please try again.');
        return;
      }

      final email = key.trim();
      final password = widget.password.trim();
      if (password.isEmpty) {
        _snack('Missing signup password. Please sign up again.');
        return;
      }

      UserCredential userCred;

      try {
        // Normal signup path
        userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        // If user already exists, try sign in (prevents getting stuck)
        if (e.code == 'email-already-in-use') {
          userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final user = userCred.user;
      if (user == null) throw Exception('Email auth failed (no user).');

      final fullName = widget.fullName.trim();
      if (fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
      }

      await _writeUserProfileDoc(
        user: user,
        provider: 'email',
        fullName: fullName,
        email: email,
        phoneNumber: '',
        photoUrl: user.photoURL ?? '',
      );

      await _cleanupOTPDoc(email);

      if (!mounted) return;
      _snack('OTP verified successfully!');

      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const RegistrationPaymentScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _snack('Auth error: ${e.message ?? e.code}');
    } catch (e) {
      _snack('Error verifying OTP: $e');
    } finally {
      if (mounted) {
        setState(() {
          _verifying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

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
              Positioned(
                top: screenHeight * 0.04,
                left: screenWidth * 0.04,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: screenWidth * 0.13,
                    height: screenWidth * 0.13,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.black,
                        size: screenWidth * 0.10,
                      ),
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.05),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/logo.png',
                          width: screenWidth * 0.09,
                          height: screenWidth * 0.09,
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Text(
                          'Helper',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.15),
                      child: Text(
                        'Let\'s get you verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.08,
                          fontFamily: 'AbrilFatface',
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    _MiniStep123(
                      width: w,
                      accent: _brandOrange,
                      activeIndex: 0,
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.06,
                              vertical: screenHeight * 0.006,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.isPhoneVerification
                                  ? 'Enter the 6-digit code sent to ${widget.emailOrPhone?.replaceFirst('+256', '+256 ')}'
                                  : 'Enter the 6-digit code sent to your email',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.05),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_otpLength + 1, (index) {
                          if (index == 3) {
                            return Container(
                              width: screenWidth * 0.015,
                              height: screenWidth * 0.015,
                              margin: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.025,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            );
                          }

                          final otpIndex = index > 3 ? index - 1 : index;
                          final otpBoxWidth = screenWidth * 0.12;
                          final otpBoxHeight = screenWidth * 0.19;

                          return Container(
                            width: otpBoxWidth,
                            height: otpBoxHeight,
                            margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.01,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Positioned(
                                  bottom: otpBoxHeight * 0.15,
                                  child: Container(
                                    width: otpBoxWidth * 0.5,
                                    height: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                Center(
                                  child: TextFormField(
                                    controller: _controllers[otpIndex],
                                    focusNode: _focusNodes[otpIndex],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(1),
                                    ],
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                      height: 1.0,
                                    ),
                                    cursorColor: const Color(0xFFD59A00),
                                    onChanged: (value) {
                                      final trimmedValue = value.trim();
                                      if (trimmedValue.isNotEmpty &&
                                          otpIndex < _otpLength - 1) {
                                        _controllers[otpIndex].text = trimmedValue;
                                        _focusNodes[otpIndex].unfocus();
                                        _focusNodes[otpIndex + 1].requestFocus();
                                      } else if (trimmedValue.isEmpty && otpIndex > 0) {
                                        _focusNodes[otpIndex].unfocus();
                                        _focusNodes[otpIndex - 1].requestFocus();
                                      }
                                      _checkOTPAndNavigate();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.09),

                    GestureDetector(
                      onTap: (_isButtonEnabled && !_isLoading) ? _resendOTP : null,
                      child: Container(
                        width: screenWidth * 0.8,
                        height: screenHeight * 0.06,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isButtonEnabled && !_isLoading
                                ? [Colors.transparent, Colors.transparent]
                                : [Colors.white, Colors.white],
                            stops: const [0.0, 0.47],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: const Border.fromBorderSide(
                            BorderSide(color: Color(0xFFFFFFFF), width: 1),
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh,
                              color: (_isButtonEnabled && !_isLoading)
                                  ? Colors.white
                                  : Colors.black,
                              size: screenWidth * 0.06,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Text(
                              _countdown > 0 ? '$_countdown' : 'Resend',
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                                color: (_isButtonEnabled && !_isLoading)
                                    ? Colors.white
                                    : Colors.black,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.06),

                    Center(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already have an account ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SignInScreen(),
                                    ),
                                  );
                                },
                            ),
                          ],
                        ),
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

extension on Function() {
  get length => null;
}

class _MiniStep123 extends StatelessWidget {
  final double width;
  final Color accent;
  final int activeIndex; // 0 -> step 1 is active

  const _MiniStep123({
    required this.width,
    required this.accent,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final dotSize = width * 0.04;
    final lineW = width * 0.18;

    Widget circle(int index) {
      final active = index == activeIndex;
      return Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? accent : Colors.transparent,
          border: Border.all(color: accent, width: 3),
        ),
      );
    }

    Widget dashed() {
      return SizedBox(
        width: lineW,
        child: CustomPaint(painter: DashedLinePainter(color: accent)),
      );
    }

    Widget num(String n) {
      return Text(
        n,
        style: TextStyle(
          color: accent,
          fontSize: width * 0.03,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Transform.translate(
              offset: Offset(0, -width * 0.01),
              child: circle(0),
            ),
            SizedBox(height: width * 0.01),
            num('Phone'),
          ],
        ),
        SizedBox(width: width * 0.02),
        Column(children: [dashed()]),
        SizedBox(width: width * 0.02),
        Column(
          children: [
            Transform.translate(
              offset: Offset(0, -width * 0.01),
              child: circle(1),
            ),
            SizedBox(height: width * 0.01),
            num('Verify'),
          ],
        ),
        SizedBox(width: width * 0.02),
        Column(children: [dashed()]),
        SizedBox(width: width * 0.02),
        Column(
          children: [
            Transform.translate(
              offset: Offset(0, -width * 0.01),
              child: circle(2),
            ),
            SizedBox(height: width * 0.01),
            num('Payment'),
          ],
        ),
      ],
    );
  }
}
