import 'dart:ui';

import 'package:flutter/material.dart';
import 'Verification_Information_Screen.dart';

class SelectWorkerTypeScreen extends StatefulWidget {
  const SelectWorkerTypeScreen({super.key});

  @override
  State<SelectWorkerTypeScreen> createState() => _SelectWorkerTypeScreenState();
}

class _SelectWorkerTypeScreenState extends State<SelectWorkerTypeScreen> {
  // 0: none, 1: professional, 2: non-professional
  int _selectedWorkerType = 0;
  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    const brandOrange = Color(0xFFFFA10D);

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
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child: Column(
                  children: [
                    SizedBox(height: h * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/logo.png',
                          width: w * 0.08,
                          height: w * 0.08,
                        ),
                        SizedBox(width: w * 0.03),
                        Text(
                          'Helper',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.055,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.05),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'What type of worker\nare you?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.085,
                          fontFamily: 'AbrilFatface',
                          height: 1.05,
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
                              vertical: screenHeight * 0.004,
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
                              'Kindly select your role',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color.fromRGBO(255, 255, 255, 1),
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWorkerType = 1;
                          });
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const VerificationInformationScreen(),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              width: screenWidth * 0.9,
                              height: screenWidth * 0.9 * (147 / 340),
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
                                  color: _selectedWorkerType == 1
                                      ? brandOrange
                                      : Colors.white.withOpacity(0.4),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: screenWidth * 0.03,
                                    left: screenWidth * 0.05,
                                    child: Text(
                                      'Professional Worker',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.055,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: screenWidth * 0.11,
                                    left: screenWidth * 0.04,
                                    child: SizedBox(
                                      width: screenWidth * 0.35,
                                      child: Text(
                                        '"Skilled and licensed\nprofessionals e.g Drivers, Electricians, Nurses etc"',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.w200,
                                          fontFamily: 'AbrilFatface',
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -screenWidth * 0.0,
                                    top: 0,
                                    child: Image.asset(
                                      'assets/images/professional.png',
                                      width: screenWidth * 0.5,
                                      height: screenWidth * 0.5,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Center(
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWorkerType = 2;
                          });
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              width: screenWidth * 0.9,
                              height: screenWidth * 0.9 * (147 / 340),
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
                                  color: _selectedWorkerType == 2
                                      ? brandOrange
                                      : Colors.white.withOpacity(0.4),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: screenWidth * 0.03,
                                    right: screenWidth * 0.05,
                                    child: Text(
                                      'Non-Professional Worker',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: screenWidth * 0.13,
                                    right: screenWidth * 0.1,
                                    child: SizedBox(
                                      width: screenWidth * 0.35,
                                      child: Text(
                                        '"General Labour,\ncleaning,\nloading, delivery etc"',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.036,
                                          fontWeight: FontWeight.w200,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: -screenWidth * 0.01,
                                    top: -screenWidth * 0.02,
                                    child: Image.asset(
                                      'assets/images/nonprofessional.png',
                                      width: screenWidth * 0.54,
                                      height: screenWidth * 0.54,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
