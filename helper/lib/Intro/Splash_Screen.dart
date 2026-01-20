import 'package:flutter/material.dart';
import 'package:helper/Auth/Phone_Number_&_Email_Address_Screen.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _displayedText = '';
  final String _fullText = 'Helper';
  Timer? _timer;
  int _currentIndex = 0;
  bool _isTyping = true;

  @override
  void initState() {
    super.initState();
    _startTypewriterEffect();
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PhoneNumberEmailAddressScreen()),
      );
    });
  }

  void _startTypewriterEffect() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        if (_isTyping) {
          if (_currentIndex < _fullText.length) {
            _displayedText = _fullText.substring(0, _currentIndex + 1);
            _currentIndex++;
          } else {
            _isTyping = false;
          }
        } else {
          if (_currentIndex > 0) {
            _currentIndex--;
            _displayedText = _fullText.substring(0, _currentIndex);
          } else {
            _isTyping = true;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
              image: AssetImage('assets/background/splashscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Top center text with white stroke
              Positioned(
                top: screenHeight * 0.1,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Helper',
                    style: TextStyle(
                      fontSize: screenWidth * 0.17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Sekuya',
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1
                        ..color = Colors.white,
                    ),
                  ),
                ),
              ),
              // Second Helper text below the first one
              Positioned(
                top: screenHeight * 0.11 + screenWidth * 0.21 + 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Helper',
                    style: TextStyle(
                      fontSize: screenWidth * 0.17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Sekuya',
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 0.6
                        ..color = Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              // Third Helper text below the second one
              Positioned(
                top: screenHeight * 0.11 + (screenWidth * 0.23 + 10) * 2,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Helper',
                    style: TextStyle(
                      fontSize: screenWidth * 0.17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Sekuya',
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 0.3
                        ..color = Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              // Centered logo and text
              Positioned(
                top: screenHeight * 0.52,
                left: 0,
                right: 0,
                child: Center(
                  child: ClipRect(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/logo.png',
                          width: screenWidth * 0.12,
                          height: screenWidth * 0.12,
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Text(
                          _displayedText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.07,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom center text
              Positioned(
                bottom: screenHeight * 0.1,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Find work. Get Help',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              // Circular progress indicator
              Positioned(
                bottom: screenHeight * 0.04,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: screenWidth * 0.08,
                    height: screenWidth * 0.08,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 5,
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
