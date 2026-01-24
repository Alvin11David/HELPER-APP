import 'package:flutter/material.dart';
import 'dart:ui'; // Add this import for ImageFilter
import 'package:flutter/services.dart'; // Add this import for TextInputFormatter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import for launching calls

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController issueTitleCtrl = TextEditingController();
  final TextEditingController issueDescCtrl = TextEditingController();
  static const Color _brandOrange = Color(0xFFFFA10D);
  bool _isLoading = false;

  Future<String?> _getFullName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['fullName'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _submit() async {
    String title = issueTitleCtrl.text.trim();
    String description = issueDescCtrl.text.trim();
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String? fullName = await _getFullName();

      await FirebaseFirestore.instance.collection('Support Issues').add({
        'title': title,
        'description': description,
        'fullName': fullName ?? 'Unknown',
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue submitted successfully')),
      );
      issueTitleCtrl.clear();
      issueDescCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting issue: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    issueTitleCtrl.dispose();
    issueDescCtrl.dispose();
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
                      'Support/Help',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins', // ✅ per your instruction
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: screenHeight * 0.12, // Adjust position below the header
                left: 0,
                right: 0,
                child: Column(
                  children: [
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
                              'We\'re here to help with jobs, payments or\ntechnical issues.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: screenHeight * 0.25, // Adjust position for the form
                left: screenWidth * 0.04,
                right: screenWidth * 0.04,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.018),
                    Text(
                      'Issue title',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.040,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    _PillInput(
                      controller: issueTitleCtrl,
                      hint: 'Enter Your Issue Title',
                      icon: Icons.title,
                      keyboardType: TextInputType.text,
                      contentFontSize: screenWidth * 0.038,
                      validator: (v) {
                        final t = (v ?? '');
                        if (t.trim().isEmpty) return 'Issue title is required';
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.018),
                    Text(
                      'Issue Description',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.040,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    _PillInput(
                      controller: issueDescCtrl,
                      hint: 'Enter Your Issue Description',
                      icon: Icons.description,
                      keyboardType: TextInputType.multiline,
                      contentFontSize: screenWidth * 0.038,
                      maxLines: 5, // Increased from 3 to 5 for taller field
                      validator: (v) {
                        final t = (v ?? '');
                        if (t.trim().isEmpty)
                          return 'Issue description is required';
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      children: [
                        SizedBox(width: screenWidth * 0.06),
                        Expanded(
                          child: SizedBox(
                            height: screenHeight * 0.060,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : _submit, // Disable when loading
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandOrange,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      'Submit',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w900,
                                        fontSize: screenWidth * 0.040,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Center(
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      children: [
                        SizedBox(width: screenWidth * 0.06),
                        Expanded(
                          child: SizedBox(
                            height: screenHeight * 0.060,
                            child: ElevatedButton(
                              onPressed: () async {
                                const phoneNumber =
                                    'tel:+1234567890'; // Replace with actual support number
                                if (await canLaunch(phoneNumber)) {
                                  await launch(phoneNumber);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not launch phone app',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandOrange,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.call,
                                    color: Colors.white,
                                    size: screenWidth * 0.05,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    'Call Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w900,
                                      fontSize: screenWidth * 0.040,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _PillInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final double contentFontSize;
  final int? maxLines;

  const _PillInput({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    required this.contentFontSize,
    this.obscure = false,
    this.suffix,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final fieldH = h * 0.065;
    final radius = fieldH / 2;

    return Container(
      height: maxLines == 1
          ? fieldH
          : null, // Allow height to expand for multiline
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: maxLines == 1
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          SizedBox(width: w * 0.04),
          Padding(
            padding: EdgeInsets.only(top: maxLines == 1 ? 0 : fieldH * 0.20),
            child: Icon(icon, color: Colors.white, size: w * 0.06),
          ),
          SizedBox(width: w * 0.025),
          Padding(
            padding: EdgeInsets.only(top: maxLines == 1 ? 0 : fieldH * 0.20),
            child: Container(
              width: 1.2,
              height: fieldH * 0.55,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              maxLines: maxLines,
              style: TextStyle(
                color: Colors.white,
                fontSize: contentFontSize,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
              cursorColor: const Color(0xFFFFA10D),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: contentFontSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
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
