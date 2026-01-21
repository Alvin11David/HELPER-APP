import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'Document_Upload_screen.dart';

class VerificationInformationScreen extends StatefulWidget {
  const VerificationInformationScreen({super.key});

  @override
  State<VerificationInformationScreen> createState() =>
      _VerificationInformationScreenState();
}

class _VerificationInformationScreenState
    extends State<VerificationInformationScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  late Timer _timer;
  late AnimationController _rippleController;
  Animation<double>? _rippleAnimation;

  @override
  void initState() {
    super.initState();

    // Auto-slide every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % 4;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });

    // Ripple animation
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _rippleAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut),
        )..addListener(() {
          setState(() {});
        });
  }

  @override
  void dispose() {
    _timer.cancel();
    _rippleController.dispose();
    super.dispose();
  }

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
              Positioned(
                bottom: screenHeight * 0.03,
                left: 0,
                right: 0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: screenHeight * 0.011,
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'Verification builds trust and opens up more\nopportunities from employers',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.03,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
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
                          'Helper\'s App',
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
                        'Verify Your Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.085,
                          fontFamily: 'AbrilFatface',
                          height: 1.05,
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.039),
                    _StepIndicator(
                      width: w,
                      activeIndex: 1,
                      labels: const ['1', '2', '3'],
                      accent: brandOrange,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Center(
                      child: Text(
                        'Let\'s get your account verified\nto get the benefits below',
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color.fromRGBO(255, 255, 255, 1),
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    // Carousel
                    SizedBox(
                      height: screenHeight * 0.25,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return _buildGlassyRectangle(
                            screenWidth,
                            screenHeight,
                            index,
                            _rippleAnimation?.value ?? 0.0,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.09),
                    Center(
                      child: SizedBox(
                        width: screenWidth * 0.9,
                        height: screenHeight * 0.07,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DocumentUploadScreen(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Start Verification',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: "Inter",
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Image.asset(
                                'assets/icons/verify.png',
                                width: screenWidth * 0.05,
                                height: screenWidth * 0.05,
                              ),
                            ],
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

// --------------------- Carousel Item ---------------------

Widget _buildContactCircle(
  IconData icon,
  VoidCallback onTap,
  double screenWidth,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: screenWidth * 0.15,
      height: screenWidth * 0.15,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(icon, color: Colors.black, size: screenWidth * 0.08),
      ),
    ),
  );
}

Widget _buildGlassyRectangle(
  double screenWidth,
  double screenHeight,
  int index,
  double rippleValue,
) {
  final contents = [
    'You will achieve\nmore job visibility.',
    'Secure Payments.',
    'Higher trust\nfrom Employers.',
    'Referral Bonuses.',
  ];

  return Container(
    width: screenWidth,
    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
    child: CustomPaint(
      painter: RipplePainter(rippleValue),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: WaterWavePainter(rippleValue),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: screenHeight * 0.2,
              width: screenWidth * 0.8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 5,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '"',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.2,
                          fontFamily: 'Epunda Slab',
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.09,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        contents[index % contents.length],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.05,
                          fontFamily: 'AbrilFatface',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Helpers App',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.05,
                          fontFamily: 'Epunda Slab',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
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

class RipplePainter extends CustomPainter {
  final double animationValue;

  RipplePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * animationValue;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) => true;
}

class WaterWavePainter extends CustomPainter {
  final double animationValue;

  WaterWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.2 * animationValue)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 5) {
      final y =
          size.height / 2 + 10 * animationValue * (x / size.width - 0.5).abs();
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaterWavePainter oldDelegate) => true;
}
