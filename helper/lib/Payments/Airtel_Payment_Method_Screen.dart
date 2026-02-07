import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:helper/Document%20Upload/Select_Worker_Type_Screen.dart';
import 'package:helper/Intro/Role_Selection_Screen.dart';

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
  bool _isPaymentSuccessful = false; // State to track payment status
  final Duration _overlayAnimDuration = Duration(milliseconds: 300);
  String? _savedPhoneNumber;

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
            .collection('Airtel Numbers')
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
            .collection('Airtel Numbers')
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
    print('Starting payment process');
    final String phoneNumber = _cardNumberController.text.trim();

    // Basic validation - Airtel Uganda prefixes: 075, 070, 074(0-2)
    final String cleanPhone = phoneNumber
        .replaceAll(' ', '')
        .replaceAll('+', '');
    final RegExp airtelRegex = RegExp(
      r'^(256(75|70|74[0-2])\d{7}|0(75|70|74[0-2])\d{7}|(75|70|74[0-2])\d{7})$',
    );
    if (phoneNumber.isEmpty || !airtelRegex.hasMatch(cleanPhone)) {
      print('Phone validation failed: $phoneNumber');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Airtel Uganda phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Phone number validated: $phoneNumber');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Phone number validated: $phoneNumber'),
        backgroundColor: Colors.green,
      ),
    );

    // Get current user and verify authentication
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('User not authenticated');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Force refresh the user's token to ensure it's valid
    try {
      await currentUser.getIdToken(true);
      print('User token refreshed successfully');
    } catch (tokenError) {
      print('Error refreshing token: $tokenError');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication error. Please sign in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print(
      'User authenticated: ${currentUser.uid}, email: ${currentUser.email}',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User authenticated: ${currentUser.uid}'),
        backgroundColor: Colors.green,
      ),
    );

    try {
      // Step 1: Validate mobile number with Relworx API
      print('Validating mobile number with Relworx...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Validating mobile number...'),
          backgroundColor: Colors.blue,
        ),
      );

      final validateCallable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('validateMobileNumber');

      // Format phone number for international format
      String formattedPhone = cleanPhone;
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '256' + formattedPhone.substring(1);
      } else if (!formattedPhone.startsWith('256')) {
        formattedPhone = '256' + formattedPhone;
      }

      print('Calling validateMobileNumber with: { msisdn: $formattedPhone }');

      final validateResult = await validateCallable.call({
        'msisdn': formattedPhone,
        'userId': currentUser.uid,
      });

      final validateData = validateResult.data as Map<String, dynamic>;
      print('validateMobileNumber response: $validateData');

      if (validateData['success'] != true) {
        print('Mobile number validation failed: ${validateData['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Validation failed: ${validateData['message'] ?? 'Invalid mobile number'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('Mobile number validation successful');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Validated: ${validateData['customer_name'] ?? 'Customer found'}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Step 2: Request payment
      print('Initiating payment request...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Initiating payment request...'),
          backgroundColor: Colors.blue,
        ),
      );

      final paymentCallable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('requestPayment');

      final reference =
          'reg_fee_${DateTime.now().millisecondsSinceEpoch}_${currentUser.uid}';

      final paymentResult = await paymentCallable.call({
        'account_no': 'REL4E261389F7', // From environment
        'reference': reference,
        'msisdn': formattedPhone,
        'currency': 'UGX',
        'amount': 25000.0,
        'description': 'Registration Fee Payment',
        'webhook_url':
            'https://us-central1-helperapp-46849.cloudfunctions.net/relworxWebhook',
        'saveCard': isChecked,
        'originalPhoneNumber': phoneNumber,
      });

      final paymentData = paymentResult.data as Map<String, dynamic>;

      print('Payment request response: $paymentData');

      if (paymentData['success'] == true) {
        // Payment request successful - show pending status
        setState(() {
          _isPaymentSuccessful = false; // Wait for webhook confirmation
          _isDimming = true;
          _showOverlay = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              paymentData['message'] ??
                  'Payment request sent successfully! Please complete the payment on your phone.',
            ),
            backgroundColor: Colors.blue,
          ),
        );

        // Start listening for payment status updates
        _listenForPaymentStatus(reference);
      } else {
        // Payment request failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment request failed: ${paymentData['message'] ?? 'Unknown error'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Payment error details: ${e.runtimeType}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: ${e.runtimeType}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _listenForPaymentStatus(String reference) {
    final paymentRef = FirebaseFirestore.instance
        .collection('Payments')
        .doc(reference);

    paymentRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final status = data?['status'];

        if (status == 'success') {
          setState(() {
            _isPaymentSuccessful = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to role selection after a short delay to show success
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SelectWorkerTypeScreen(),
              ),
            );
          });
        } else if (status == 'failed') {
          setState(() {
            _isPaymentSuccessful = false;
            _showOverlay = false; // Hide overlay on failure
            _isDimming = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment failed: ${data?['message'] ?? 'Unknown error'}',
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
                                _isPaymentSuccessful ? 'Paid' : 'Not Paid',
                                style: TextStyle(
                                  color: _isPaymentSuccessful
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
                          _isPaymentSuccessful
                              ? 'Account Created'
                              : 'Payment Pending',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.065,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isPaymentSuccessful
                              ? 'Successfully'
                              : 'Please Complete Payment',
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
                            _isPaymentSuccessful
                                ? 'Your payment of UGX 25,000\nhas been successfully\nreceived.'
                                : 'Please complete your payment\non your Airtel mobile phone\nto continue.',
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
