import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helper/Document%20Upload/Select_Worker_Type_Screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VisaPaymentMethodScreen extends StatefulWidget {
  const VisaPaymentMethodScreen({super.key});

  @override
  State<VisaPaymentMethodScreen> createState() =>
      _VisaPaymentMethodScreenState();
}

class _VisaPaymentMethodScreenState extends State<VisaPaymentMethodScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  static const String _kVisaCardNumberKey = 'visa_card_number';
  static const String _kVisaCardHolderKey = 'visa_card_holder';
  static const String _kVisaExpiryKey = 'visa_expiry';
  static const String _kVisaCVVKey = 'visa_cvv';

  @override
  void initState() {
    super.initState();
    _loadSavedCardData();
    _cardNumberController.addListener(_saveCardData);
    _cardHolderController.addListener(_saveCardData);
    _expiryController.addListener(_saveCardData);
    _cvvController.addListener(_saveCardData);
  }

  Future<void> _loadSavedCardData() async {
    final prefs = await SharedPreferences.getInstance();
    _cardNumberController.text = prefs.getString(_kVisaCardNumberKey) ?? '';
    _cardHolderController.text = prefs.getString(_kVisaCardHolderKey) ?? '';
    _expiryController.text = prefs.getString(_kVisaExpiryKey) ?? '';
    _cvvController.text = prefs.getString(_kVisaCVVKey) ?? '';
  }

  Future<void> _saveCardData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVisaCardNumberKey, _cardNumberController.text);
    await prefs.setString(_kVisaCardHolderKey, _cardHolderController.text);
    await prefs.setString(_kVisaExpiryKey, _expiryController.text);
    await prefs.setString(_kVisaCVVKey, _cvvController.text);
  }

  bool isChecked = false;
  bool _isDimming = false; // State to track if the screen should dim
  bool _showOverlay = false; // State to control the overlay visibility
  bool _isPaymentSuccessful = false; // State to track payment status
  final Duration _overlayAnimDuration = Duration(milliseconds: 300);
  StreamSubscription<DocumentSnapshot>? _paymentStatusSubscription;
  String? _currentPaymentReference;

  @override
  void dispose() {
    _cardNumberController.removeListener(_saveCardData);
    _cardHolderController.removeListener(_saveCardData);
    _expiryController.removeListener(_saveCardData);
    _cvvController.removeListener(_saveCardData);
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _paymentStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final String cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final String cardHolder = _cardHolderController.text;
    final String expiry = _expiryController.text;
    final String cvv = _cvvController.text;

    // Basic validation
    if (cardNumber.isEmpty || cardNumber.length < 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid card number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (cardHolder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the card holder name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (expiry.isEmpty || !RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid expiry date (MM/YY)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (cvv.isEmpty || cvv.length != 3 || !RegExp(r'^\d{3}$').hasMatch(cvv)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 3-digit CVV'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get current user
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String userId = user.uid;
    final String reference =
        'visa_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    _currentPaymentReference = reference;

    // RELWORX API call
    const String apiKey = '2902144e65b9a7.v3wxxu9iseWHI-dQzOh7Gg';
    const String relworxUrl =
        'https://api.relworx.com/api/card/request-payment'; // Assuming this is the endpoint
    const String webhookUrl =
        'https://us-central1-helper-app-9b3a3.cloudfunctions.net/relworxWebhook'; // Your webhook URL

    final Map<String, dynamic> requestBody = {
      'api_key': apiKey,
      'amount': '25000',
      'currency': 'UGX',
      'card_number': cardNumber,
      'card_holder': cardHolder,
      'expiry': expiry,
      'cvv': cvv,
      'webhook_url': webhookUrl,
      'reference': reference,
    };

    try {
      final response = await http.post(
        Uri.parse(relworxUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // Payment request sent, start listening for status
        _listenForPaymentStatus(reference);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment processing... Please wait for confirmation.',
            ),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment request failed: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _listenForPaymentStatus(String reference) {
    _paymentStatusSubscription?.cancel();
    _paymentStatusSubscription = FirebaseFirestore.instance
        .collection('payments')
        .doc(reference)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            if (data != null && data['status'] == 'completed') {
              setState(() {
                _isPaymentSuccessful = true;
                _isDimming = true;
                _showOverlay = true;
              });
              _paymentStatusSubscription?.cancel();
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
                  // Header row (same as your code)
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
                            fontFamily: 'Poppins', // ✅ per your instruction
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Top gradient rectangle (Mastercard style)
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
                          colors: [
                            Color(0xFF1534CC), // blue
                            Color(0xFFFFFFFF), // white
                          ],
                          stops: [0.73, 1.2],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mastercard icon with shadow (same pattern)
                              Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/visa.png',
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
                                    'Visa Card',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.055,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.00),
                                  Text(
                                    'Amount',
                                    style: TextStyle(
                                      color: Colors.white,
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
                                      fontFamily:
                                          'AbrilFatface', // ✅ heading font
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Payment status pill (same positioning pattern)
                          Positioned(
                            bottom: screenWidth * 0.04,
                            right: screenWidth * 0.04,
                            child: Container(
                              width: screenWidth * (94 / 340),
                              height: screenWidth * (28 / 340),
                              decoration: BoxDecoration(
                                color: _isPaymentSuccessful
                                    ? Colors.green
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.10),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _isPaymentSuccessful ? 'Paid' : 'Not Paid',
                                style: TextStyle(
                                  color: _isPaymentSuccessful
                                      ? Colors.white
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

                  // Inputs section (same layout math as your code)
                  Positioned(
                    top:
                        screenHeight * 0.14 +
                        screenWidth * 0.92 * (148 / 340) +
                        screenHeight * 0.03,
                    left: screenWidth * 0.04,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Card Number',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily:
                                'PlayfairDisplay', // ✅ per your instruction
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
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.04,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w800,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter Your Card Number',
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
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    TextInputFormatter.withFunction((
                                      oldValue,
                                      newValue,
                                    ) {
                                      final text = newValue.text.replaceAll(
                                        ' ',
                                        '',
                                      );
                                      final buffer = StringBuffer();
                                      for (int i = 0; i < text.length; i++) {
                                        buffer.write(text[i]);
                                        if ((i + 1) % 4 == 0 &&
                                            i + 1 != text.length) {
                                          buffer.write(' ');
                                        }
                                      }
                                      return TextEditingValue(
                                        text: buffer.toString(),
                                        selection: TextSelection.collapsed(
                                          offset: buffer.length,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Image.asset(
                                'assets/images/visa.png',
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        Text(
                          'Card Holder Name',
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
                                  controller: _cardHolderController,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.04,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w900,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter Your Card Holder Name',
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
                              const Icon(
                                Icons.person,
                                color: Colors.black,
                                size: 24,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        Row(
                          children: [
                            // Expires on
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expires on',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'PlayfairDisplay',
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                Container(
                                  width: screenWidth * (122 / 375),
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
                                          controller: _expiryController,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.04,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w900,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '**/**',
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
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9/]'),
                                            ),
                                            LengthLimitingTextInputFormatter(5),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Colors.black,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(width: screenWidth * 0.04),

                            // CVV
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '3-Digit CVV',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'PlayfairDisplay',
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.012),
                                Container(
                                  width: screenWidth * (211 / 375),
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
                                          controller: _cvvController,
                                          obscureText: true,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.04,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w900,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter CVV',
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
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(3),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      const Icon(
                                        Icons.lock,
                                        color: Colors.black,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // Checkbox (same pattern)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => isChecked = !isChecked),
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

                        // Pay button (same pattern)
                        GestureDetector(
                          onTap: _processPayment,
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

                  // Glassmorphism bottom pill (same as your code)
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
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SelectWorkerTypeScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Go To Worker Type Selection',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Inter',
                                      ),
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
