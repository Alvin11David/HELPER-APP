// referral_code_screen.dart
// ✅ Matches your design + keeps your required header structure (Stack + back button + centered logo)
// ✅ Glassmorphism pills + dashed OTP-style boxes (like your OTP screen)
// ✅ AbrilFatface for headings, Poppins for body

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class ReferralCodeScreen extends StatefulWidget {
  const ReferralCodeScreen({super.key});

  @override
  State<ReferralCodeScreen> createState() => _ReferralCodeScreenState();
}

class _ReferralCodeScreenState extends State<ReferralCodeScreen> {
  static const _brandOrange = Color(0xFFFFA10D);
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  int _countdown = 60;
  final int _otpLength = 6;
  bool _showOverlay = false;
  final Duration _overlayAnimDuration = const Duration(milliseconds: 360);

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _otpLength,
      (_) => TextEditingController(text: ''),
    );
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _startCountdown();
  }

  void _checkOTPAndNavigate() {
    String otp = _controllers.map((controller) => controller.text).join();
    if (otp.length == _otpLength && !_showOverlay) {
      setState(() {
        _showOverlay = true;
      });
      // TODO: Add your OTP verification logic here
      // print('OTP entered: $otp');
    }
  }

  void _resendOTP() {
    if (_isButtonEnabled && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      // TODO: Add your resend OTP logic here
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _startCountdown();
          // Clear OTP fields
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        }
      });
    }
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

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  String get _refCode => _controllers.map((e) => e.text).join();

  void _onShare() {
    // TODO: share referral code
    // print(_refCode);
  }

  void _onSkip() {
    // TODO: navigate next
  }

  void _onHowToUse() {
    // TODO: show instructions / open modal
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final double baseHorizontalPadding = 16;
    final double sheetWidth = math.min(
      359,
      screenWidth - (baseHorizontalPadding * 2),
    );
    final double sheetHeight = math.min(502, screenHeight * 0.75);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/normalscreenbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Back button (required structure)
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

              // Skip (top right)
              Positioned(
                top: screenHeight * 0.055,
                right: screenWidth * 0.06,
                child: GestureDetector(
                  onTap: _onSkip,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.006,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.035,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              // Main content
              Column(
                children: [
                  SizedBox(height: screenHeight * 0.03),

                  // Center logo (required structure)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/logo.png',
                        width: screenWidth * 0.08,
                        height: screenWidth * 0.08,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Text(
                        'Helper',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.035),

                  // Heading (Abril Fatface)
                  Padding(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.06,
                      right: screenWidth * 0.20,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Enter\nreferral code and\nearn rewards after\nregistration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.085,
                          fontFamily: 'AbrilFatface',
                          height: 1.05,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Glass label: "Your referral code is:"
                  _GlassPill(
                    width: screenWidth * 0.52,
                    radius: 30,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.009,
                    ),
                    child: Text(
                      'Your referral code is:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: screenWidth * 0.035,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
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
                            border: Border.all(color: Colors.white, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Positioned(
                                bottom: screenWidth * 0.035,
                                child: Container(
                                  width: otpBoxWidth * 0.75,
                                  height: 1.4,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              Center(
                                child: SizedBox(
                                  width: otpBoxWidth * 0.55,
                                  child: TextField(
                                    controller: _controllers[otpIndex],
                                    focusNode: _focusNodes[otpIndex],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.08,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (value) {
                                      if (value.length == 1 &&
                                          otpIndex < _otpLength - 1) {
                                        _focusNodes[otpIndex + 1]
                                            .requestFocus();
                                      } else if (value.isEmpty &&
                                          otpIndex > 0) {
                                        _focusNodes[otpIndex - 1]
                                            .requestFocus();
                                      }

                                      _checkOTPAndNavigate();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  // Share button (white)
                  SizedBox(
                    width: screenWidth * 0.88,
                    height: screenHeight * 0.062,
                    child: ElevatedButton(
                      onPressed: _onShare,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Share',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Icon(
                            Icons.share_rounded,
                            color: Colors.black,
                            size: screenHeight * 0.032,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  // How to use the code? (link)
                  GestureDetector(
                    onTap: _onHowToUse,
                    child: Text(
                      'How to use the code?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: screenWidth * 0.036,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  // Glass note pill
                  _GlassPill(
                    width: screenWidth * 0.9,
                    radius: 30,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.010,
                    ),
                    child: Text(
                      'Your referral code can only be used once',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: screenWidth * 0.033,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom sign-in line
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.03),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: screenWidth * 0.036,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SignInScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: _brandOrange,
                              fontSize: screenWidth * 0.032,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Dim background overlay
              IgnorePointer(
                ignoring: !_showOverlay,
                child: AnimatedOpacity(
                  duration: _overlayAnimDuration,
                  curve: Curves.easeInOut,
                  opacity: _showOverlay ? 0.55 : 0.0,
                  child: Container(color: Colors.black),
                ),
              ),

              // Sliding white rectangle
              AnimatedPositioned(
                duration: _overlayAnimDuration,
                curve: Curves.easeOutCubic,
                left: baseHorizontalPadding,
                right: baseHorizontalPadding,
                bottom: _showOverlay
                    ? (baseHorizontalPadding + bottomInset)
                    : -(sheetHeight + 40),
                child: AnimatedOpacity(
                  duration: _overlayAnimDuration,
                  curve: Curves.easeInOut,
                  opacity: _showOverlay ? 1.0 : 0.0,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: sheetWidth,
                      height: sheetHeight,
                      padding: EdgeInsets.fromLTRB(
                        baseHorizontalPadding,
                        0,
                        baseHorizontalPadding,
                        baseHorizontalPadding + bottomInset,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.0),
                          Stack(
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              Image.asset(
                                'assets/images/pop.png',
                                width: screenWidth * 1.1,
                                fit: BoxFit.contain,
                              ),
                              Positioned(
                                top: 0,
                                child: Image.asset(
                                  'assets/images/celebration.png',
                                  width: screenWidth * 0.4,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.0),
                          Text(
                            'Congratulations',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenWidth * 0.065,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'you have earned',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenWidth * 0.045,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'UGX 2,500/ & 0.5',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFDF8800),
                              fontSize: screenWidth * 0.055,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.08,
                            ),
                            child: Text(
                              'You have earned yourself a prize of\nUGX 1,000 approximate to \$ 0.5 for using\nthe referral code',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.035,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.07),
                          SizedBox(
                            width: double.infinity,
                            height: screenHeight * 0.062,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      // TODO: Handle continue action
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDF8800),
                                disabledBackgroundColor: const Color(
                                  0xFFDF8800,
                                ).withOpacity(0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: screenHeight * 0.03,
                                      height: screenHeight * 0.03,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Continue',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.045,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.02),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: screenHeight * 0.035,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          // Add more content here as needed
                        ],
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

// ---------------------- Widgets ----------------------

class _GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double width;

  const _GlassPill({
    required this.child,
    required this.padding,
    required this.radius,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: width,
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.22),
                  Colors.white.withOpacity(0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.08),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _DashedCodeBox extends StatelessWidget {
  final double width;
  final double height;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _DashedCodeBox({
    required this.width,
    required this.height,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: Colors.white.withOpacity(0.9),
        strokeWidth: 2,
        dash: 6,
        gap: 4,
        radius: 10,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            maxLength: 1,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            ],
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              color: Colors.white,
              fontSize: width * 0.55,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              height: 1.0,
            ),
            cursorColor: const Color(0xFFFFA10D),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

// Dashed border painter (for the code boxes)
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    double distance = 0;

    while (distance < metrics.length) {
      final len = (distance + dash < metrics.length)
          ? dash
          : metrics.length - distance;
      final extract = metrics.extractPath(distance, distance + len);
      canvas.drawPath(extract, paint);
      distance += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}
