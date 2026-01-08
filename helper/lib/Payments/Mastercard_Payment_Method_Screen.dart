

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MasterCardPaymentMethodScreen extends StatefulWidget {
  const MasterCardPaymentMethodScreen({super.key});

  @override
  State<MasterCardPaymentMethodScreen> createState() =>
      _MasterCardPaymentMethodScreenState();
}

class _MasterCardPaymentMethodScreenState
    extends State<MasterCardPaymentMethodScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  bool isChecked = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

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
                        Color(0xFFF6B12B), // orange
                        Color(0xFFFF3B2F), // red
                      ],
                      stops: [0.0, 1.0],
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
                              'assets/images/mastercard.png',
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
                                'Master Card',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.050,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.001),
                              Text(
                                'Amount',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'UGX 25,000',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.07,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'AbrilFatface', // ✅ heading font
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Not Paid pill (same positioning pattern)
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
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Not Paid',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
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
                top: screenHeight * 0.14 +
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
                        fontFamily: 'Poppins', // ✅ per your instruction
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
                              controller: _cardNumberController,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.04,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter Your Card Number',
                                hintStyle: TextStyle(
                                  color: Colors.black54,
                                  fontSize: screenWidth * 0.04,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                ),
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              cursorColor: Colors.black,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                TextInputFormatter.withFunction(
                                  (oldValue, newValue) {
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
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Image.asset(
                            'assets/images/mastercard.png',
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
                        fontFamily: 'Poppins',
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
                              controller: _cardHolderController,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.04,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter Your Card Holder Name',
                                hintStyle: TextStyle(
                                  color: Colors.black54,
                                  fontSize: screenWidth * 0.04,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                ),
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              cursorColor: Colors.black,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          const Icon(Icons.person, color: Colors.black, size: 24),
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
                                fontFamily: 'Poppins',
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.012),
                            Container(
                              width: screenWidth * (122 / 375),
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
                                      controller: _expiryController,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.04,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w800,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '**/**',
                                        hintStyle: TextStyle(
                                          color: Colors.black54,
                                          fontSize: screenWidth * 0.04,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w700,
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
                                fontFamily: 'Poppins',
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.012),
                            Container(
                              width: screenWidth * (211 / 375),
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
                                      controller: _cvvController,
                                      obscureText: true,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.04,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w800,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter CVV',
                                        hintStyle: TextStyle(
                                          color: Colors.black54,
                                          fontSize: screenWidth * 0.04,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w700,
                                        ),
                                        border: InputBorder.none,
                                        isCollapsed: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      cursorColor: Colors.black,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  const Icon(Icons.lock,
                                      color: Colors.black, size: 24),
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
                          onTap: () => setState(() => isChecked = !isChecked),
                          child: Container(
                            width: screenWidth * 0.05,
                            height: screenWidth * 0.05,
                            decoration: BoxDecoration(
                              color:
                                  isChecked ? Colors.white : Colors.transparent,
                              border:
                                  Border.all(color: Colors.white, width: 2),
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
                            fontFamily: 'Poppins',
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: screenHeight * 0.05),

                    // Pay button (same pattern)
                    GestureDetector(
                      onTap: () {
                        // Add your payment logic here
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
                                fontFamily: 'Poppins',
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
    );
  }
}
