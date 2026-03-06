import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helper/Document Upload/Select_Worker_Type_Screen.dart';
import 'package:helper/Employer Dashboard/Employer_Dashboard_Screen.dart';
import 'package:helper/Amount.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'MTN_Payment_Method_Screen.dart';
import 'Airtel_Payment_Method_Screen.dart';

class RegistrationPaymentScreen extends StatefulWidget {
  const RegistrationPaymentScreen({super.key});

  @override
  State<RegistrationPaymentScreen> createState() =>
      _RegistrationPaymentScreenState();
}

class _RegistrationPaymentScreenState extends State<RegistrationPaymentScreen> {
  final bool _isMasterCardSelected = false;
  final bool _isVisaCardSelected = false;
  final bool _isMtnCardSelected = false;
  final bool _isAirtelCardSelected = false;
  bool _isLoading = false;
  int? _registrationFee;
  int? _registrationFeeUSD;

  @override
  void initState() {
    super.initState();
    _loadRegistrationFee();
  }

  Future<void> _loadRegistrationFee() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('System Settings')
          .doc('default')
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _registrationFee = data['registrationFee'] is int
              ? data['registrationFee']
              : int.tryParse(data['registrationFee'].toString());
          _registrationFeeUSD = data['registrationFeeUSD'] is int
              ? data['registrationFeeUSD']
              : int.tryParse(data['registrationFeeUSD'].toString());
        });
      }
    } catch (e) {
      print('Error loading registration fee: $e');
    }
  }

  Future<void> _handleMasterCardPayment() async {
    setState(() => _isLoading = true);

    if (_registrationFee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration fee not loaded'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final String reference = 'MC_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await http.post(
        Uri.parse(
          'https://us-central1-helperapp-46849.cloudfunctions.net/requestCardSession',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user?.uid,
          'amount': _registrationFee,
          'reference': reference,
          'description': 'Helper App Registration',
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final String paymentUrl = data['payment_url'];
        if (await canLaunchUrl(Uri.parse(paymentUrl))) {
          await launchUrl(
            Uri.parse(paymentUrl),
            mode: LaunchMode.externalApplication,
          );

          _listenForCompletion(reference);
        }
      } else {
        throw Exception(data['message'] ?? 'Payment initiation failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVisaPayment() async {
    setState(() => _isLoading = true);

    if (_registrationFee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration fee not loaded'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final String reference = 'VISA_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await http.post(
        Uri.parse(
          'https://us-central1-helperapp-46849.cloudfunctions.net/requestCardSession',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user?.uid,
          'amount': _registrationFee,
          'reference': reference,
          'description': 'Helper App Registration',
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final String paymentUrl = data['payment_url'];
        if (await canLaunchUrl(Uri.parse(paymentUrl))) {
          await launchUrl(
            Uri.parse(paymentUrl),
            mode: LaunchMode.externalApplication,
          );

          _listenForCompletion(reference);
        }
      } else {
        throw Exception(data['message'] ?? 'Payment initiation failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _listenForCompletion(String reference) {
    FirebaseFirestore.instance
        .collection('Payment Data')
        .doc(reference)
        .snapshots()
        .listen((snapshot) async {
          if (snapshot.exists && snapshot.data()?['status'] == 'COMPLETED') {
            // Apply referral rewards after successful payment
            await _applyReferralRewardsAfterPayment();

            _navigateBasedOnRole();
          }
        });
  }

  Future<void> _applyReferralRewardsAfterPayment() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user's sign-up data
      final userDoc = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data();
      if (userData == null) return;

      // Check if referral reward has already been applied
      final bool rewardApplied = userData['referralRewardApplied'] ?? false;
      if (rewardApplied) return; // Already applied

      // Get the referral code they used during signup
      final String usedReferralCode = userData['usedReferralCode'] ?? '';

      if (usedReferralCode.isEmpty) return; // No referral code was used

      // Apply referral rewards
      final result = await AmountService.applyReferralRewards(
        referredUserId: user.uid,
        referralCode: usedReferralCode,
      );

      // Mark reward as applied to prevent duplicates
      if (result['success'] == true) {
        await FirebaseFirestore.instance
            .collection('Sign Up')
            .doc(user.uid)
            .update({'referralRewardApplied': true});
      }
    } catch (e) {
      // Silently fail - don't block user flow if referral rewards fail
      print('Error applying referral rewards: $e');
    }
  }

  Future<void> _navigateBasedOnRole() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data();
      if (userData == null) return;

      final String? role = userData['role'];

      if (!mounted) return;

      if (role == 'employer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const EmployerDashboardScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SelectWorkerTypeScreen(),
          ),
        );
      }
    } catch (e) {
      print('Error navigating based on role: $e');
      // Fallback to worker type screen on error
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SelectWorkerTypeScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    if (_registrationFee == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            child: SizedBox(
              height: screenHeight * 1.2,
              child: Stack(
                children: [
                  Positioned(
                    top: screenHeight * 0.04,
                    left: screenWidth * 0.04,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                              'Payment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.08,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.15),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.attach_money,
                                      color: Colors.white,
                                      size: screenWidth * 0.055,
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Text(
                                      'Registration Fee',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Center(
                          child: Text(
                            'UGX ${_registrationFee?.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},") ?? ''}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
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
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.004,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
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
                                    Text(
                                      'Outside World: \$${_registrationFeeUSD ?? ''}',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.34,
                    left: screenWidth * 0.04,
                    child: Text(
                      'Choose Method',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.39,
                    left: screenWidth * 0.04,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _isLoading ? null : _handleMasterCardPayment,
                          child: Container(
                            width: screenWidth * 0.91,
                            height: screenHeight * 0.091,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/images/mastercard.png',
                                        width: screenWidth * 0.12,
                                        height: screenWidth * 0.12,
                                      ),
                                      SizedBox(width: screenWidth * 0.04),
                                      Text(
                                        'Master Card',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.045,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: screenWidth * 0.065,
                                    height: screenWidth * 0.065,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isMasterCardSelected
                                          ? Colors.orange
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: _isMasterCardSelected
                                            ? Colors.white
                                            : Colors.black,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        GestureDetector(
                          onTap: _isLoading ? null : _handleVisaPayment,
                          child: Container(
                            width: screenWidth * 0.91,
                            height: screenHeight * 0.091,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/images/visa.png',
                                        width: screenWidth * 0.12,
                                        height: screenWidth * 0.12,
                                      ),
                                      SizedBox(width: screenWidth * 0.04),
                                      Text(
                                        'Visa Card',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.045,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: screenWidth * 0.065,
                                    height: screenWidth * 0.065,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isVisaCardSelected
                                          ? Colors.orange
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: _isVisaCardSelected
                                            ? Colors.white
                                            : Colors.black,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MtnPaymentMethodScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: screenWidth * 0.91,
                            height: screenHeight * 0.091,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/images/mtn.png',
                                        width: screenWidth * 0.12,
                                        height: screenWidth * 0.12,
                                      ),
                                      SizedBox(width: screenWidth * 0.04),
                                      Text(
                                        'MTN',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.045,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: screenWidth * 0.065,
                                    height: screenWidth * 0.065,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isMtnCardSelected
                                          ? Colors.orange
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: _isMtnCardSelected
                                            ? Colors.white
                                            : Colors.black,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AirtelPaymentMethodScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: screenWidth * 0.91,
                            height: screenHeight * 0.091,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/images/airtel.png',
                                        width: screenWidth * 0.12,
                                        height: screenWidth * 0.12,
                                      ),
                                      SizedBox(width: screenWidth * 0.04),
                                      Text(
                                        'AIRTEL',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.045,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: screenWidth * 0.065,
                                    height: screenWidth * 0.065,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isAirtelCardSelected
                                          ? Colors.orange
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: _isAirtelCardSelected
                                            ? Colors.white
                                            : Colors.black,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: screenHeight * 0.01,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.06,
                              vertical: screenHeight * 0.015,
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
                                  'Secure payment. Refundable if verification fails',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.03,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Inter',
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
        ),
      ),
    );
  }
}
