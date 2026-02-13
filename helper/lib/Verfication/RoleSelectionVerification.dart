import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:helper/Verfication/RegistrationPaymentVerification.dart';
import '../Auth/Sign_In_Screen.dart';
import 'package:helper/Payments/Registration_Payment_Screen.dart';
import '../Employer Dashboard/Employer_Dashboard_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleSelectionVerificationScreen extends StatefulWidget {
  const RoleSelectionVerificationScreen({super.key});

  @override
  State<RoleSelectionVerificationScreen> createState() =>
      _RoleSelectionVerificationScreenState();
}

class _RoleSelectionVerificationScreenState
    extends State<RoleSelectionVerificationScreen> {
  String? _selectedRole; // 'worker' or 'employer'

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

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
          child: SingleChildScrollView(
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
                      'Helper\'s App',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
                Padding(
                  padding: EdgeInsets.only(left: screenWidth * 0.04),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Find',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.08,
                            fontFamily: 'AbrilFatface',
                          ),
                        ),
                        Text(
                          'Trusted help',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.08,
                            fontFamily: 'AbrilFatface',
                          ),
                        ),
                        Text(
                          'or get hired instantly',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.08,
                            fontFamily: 'AbrilFatface',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
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
                          'Kindly select your role',
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
                SizedBox(height: screenHeight * 0.03),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        _selectedRole = 'worker';
                      });
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('Sign Up')
                            .doc(user.uid)
                            .update({
                              'role': 'worker',
                              'activeRole': 'worker',
                              'workerType': '',
                            });
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const RegistrationPaymentVerificationScreen(),
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
                              color: _selectedRole == 'worker'
                                  ? Colors.orange
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
                                  'I am a Worker',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.055,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ),
                              Positioned(
                                top: screenWidth * 0.13,
                                left: screenWidth * 0.04,
                                child: SizedBox(
                                  width: screenWidth * 0.35,
                                  child: Text(
                                    '"Find near jobs\nand\nget paid securely"',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.040,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -screenWidth * 0.08,
                                bottom: 0,
                                child: Image.asset(
                                  'assets/images/worker.png',
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
                    onTap: () async {
                      setState(() {
                        _selectedRole = 'employer';
                      });
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('Sign Up')
                            .doc(user.uid)
                            .update({
                              'role': 'employer',
                              'activeRole': 'employer',
                            });
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EmployerDashboardScreen(),
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
                              color: _selectedRole == 'employer'
                                  ? Colors.orange
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
                                  'I am an Employer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.055,
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
                                    '"Find verified\nworkers\naround you"',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.042,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: -screenWidth * 0.01,
                                top: 0,
                                child: Image.asset(
                                  'assets/images/employer.png',
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
                SizedBox(height: screenHeight * 0.02),
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
        ),
      ),
    );
  }
}
