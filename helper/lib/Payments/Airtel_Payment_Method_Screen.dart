import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutterwave_standard/core/flutterwave.dart';
import 'package:flutterwave_standard/models/requests/customer.dart';
import 'package:flutterwave_standard/models/requests/customizations.dart';
import 'package:flutterwave_standard/models/responses/charge_response.dart';

class AirtelPaymentMethodScreen extends StatefulWidget {
  const AirtelPaymentMethodScreen({super.key});

  @override
  State<AirtelPaymentMethodScreen> createState() =>
      _AirtelPaymentMethodScreenState();
}

class _AirtelPaymentMethodScreenState extends State<AirtelPaymentMethodScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  bool isChecked = false;
  bool _isDimming = false; // State to track if the screen should dim
  bool _showOverlay = false; // State to control the overlay visibility
  final Duration _overlayAnimDuration = Duration(milliseconds: 300);
  String _paymentStatus = 'Not Paid'; // State for payment status

  // Flutterwave configuration
  final String publicKey =
      "FLWPUBK_TEST-5c4c1ba4-9c72-45c8-90b0-b29e9c6a4597-X"; // Test Public Key
  final String encryptionKey =
      "0lT5zNJgnxHOm2PyOYZxQKL7yk0MC9Uodyo3Z/I3DE4="; // Test Encryption Key

  @override
  void dispose() {
    _cardNumberController.dispose();
    super.dispose();
  }

  void _handlePayment() async {
    String phoneNumber = _cardNumberController.text.trim();
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Airtel phone number')),
      );
      return;
    }

    // Validate Airtel prefixes using regex
    RegExp airtelRegex = RegExp(r'^(070[0-9]|075[0-9]|074[0-2])\d{6}$');
    if (!airtelRegex.hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid Airtel number. Must be a valid 10-digit Airtel Uganda number',
          ),
        ),
      );
      return;
    }

    // Convert to +256 format
    String convertedPhoneNumber = '+256' + phoneNumber.substring(1);

    // Generate a unique transaction reference
    final txRef = "helper_reg_${DateTime.now().millisecondsSinceEpoch}";

    final Customer customer = Customer(
      name: "Helper User", // You might want to get this from user data
      phoneNumber: convertedPhoneNumber,
      email: "user@example.com", // Replace with actual email if available
    );

    final Flutterwave flutterwave = Flutterwave(
      publicKey: publicKey,
      txRef: txRef,
      amount: "25000",
      customer: customer,
      paymentOptions: "mobilemoneyuganda",
      customization: Customization(
        title: "Helper Registration Payment",
        description: "Payment for Helper app registration",
      ),
      redirectUrl: "https://your-redirect-url.com", // Optional
      isTestMode: true, // Set to false for production
      currency: "UGX",
    );

    try {
      final ChargeResponse response = await flutterwave.charge(context);
      print(
        'Flutterwave Response: ${response.toJson()}',
      ); // Add this for debugging
      if (response.success == true) {
        // Payment successful
        setState(() {
          _isDimming = true;
          _showOverlay = true;
          _paymentStatus = 'Paid';
        });
      } else {
        // Payment failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment failed: ${response.status ?? 'Unknown error'}',
            ),
          ),
        );
      }
    } catch (error) {
      print('Payment Error: $error'); // Add this for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during payment')),
      );
    }
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
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFD40000), Color(0xFFFFFFFF)],
                          stops: [0.73, 1.2],
                        ),
                      ),
                      child: Stack(
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
                                  'assets/images/airtel.png',
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
                                    'AIRTEL',
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
                                    'UGX 25,000',
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

                          Positioned(
                            bottom: screenWidth * 0.04,
                            right: screenWidth * 0.04,
                            child: Container(
                              width: screenWidth * (94 / 340),
                              height: screenWidth * (28 / 340),
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
                                _paymentStatus,
                                style: TextStyle(
                                  color: _paymentStatus == 'Paid'
                                      ? Colors.green
                                      : Colors.black,
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.bold,
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
                          height: 40,
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
                                  controller: _cardNumberController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.04,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w900,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter Your Airtel Number',
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
                              Icon(Icons.phone, color: Colors.red, size: 24),
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
                          onTap: _handlePayment,
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
                          'Account Created',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.065,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Successfully',
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
                            'Your payment of UGX 25,000\nhas been successfully\nreceived.',
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
                        SizedBox(height: screenHeight * 0.04),
                        Text(
                          'Welcome to Helper!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.06,
                            fontFamily: 'AbrilFatface',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.07),
                        SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.062,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Handle continue action
                            },
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
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Go To Dashboard',
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
