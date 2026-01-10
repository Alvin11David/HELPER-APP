import 'package:flutter/material.dart';
import 'dart:ui';
import 'Academic_Certificate_Upload_Screen.dart';

class AddProfessionScreen extends StatefulWidget {
  @override
  _AddProfessionScreenState createState() => _AddProfessionScreenState();
}

class _AddProfessionScreenState extends State<AddProfessionScreen> {
  final TextEditingController _professionController = TextEditingController();

  @override
  void dispose() {
    _professionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                      'Add Profession',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top:
                    screenHeight * 0.15, // Adjusted to reduce space from header
                left: screenWidth * 0.12,
                right: screenWidth * 0.12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: screenHeight * 0.003,
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
                      height: 30,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Add Your Profession Here',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.038,
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
              Positioned(
                top: screenHeight * 0.2,
                left: screenWidth * 0.04,
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.02),
                    Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.7),
                      child: Text(
                        'Profession',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'PlayfairDisplay',
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Container(
                      width: screenWidth * (347 / 375),
                      height: 39,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _professionController,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.04,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w900,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter Your Profession',
                                hintStyle: TextStyle(
                                  color: Colors.black54,
                                  fontSize: screenWidth * 0.04,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w900,
                                ),
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              cursorColor: Colors.black,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Image.asset(
                            'assets/icons/license.png',
                            width: 24,
                            height: 24,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.28),
                    GestureDetector(
                      onTap: () {
                        String newProfession = _professionController.text
                            .trim();
                        if (newProfession.isNotEmpty &&
                            !AcademicCertificateUploadScreen.professions
                                .contains(newProfession)) {
                          setState(() {
                            AcademicCertificateUploadScreen.professions.add(
                              newProfession,
                            );
                          });
                          _professionController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Profession added successfully!'),
                            ),
                          );
                        } else if (newProfession.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please enter a profession.'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Profession already exists.'),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: screenWidth * 0.93,
                        height: screenHeight * 0.07,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PlayfairDisplay',
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.black,
                              size: screenWidth * 0.06,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: screenHeight * 0.2,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: screenHeight * 0.010,
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
                              'Instant Confirmation',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.033,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
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
      ),
    );
  }
}
