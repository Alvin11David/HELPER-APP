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
  final String? emailOrPhone; // Email or phone number for OTP verification
  const OTPVerificationScreen({
    super.key,
    this.isPhoneVerification = true, // default to phone
    this.emailOrPhone, required String initialVerificationId,
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
  Timer? _timer;
  String? _verificationId; // For Firebase phone auth

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _otpLength,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(_otpLength, (index) => FocusNode());
    if (widget.isPhoneVerification && widget.emailOrPhone != null) {
      _startPhoneVerification(widget.emailOrPhone!);
    }
    _startCountdown();
  }

  void _startPhoneVerification(String phoneNumber) async {
    setState(() => _isLoading = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval or instant verification
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RegistrationPaymentScreen(),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Auto-verification failed: $e')),
            );
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
        }
        setState(() => _isLoading = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent to your phone.')),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
        });
      },
    );
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
      _isButtonEnabled = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _isButtonEnabled = true;
        });
        timer.cancel();
      }
    });
  }

  String _generateOTP() {
    // Generate a 6-digit OTP
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString();
  }

  void _resendOTP() async {
    if (_isButtonEnabled && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (widget.isPhoneVerification && widget.emailOrPhone != null) {
          // Generate OTP for phone
          String otpCode = _generateOTP();
          // Update OTP in Firestore
          await FirebaseFirestore.instance
              .collection('OTP Codes')
              .doc(widget.emailOrPhone!)
              .set({
                'phone': widget.emailOrPhone!,
                'otpCode': otpCode,
                'timestamp': FieldValue.serverTimestamp(),
                'expiresAt': Timestamp.fromDate(
                  DateTime.now().add(const Duration(minutes: 10)),
                ),
              });
          // Send SMS via Cloud Function
          try {
            final result = await FirebaseFunctions.instance
                .httpsCallable('sendSMSOTP')
                .call({'phone': widget.emailOrPhone!, 'otpCode': otpCode});
            print('SMS OTP resent successfully');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SMS resent successfully!')),
              );
            }
          } catch (e) {
            print('Error resending SMS OTP: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to resend SMS: $e')),
              );
            }
          }
        } else if (!widget.isPhoneVerification && widget.emailOrPhone != null) {
          // Resend email OTP
          String otpCode = _generateOTP();

          // Update OTP in Firestore
          await FirebaseFirestore.instance
              .collection('OTP Codes')
              .doc(widget.emailOrPhone!)
              .set({
                'email': widget.emailOrPhone!,
                'otpCode': otpCode,
                'timestamp': FieldValue.serverTimestamp(),
                'expiresAt': Timestamp.fromDate(
                  DateTime.now().add(const Duration(minutes: 10)),
                ),
              });

          // Send email via Cloud Function
          try {
            final result = await FirebaseFunctions.instance
                .httpsCallable('sendOTPEmail')
                .call({'email': widget.emailOrPhone!, 'otpCode': otpCode});
            print('OTP email resent successfully');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('OTP email resent successfully!')),
              );
            }
          } catch (e) {
            print('Error resending OTP email: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to resend OTP email: $e')),
              );
            }
          }
        }

        if (mounted) {
          _startCountdown();
          // Clear OTP fields
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        }
      } catch (e) {
        print('Error resending OTP: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error resending OTP: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _checkOTPAndNavigate() async {
    String otp = _controllers.map((controller) => controller.text).join();
    if (otp.length == _otpLength && widget.emailOrPhone != null) {
      try {
        if (widget.isPhoneVerification) {
          // Use Firebase phone auth
          if (_verificationId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No verification ID. Please resend OTP.'),
              ),
            );
            return;
          }
          final credential = PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: otp,
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Phone number verified successfully!'),
              ),
            );
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RegistrationPaymentScreen(),
              ),
            );
          }
        } else {
          // Email verification using stored OTP (unchanged)
          DocumentSnapshot otpDoc = await FirebaseFirestore.instance
              .collection('OTP Codes')
              .doc(widget.emailOrPhone!)
              .get();

          if (otpDoc.exists) {
            String storedOTP = otpDoc['otpCode'];
            Timestamp expiresAt = otpDoc['expiresAt'];

            // Check if OTP is expired
            if (expiresAt.toDate().isBefore(DateTime.now())) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('OTP has expired. Please request a new one.'),
                  ),
                );
              }
              return;
            }

            // Check if entered OTP matches stored OTP
            if (otp == storedOTP) {
              // OTP is correct - update user data to mark as verified
              QuerySnapshot userDocs = await FirebaseFirestore.instance
                  .collection('Sign Up')
                  .where('email', isEqualTo: widget.emailOrPhone!)
                  .where('verified', isEqualTo: false)
                  .get();

              if (userDocs.docs.isNotEmpty) {
                await userDocs.docs.first.reference.update({'verified': true});
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('OTP verified successfully!')),
                );
                print('OTP verified successfully for: ${widget.emailOrPhone}');
                // Navigate to RegistrationPaymentScreen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RegistrationPaymentScreen(),
                  ),
                );
              }
            } else {
              // OTP is incorrect
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid OTP. Please try again.'),
                  ),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('OTP not found. Please request a new one.'),
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error verifying OTP: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

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
                    // ✅ circle #1 filled orange
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
                          // Add separator after 3rd box
                          if (index == 3) {
                            return Container(
                              width: screenWidth * 0.015,
                              height: screenWidth * 0.015,
                              margin: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.025,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            );
                          }

                          // Calculate actual OTP box index
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
                                        _controllers[otpIndex].text =
                                            trimmedValue;
                                        _focusNodes[otpIndex].unfocus();
                                        _focusNodes[otpIndex + 1]
                                            .requestFocus();
                                      } else if (trimmedValue.isEmpty &&
                                          otpIndex > 0) {
                                        _focusNodes[otpIndex].unfocus();
                                        _focusNodes[otpIndex - 1]
                                            .requestFocus();
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
                      onTap: (_isButtonEnabled && !_isLoading)
                          ? _resendOTP
                          : null,
                      child: Container(
                        width: screenWidth * 0.8,
                        height: screenHeight * 0.06,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isButtonEnabled && !_isLoading
                                ? [Colors.transparent, Colors.transparent]
                                : [Colors.white, Colors.white],
                            stops: [0.0, 0.47],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Color(0xFFFFFFFF),
                            width: 1,
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
          color: active ? accent : Colors.transparent, // ✅ fill active
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
