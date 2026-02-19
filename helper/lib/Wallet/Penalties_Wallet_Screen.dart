import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helper/Wallet/Penalities_Withdraw_Payment_Method_Screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Wallet_Withdraw_Payment_Method_Screen.dart';

class NumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final intValue = int.tryParse(newValue.text.replaceAll(',', ''));
    if (intValue == null) {
      return oldValue;
    }
    final formatted = NumberFormat('#,###').format(intValue);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PenaltiesWalletScreen extends StatefulWidget {
  const PenaltiesWalletScreen({super.key});

  @override
  State<PenaltiesWalletScreen> createState() => _PenaltiesWalletScreenState();
}

class _PenaltiesWalletScreenState extends State<PenaltiesWalletScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool loading = false;
  String? selectedAmount;
  int _balance = 0;

  Future<int> _fetchPenaltiesSum() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Penalties')
        .get();
    int total = 0;
    int withdrawn = 0;
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final amount = data['amount'];
      final isWithdrawn = data['withdraw'] == true;
      int amt = 0;
      if (amount is int) {
        amt = amount;
      } else if (amount is String) {
        amt = int.tryParse(amount.replaceAll(',', '')) ?? 0;
      }
      if (isWithdrawn) {
        withdrawn += amt;
      } else {
        total += amt;
      }
    }
    return total - withdrawn;
  }

  final double screenWidth =
      WidgetsBinding.instance.window.physicalSize.width /
      WidgetsBinding.instance.window.devicePixelRatio;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int _getCurrentAmount() {
    String amount = selectedAmount != null
        ? selectedAmount!.replaceAll('UGX ', '').replaceAll(',', '')
        : _amountController.text.replaceAll(',', '');
    return int.tryParse(amount) ?? 0;
  }

  void onContinue() {
    int currentAmount = _getCurrentAmount();
    if (currentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount to withdraw'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (currentAmount > _balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You can't withdraw more than your balance"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get the amount to pass - either from selected preset or manual input
    String amountToPass = selectedAmount != null
        ? selectedAmount!.replaceAll('UGX ', '')
        : _amountController.text.isNotEmpty
        ? _amountController.text
        : '0';

    // Remove commas for passing the amount
    amountToPass = amountToPass.replaceAll(',', '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PenaltiestWithdrawPaymentMethodScreen(amount: amountToPass),
      ),
    );
  }

  Widget _amountButton(
    double w,
    double h,
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w * 0.22,
        height: h * 0.04,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFA10D), width: 2),
          color: isSelected ? const Color(0xFFFFA10D) : Colors.transparent,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: w * 0.03,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: screenHeight * 1.2,
          child: Stack(
            children: [
              Container(
                constraints: const BoxConstraints.expand(),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/background/normalscreenbg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.04,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: screenWidth * 0.04),
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
                              'Withdraw',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.08,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
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
                            child: Text(
                              'Enter the Amount of Money',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color.fromRGBO(255, 255, 255, 1),
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    FutureBuilder<int>(
                      future: _fetchPenaltiesSum(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: Container(
                              width: screenWidth * 0.9,
                              height: screenHeight * 0.05,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBC04),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error loading penalties balance'),
                          );
                        }
                        _balance = snapshot.data ?? 0;
                        return Center(
                          child: Container(
                            width: screenWidth * 0.9,
                            height: screenHeight * 0.05,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBC04),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  color: Colors.black,
                                  size: screenWidth * 0.05,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  'Available Penalties:',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  'UGX ${NumberFormat('#,###').format(_balance)}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    Center(
                      child: Container(
                        width: screenWidth * 0.9,
                        height: screenHeight * 0.3,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenHeight * 0.01,
                          ),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "How much money would you like to withdraw \nFrom your Helper's App Wallet?",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Text(
                                  "Amount",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.03,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "UGX",
                                      style: TextStyle(
                                        color: const Color(0xFFFFA10D),
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Expanded(
                                      child: TextField(
                                        controller: _amountController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          NumberInputFormatter(),
                                        ],
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Poppins',
                                        ),
                                        decoration: InputDecoration(
                                          hintText: "Enter Amount",
                                          hintStyle: TextStyle(
                                            color: Colors.black.withOpacity(
                                              0.55,
                                            ),
                                            fontSize: screenWidth * 0.03,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: 'Poppins',
                                          ),
                                          border: InputBorder.none,
                                          isCollapsed: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                CustomPaint(
                                  painter: _DashedLinePainter(
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                  child: SizedBox(
                                    height: 1,
                                    width: screenWidth * 0.8,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.04),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(width: screenWidth * 0.0),
                                      _amountButton(
                                        screenWidth,
                                        screenHeight,
                                        "UGX 10,000",
                                        selectedAmount == "UGX 10,000",
                                        () {
                                          setState(() {
                                            selectedAmount = "UGX 10,000";
                                            _amountController.text = "10,000";
                                          });
                                        },
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      _amountButton(
                                        screenWidth,
                                        screenHeight,
                                        "UGX 25,000",
                                        selectedAmount == "UGX 25,000",
                                        () {
                                          setState(() {
                                            selectedAmount = "UGX 25,000";
                                            _amountController.text = "25,000";
                                          });
                                        },
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      _amountButton(
                                        screenWidth,
                                        screenHeight,
                                        "UGX 50,000",
                                        selectedAmount == "UGX 50,000",
                                        () {
                                          setState(() {
                                            selectedAmount = "UGX 50,000";
                                            _amountController.text = "50,000";
                                          });
                                        },
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      _amountButton(
                                        screenWidth,
                                        screenHeight,
                                        "UGX 100,000",
                                        selectedAmount == "UGX 100,000",
                                        () {
                                          setState(() {
                                            selectedAmount = "UGX 100,000";
                                            _amountController.text = "100,000";
                                          });
                                        },
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      _amountButton(
                                        screenWidth,
                                        screenHeight,
                                        "UGX 200,000",
                                        selectedAmount == "UGX 200,000",
                                        () {
                                          setState(() {
                                            selectedAmount = "UGX 200,000";
                                            _amountController.text = "200,000";
                                          });
                                        },
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RuleRow('Minimum Amount: UGX 500'),
                    _RuleRow('Maximum Amount: Available Balance'),
                    SizedBox(height: screenHeight * 0.09),
                    // Continue (white)
                    SizedBox(
                      width: screenWidth * 0.9,
                      height: screenHeight * 0.062,
                      child: ElevatedButton(
                        onPressed:
                            loading ||
                                _getCurrentAmount() <= 0 ||
                                _getCurrentAmount() > _balance
                            ? null
                            : onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFFFBBC04),
                          disabledBackgroundColor: const Color(
                            0XFFFBBC04,
                          ).withOpacity(0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: loading
                            ? SizedBox(
                                width: screenHeight * 0.03,
                                height: screenHeight * 0.03,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.black,
                                ),
                              )
                            : Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.black,
                                      size: screenHeight * 0.035,
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

// Dashed line painter
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    const dashWidth = 6.0;
    const dashSpace = 5.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

class _RuleRow extends StatelessWidget {
  final String text;
  const _RuleRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white.withOpacity(0.9),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
