import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'Sign_In_Screen.dart';

class PasswordResetScreen extends StatefulWidget {
  final String? email;
  const PasswordResetScreen({super.key, this.email});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  TextEditingController? _passwordCtrl;
  TextEditingController? _confirmCtrl;
  bool? _obscurePass;
  bool? _obscureConfirm;
  bool _loading = false;

  Future<void> _onContinue() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    // TODO: implement actual password reset flow
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _passwordCtrl?.dispose();
    _confirmCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure controller exists even after hot reload preserving old State
    _passwordCtrl ??= TextEditingController();
    _confirmCtrl ??= TextEditingController();
    _obscurePass ??= true;
    _obscureConfirm ??= true;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    const brandOrange = Color(0xFFFFA10D);

    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/normalscreenbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
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
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.03),
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
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.02),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Password Reset',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.08,
                            fontFamily: 'AbrilFatface',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: h * 0.023),
                    _StepIndicator(
                      width: w,
                      activeIndex: 0,
                      labels: const ['1', '2', '3'],
                      accent: brandOrange,
                    ),
                    SizedBox(height: screenHeight * 0.03),
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
                              'Create a new password for your account',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        SizedBox(height: h * 0.04),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: w * 0.04,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        SizedBox(height: h * 0.02),
                        // Use named arguments here
                        _PillInput(
                          null,
                          controller: _passwordCtrl!,
                          hint: 'Enter Your Password',
                          icon: Icons.lock_rounded,
                          keyboardType: TextInputType.visiblePassword,
                          contentFontSize: 16,
                          obscure: _obscurePass!,
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass!),
                            icon: Icon(
                              _obscurePass!
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(height: h * 0.04),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Confirm Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: w * 0.04,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        SizedBox(height: h * 0.02),
                        _PillInput(
                          null,
                          controller: _confirmCtrl!,
                          hint: 'Confirm Your Password',
                          icon: Icons.lock_rounded,
                          keyboardType: TextInputType.visiblePassword,
                          contentFontSize: 16,
                          obscure: _obscureConfirm!,
                          suffix: IconButton(
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm!,
                            ),
                            icon: Icon(
                              _obscureConfirm!
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.05),

                    // Continue (white)
                    SizedBox(
                      width: double.infinity,
                      height: h * 0.062,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white.withOpacity(
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
                                      'Change Password',
                                      style: TextStyle(
                                        fontSize: w * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontFamily: 'Poppins',
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
    final dotBox = dot * 1.45; // keep number width equal to dot container
    final spacer = width * 0.02; // same spacer used above between items
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

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
            SizedBox(width: spacer),
            dashed(),
            SizedBox(width: spacer),
            dotW(activeIndex >= 1),
            SizedBox(width: spacer),
            dashed(),
            SizedBox(width: spacer),
            dotW(activeIndex >= 2),
          ],
        ),
        SizedBox(height: width * 0.012),
        // Mirror the exact layout widths above so numbers sit under circles
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: dotBox,
              child: Center(
                child: Text(
                  labels.elementAt(0),
                  style: TextStyle(
                    color: accent,
                    fontSize: width * 0.032,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            SizedBox(width: spacer),
            SizedBox(width: lineW),
            SizedBox(width: spacer),
            SizedBox(
              width: dotBox,
              child: Center(
                child: Text(
                  labels.elementAt(1),
                  style: TextStyle(
                    color: accent,
                    fontSize: width * 0.032,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            SizedBox(width: spacer),
            SizedBox(width: lineW),
            SizedBox(width: spacer),
            SizedBox(
              width: dotBox,
              child: Center(
                child: Text(
                  labels.elementAt(2),
                  style: TextStyle(
                    color: accent,
                    fontSize: width * 0.032,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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

// --------------------- Input ---------------------

class _PillInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  final double contentFontSize;

  const _PillInput(
    this.validator, {
    required this.controller,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    required this.contentFontSize,
    this.obscure = false,
    this.suffix,
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
              validator: validator,
              style: TextStyle(
                color: Colors.white,
                fontSize: contentFontSize,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins', // ✅ requested
              ),
              cursorColor: const Color(0xFFFFA10D),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: contentFontSize * 0.9,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins', // ✅ requested
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
