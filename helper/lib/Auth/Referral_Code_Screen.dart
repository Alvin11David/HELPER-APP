// referral_code_screen.dart
// ✅ Matches your design + keeps your required header structure (Stack + back button + centered logo)
// ✅ Glassmorphism pills + dashed OTP-style boxes (like your OTP screen)
// ✅ AbrilFatface for headings, Poppins for body

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  final int _codeLength = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(_codeLength, (_) => TextEditingController(text: ''));
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
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
                      border:
                          Border.all(color: Colors.white.withOpacity(0.35)),
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

                  SizedBox(height: screenHeight * 0.03),

                  // Code boxes (dashed like OTP feel)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_codeLength, (i) {
                        final boxW = screenWidth * 0.11;
                        final boxH = screenWidth * 0.15;

                        return _DashedCodeBox(
                          width: boxW,
                          height: boxH,
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          onChanged: (val) {
                            final v = val.trim();
                            if (v.isNotEmpty && i < _codeLength - 1) {
                              _controllers[i].text = v;
                              _focusNodes[i].unfocus();
                              _focusNodes[i + 1].requestFocus();
                            } else if (v.isEmpty && i > 0) {
                              _focusNodes[i].unfocus();
                              _focusNodes[i - 1].requestFocus();
                            }
                            setState(() {});
                          },
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

                  SizedBox(height: screenHeight * 0.02),

                  // How to use the code? (link)
                  GestureDetector(
                    onTap: _onHowToUse,
                    child: Text(
                      'How to use the code?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: screenWidth * 0.036,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.018),

                  // Glass note pill
                  _GlassPill(
                    width: screenWidth * 0.72,
                    radius: 30,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.010,
                    ),
                    child: Text(
                      'Your referral code can only be used once',
                      textAlign: TextAlign.center,
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
                            // TODO: navigate to sign in
                          },
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: _brandOrange,
                              fontSize: screenWidth * 0.032,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
      final len = (distance + dash < metrics.length) ? dash : metrics.length - distance;
      final extract = metrics.extractPath(distance, distance + len);
      canvas.drawPath(extract, paint);
      distance += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}
