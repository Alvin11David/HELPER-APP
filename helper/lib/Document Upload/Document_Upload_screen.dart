import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helper/Document%20Upload/National_ID_Passport_Front_Upload_Screen.dart';
import 'package:rxdart/rxdart.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  bool _loading = false;
  int _selectedIndex = -1;
  final _formKey = GlobalKey<FormState>();
  bool _nationalIdSubmitted = false;

  Future<void> _onContinue() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    // TODO:
    // phone: send OTP -> navigate to OTPVerificationScreen
    // email: login/register -> next
    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkNationalIdSubmission();
  }

  Future<void> _checkNationalIdSubmission() async {
    final user = await Future.value(
      null,
    ); // Replace with FirebaseAuth.instance.currentUser if available
    // TODO: Replace with actual user check if needed
    // For demo, just check Firestore for the document
    // Uncomment and use the following if Firebase is available:
    /*
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docType = 'professional_workers_national_id_back';
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('documents')
        .doc('Professional Workers')
        .collection('Professional Workers')
        .doc(docType)
        .get();
    setState(() {
      _nationalIdSubmitted = doc.exists;
    });
    */
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    const brandOrange = Color(0xFFFFA10D);
    bool loading = false;
    final formKey = GlobalKey<FormState>();

    Future<void> onContinue() async {
      FocusScope.of(context).unfocus();
      if (!(formKey.currentState?.validate() ?? false)) return;

      setState(() => loading = true);

      // TODO:
      // phone: send OTP -> navigate to OTPVerificationScreen
      // email: login/register -> next
      await Future.delayed(const Duration(milliseconds: 650));

      if (!mounted) return;
      setState(() => loading = false);
    }

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
                        'Upload Verification\nDocuments',
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
                      activeIndex: 1,
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
                              horizontal: screenWidth * 0.04,
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
                              'Please provide the following documents\nto verify your profile',
                              maxLines: 2,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color.fromRGBO(255, 255, 255, 1),
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: h * 0.05),
                    Container(
                      width: 361,
                      height: 249,
                      padding: EdgeInsets.all(w * 0.04),
                      alignment: Alignment.topCenter,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Replace National ID/Passport row with a StreamBuilder that listens to Firestore for both front and back uploads
                            StreamBuilder<List<bool>>(
                              stream: _nationalIdVerificationStream(),
                              builder: (context, snapshot) {
                                final bothUploaded =
                                    snapshot.data != null &&
                                    snapshot.data!.every((v) => v);
                                return GestureDetector(
                                  onTap: () async {
                                    setState(() => _selectedIndex = 0);
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            NationalIdPassportFrontUploadScreen(
                                              selected: 0,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: bothUploaded
                                              ? const Color(0xFFFBBC04)
                                              : (_selectedIndex == 0
                                                    ? const Color(0xFFFBBC04)
                                                    : const Color(0xFFD9D9D9)),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Image.asset(
                                            'assets/icons/nationalid.png',
                                            width: 20,
                                            height: 20,
                                            color: bothUploaded
                                                ? Colors.white
                                                : null,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: w * 0.018),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'National ID/Passport',
                                              style: TextStyle(
                                                color: bothUploaded
                                                    ? Colors.orange
                                                    : (_selectedIndex == 0
                                                          ? const Color(
                                                              0xFFFBBC04,
                                                            )
                                                          : Colors.black),
                                                fontSize: screenWidth * 0.032,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              bothUploaded
                                                  ? 'Submitted For Verification'
                                                  : 'Not Verified',
                                              style: TextStyle(
                                                color: bothUploaded
                                                    ? Colors.orange
                                                    : (_selectedIndex == 0
                                                          ? const Color(
                                                              0xFFFBBC04,
                                                            )
                                                          : Colors.black54),
                                                fontSize: screenWidth * 0.035,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: bothUploaded
                                            ? Colors.orange
                                            : (_selectedIndex == 0
                                                  ? const Color(0xFFFBBC04)
                                                  : Colors.black54),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: h * 0.03),
                            GestureDetector(
                              onTap: () => setState(() => _selectedIndex = 1),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _selectedIndex == 1
                                          ? const Color(0xFFFBBC04)
                                          : const Color(0xFFD9D9D9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/icons/academic.png',
                                        width: 20,
                                        height: 20,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: w * 0.018),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Academic Certificates',
                                          style: TextStyle(
                                            color: _selectedIndex == 1
                                                ? const Color(0xFFFBBC04)
                                                : Colors.black,
                                            fontSize: screenWidth * 0.032,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          'Not Verified',
                                          style: TextStyle(
                                            color: _selectedIndex == 1
                                                ? const Color(0xFFFBBC04)
                                                : Colors.black54,
                                            fontSize: screenWidth * 0.035,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: _selectedIndex == 1
                                        ? const Color(0xFFFBBC04)
                                        : Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: h * 0.03),
                            GestureDetector(
                              onTap: () => setState(() => _selectedIndex = 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _selectedIndex == 2
                                          ? const Color(0xFFFBBC04)
                                          : const Color(0xFFD9D9D9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/icons/license.png',
                                        width: 20,
                                        height: 20,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: w * 0.018),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Professional Licenses',
                                          style: TextStyle(
                                            color: _selectedIndex == 2
                                                ? const Color(0xFFFBBC04)
                                                : Colors.black,
                                            fontSize: screenWidth * 0.032,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          'Not Verified',
                                          style: TextStyle(
                                            color: _selectedIndex == 2
                                                ? const Color(0xFFFBBC04)
                                                : Colors.black54,
                                            fontSize: screenWidth * 0.035,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: _selectedIndex == 2
                                        ? const Color(0xFFFBBC04)
                                        : Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: h * 0.03),
                            GestureDetector(
                              onTap: () => setState(() => _selectedIndex = 3),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _selectedIndex == 3
                                          ? const Color(0xFFFBBC04)
                                          : const Color(0xFFD9D9D9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.camera,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: w * 0.018),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Photo(Selfie)',
                                          style: TextStyle(
                                            color: _selectedIndex == 3
                                                ? const Color(0xFFFBBC04)
                                                : Colors.black,
                                            fontSize: screenWidth * 0.032,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          'Not Verified',
                                          style: TextStyle(
                                            color: _selectedIndex == 3
                                                ? const Color(0xFFFBBC04)
                                                : Colors.black54,
                                            fontSize: screenWidth * 0.035,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: _selectedIndex == 3
                                        ? const Color(0xFFFBBC04)
                                        : Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: h * 0.06),
                    // Continue (white)
                    SizedBox(
                      width: double.infinity,
                      height: h * 0.062,
                      child: ElevatedButton(
                        onPressed: null, // Deactivated
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0XFFFBBC04).withOpacity(0.6),
                          disabledBackgroundColor: Color(
                            0XFFFBBC04,
                          ).withOpacity(0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: w * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black.withOpacity(0.5),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(width: w * 0.02),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.black.withOpacity(0.5),
                                size: h * 0.035,
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

// Helper: Listen to both front and back uploads for National ID/Passport
Stream<List<bool>> _nationalIdVerificationStream() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value([false, false]);
  }

  final baseRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('documents')
      .doc('Professional Workers')
      .collection('Professional Workers');

  final frontStream = baseRef
      .doc('professional_workers_national_id_front')
      .snapshots();

  final backStream = baseRef
      .doc('professional_workers_national_id_back')
      .snapshots();

  return Rx.combineLatest2<DocumentSnapshot, DocumentSnapshot, List<bool>>(
    frontStream,
    backStream,
    (front, back) => [
      front.exists,
      back.exists,
    ],
  );
}
