import 'dart:async';
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

  int _countdown = 60;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _otpLength,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(_otpLength, (index) => FocusNode());
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
              Column(
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
                        border: Border.all(color: Color(0xFFFFFFFF), width: 1),
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
                              fontFamily: 'AbrilFatface',
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
                            ),
                          ),
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
