import 'dart:ui';

import 'package:flutter/material.dart';

class AcademicCertificateUploadScreen extends StatelessWidget {
  const AcademicCertificateUploadScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background/normalscreenbg.png',
            fit: BoxFit.cover,
          ),
          Positioned(
            top: screenWidth * 0.1,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    GestureDetector(
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
                    SizedBox(width: screenWidth * 0.06),
                    Text(
                      'Academic Certificates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
                top:
                    screenHeight * 0.14, // Adjusted to reduce space from header
                left: screenWidth * 0.12,
                right: screenWidth * 0.12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
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
                      height: 33,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Search or add your professiona/Job',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
