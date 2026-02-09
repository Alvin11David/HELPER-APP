import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class MtnAirtelWithdrawScreen extends StatefulWidget {
  final String amount;
  final String type;

  const MtnAirtelWithdrawScreen({
    super.key,
    required this.amount,
    required this.type,
  });

  @override
  State<MtnAirtelWithdrawScreen> createState() =>
      _MtnAirtelWithdrawScreenState();
}

class _MtnAirtelWithdrawScreenState extends State<MtnAirtelWithdrawScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  bool isChecked = false;
  bool _isDimming = false;
  bool _showOverlay = false;
  bool _isLoading = false;
  bool _isPaymentSuccessful = false;
  String? _savedPhoneNumber;
  final Duration _overlayAnimDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _loadSavedPhoneNumber();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPhoneNumber() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('Saved Payment Methods')
            .doc(currentUser.uid)
            .collection('${widget.type} Numbers')
            .doc('latest')
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _savedPhoneNumber = data['phoneNumber'] as String?;
            if (_savedPhoneNumber != null &&
                _cardNumberController.text.isEmpty) {
              _cardNumberController.text = _savedPhoneNumber!;
            }
          });
        }
      }
    } catch (e) {
      // Silently handle errors for saved phone number loading
      print('Error loading saved phone number: $e');
    }
  }

  Future<void> _savePhoneNumber(String phoneNumber) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('Saved Payment Methods')
            .doc(currentUser.uid)
            .collection('${widget.type} Numbers')
            .doc('latest')
            .set({
              'phoneNumber': phoneNumber,
              'savedAt': FieldValue.serverTimestamp(),
              'isActive': true,
            });
      }
    } catch (e) {
      print('Error saving phone number: $e');
    }
  }

  Future<void> _processPayment() async {
    final String phoneNumber = _cardNumberController.text.trim();

    // Basic validation
    final String cleanPhone = phoneNumber
        .replaceAll(' ', '')
        .replaceAll('+', '');
    final RegExp regex = widget.type == 'MTN'
        ? RegExp(
            r'^(256(77|78|76|79|31|39)\d{7}|0(77|78|76|79|31|39)\d{7}|(77|78|76|79|31|39)\d{7})$',
          )
        : RegExp(
            r'^(256(70|74|75|20)\d{7}|0(70|74|75|20)\d{7}|(70|74|75|20)\d{7})$',
          );
    if (phoneNumber.isEmpty || !regex.hasMatch(cleanPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid ${widget.type} Uganda phone number',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    print('Starting withdrawal process');

    // 1. FORMAT MSISDN (Force +256 format)
    String digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = '256' + digits.substring(1);
    if (!digits.startsWith('256')) digits = '256' + digits;
    final String finalMsisdn = '+' + digits;

    print('DEBUG: Sending MSISDN: $finalMsisdn');

    // 2. SAFE REFERENCE (Avoid Substring Crash)
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    // SAFE: Use the whole string or check length before cutting
    final String rawRef = 'W$timestamp'; // W for Withdraw
    final String finalReference = rawRef.length > 15
        ? rawRef.substring(0, 15)
        : rawRef;

    print('DEBUG: Sending Reference: $finalReference');

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('DEBUG: No user authenticated');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final paymentUrl =
          'https://us-central1-helperapp-46849.cloudfunctions.net/requestWithdrawal'; // Assuming same endpoint

      print('Initiating withdrawal request to $paymentUrl...');
      final paymentResponse = await http.post(
        Uri.parse(paymentUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await currentUser.getIdToken()}',
        },
        body: jsonEncode({
          "data": {
            'userId': currentUser.uid,
            'msisdn': finalMsisdn,
            'amount': int.parse(widget.amount),
            'reference': finalReference,
            'description': 'Wallet Withdraw',
            'originalPhoneNumber': phoneNumber,
            'saveCard': isChecked,
          },
        }),
      );

      print('Withdrawal request HTTP status: ${paymentResponse.statusCode}');
      print('Raw Response: ${paymentResponse.body}');

      final fullResponseBody = jsonDecode(paymentResponse.body);
      final paymentData = fullResponseBody['result'] ?? fullResponseBody;

      if (paymentResponse.statusCode == 200 &&
          (paymentData['success'] == true)) {
        print('SUCCESS: Prompt sent to $finalMsisdn');
        if (isChecked) {
          await _savePhoneNumber(phoneNumber);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Withdrawal request sent successfully. Please check your phone for the prompt.',
            ),
            backgroundColor: Colors.blue,
          ),
        );
        setState(() {
          _isDimming = true;
          _showOverlay = true;
        });
        _listenForPaymentStatus(finalReference);
      } else {
        String msg = paymentData['message'] ?? 'Invalid response from server';
        print('FAILED: $msg');
        throw Exception(msg);
      }
    } catch (e) {
      print('CRITICAL ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _listenForPaymentStatus(String reference) {
    FirebaseFirestore.instance
        .collection('Payment Data')
        .where('reference', isEqualTo: reference)
        .snapshots()
        .listen((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            final doc = querySnapshot.docs.first;
            final data = doc.data();
            final status = data['status'];

            if (status == 'SUCCESS') {
              setState(() {
                _isPaymentSuccessful = true;
              });
              // Deduct from balance
              final User? currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                final amount = int.parse(widget.amount);
                FirebaseFirestore.instance
                    .collection('Sign Up')
                    .doc(currentUser.uid)
                    .update({'amount': FieldValue.increment(-amount)});
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Withdrawal completed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              // Navigate back after a short delay
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.of(context).pop();
              });
            } else if (status == 'FAILED') {
              setState(() {
                _isPaymentSuccessful = false;
                _showOverlay = false; // Hide overlay on failure
                _isDimming = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Withdrawal failed: ${data['message'] ?? 'Unknown error'}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Dim overlay
          if (_isDimming)
            Container(
              color: Colors.black.withOpacity(
                0.5,
              ), // Semi-transparent black overlay
            ),

          SafeArea(
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
                          'Payment Method',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.07,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.14,
                    left: screenWidth * 0.04,
                    child: Container(
                      width: screenWidth * 0.92,
                      height: screenWidth * 0.92 * (148 / 340),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: widget.type == 'MTN'
                              ? [
                                  const Color(0xFFFFCB05),
                                  const Color(0xFFFFFFFF),
                                ]
                              : [
                                  const Color(0xFFD40000),
                                  const Color(0xFFFFFFFF),
                                ],
                          stops: [0.73, 1.2],
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  widget.type == 'MTN'
                                      ? 'assets/images/mtn.png'
                                      : 'assets/images/airtel.png',
                                  width: screenWidth * 0.15,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.04),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: screenHeight * 0.002),
                                  Text(
                                    widget.type,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.055,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.00),
                                  Text(
                                    'Amount',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.005),
                                  Text(
                                    'UGX ${NumberFormat('#,###').format(int.parse(widget.amount))}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.07,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'AbrilFatface',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: screenWidth * 0.04,
                                right: screenWidth * 0.04,
                              ),
                              child: Container(
                                width: screenWidth * (94 / 340),
                                height: screenWidth * (40 / 340),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Not Paid', // Change this to 'Not Paid', 'Pending', etc. as needed
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Add Card Number input section below the rectangle
                  Positioned(
                    top:
                        screenHeight * 0.14 +
                        screenWidth * 0.92 * (148 / 340) +
                        screenHeight * 0.03,
                    left: screenWidth * 0.04,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add Card Holder Name input section below the Card Number field
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'Phone Number',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'PlayfairDisplay',
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.012),
                        Container(
                          width: screenWidth * (347 / 375),
                          height: 35,
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
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.04,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w900,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Enter Your ${widget.type} Number',
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
                              Icon(
                                Icons.phone,
                                color: widget.type == 'MTN'
                                    ? Colors.yellow
                                    : Colors.red,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                        // Add Save Card for Future checkbox below the Expires On row
                        SizedBox(height: screenHeight * 0.04),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isChecked = !isChecked;
                                });
                              },
                              child: Container(
                                width: screenWidth * 0.05,
                                height: screenWidth * 0.05,
                                decoration: BoxDecoration(
                                  color: isChecked
                                      ? Colors.white
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: isChecked
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.black,
                                        size: screenWidth * 0.03,
                                      )
                                    : null,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Text(
                              'Save card for future',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'PlayfairDisplay',
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.05),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isDimming = true; // Trigger the dimming effect
                              _showOverlay =
                                  true; // Show the overlay permanently
                            });
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
                                  'Pay',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.06,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'PlayfairDisplay',
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.black,
                                  size: screenWidth * 0.06,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: screenHeight * 0.03,
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
          // Dim overlay
          if (_isDimming)
            Container(
              color: Colors.black.withOpacity(
                0.5,
              ), // Semi-transparent black overlay
            ),

          // Sliding white rectangle for confirmation
          AnimatedPositioned(
            duration: _overlayAnimDuration,
            curve: Curves.easeOutCubic,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            bottom: _showOverlay ? screenHeight * 0.02 : -screenHeight,
            child: AnimatedOpacity(
              duration: _overlayAnimDuration,
              curve: Curves.easeInOut,
              opacity: _showOverlay ? 1.0 : 0.0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: screenWidth * 0.9,
                  height:
                      screenHeight *
                      0.7, // Increased height to fit content better
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.05,
                    0,
                    screenWidth * 0.05,
                    15, // Reduced bottom padding to prevent clipping the button
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.0),
                        Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Image.asset(
                              'assets/images/pop.png',
                              width: screenWidth * 1.1,
                              fit: BoxFit.contain,
                            ),
                            Positioned(
                              top: 0,
                              child: Image.asset(
                                'assets/images/celebration.png',
                                width: screenWidth * 0.4,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.0),
                        Text(
                          'Congratulations\nyou have withdrawn money',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.065,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'to your phone number',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.065,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                          ),
                          child: Text(
                            'Your withdrawal of UGX ${NumberFormat('#,###').format(int.parse(widget.amount))}\nhas been successfully\nmade.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenWidth * 0.035,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.07),
                        SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.062,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _processPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDF8800),
                              disabledBackgroundColor: const Color(
                                0xFFDF8800,
                              ).withOpacity(0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: screenHeight * 0.03,
                                    height: screenHeight * 0.03,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Withdraw',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: 'AbrilFatface',
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.02),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: screenHeight * 0.035,
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        // Add more content here as needed
                      ],
                    ),
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
