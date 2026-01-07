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

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final int _otpLength = 6;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _otpLength,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(_otpLength, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _checkOTPAndNavigate() {
    String otp = _controllers.map((controller) => controller.text).join();
    if (otp.length == _otpLength) {
      // TODO: Add your OTP verification logic here
      print('OTP entered: $otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
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
                padding: EdgeInsets.only(right: screenWidth * 0.1),
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
              // Page Indicator with Text Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Active indicator - Phone
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.012,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFA10D),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFFA10D).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      'Phone',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  // Inactive indicator - Verify
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.012,
                    ),
                    child: Text(
                      'Verify',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  // Inactive indicator - Payment
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.012,
                    ),
                    child: Text(
                      'Payment',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
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
                        'Enter the 6-digit code sent to your',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                        ),
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
                                color: Colors.black,
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
                                } else if (trimmedValue.isEmpty &&
                                    otpIndex > 0) {
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
            ],
          ),
        ),
      ),
    );
  }
}
