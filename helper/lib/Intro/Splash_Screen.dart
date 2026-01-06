import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
                        ..strokeWidth = 1
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
                        ..strokeWidth = 1
                        ..color = Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
              // Centered logo and text
              Center(
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
                        'Helper',
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
                      strokeWidth: 3,
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
