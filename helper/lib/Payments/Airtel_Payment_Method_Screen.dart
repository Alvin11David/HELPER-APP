import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AirtelPaymentMethodScreen extends StatefulWidget {
  const AirtelPaymentMethodScreen({super.key});

  @override
  State<AirtelPaymentMethodScreen> createState() =>
      _AirtelPaymentMethodScreenState();
}

class _AirtelPaymentMethodScreenState extends State<AirtelPaymentMethodScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  bool isChecked = false;
  @override
  void dispose() {
    _cardNumberController.dispose();
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
                                'VISA',
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
                            'Not Paid', // Change this to 'Not Paid', 'Pending', etc. as needed
                            style: TextStyle(
                              color: Colors.black,
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
                    Text(
                      'Card Number',
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
                              controller: _cardNumberController,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.04,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w900,
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
                    // Add Card Holder Name input section below the Card Number field
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
                          Icon(Icons.person, color: Colors.black, size: 24),
                        ],
                      ),
                    ),
                    // Add Expiration Date and CVV input fields in a Row
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      children: [
                        // Expiration Date Field
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
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Icon(
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
                        // CVV Field
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
                                      obscureText: true, // Enable CVV masking
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
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Icon(
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
                    // Add Save Card for Future checkbox below the Expires On row
                    SizedBox(height: screenHeight * 0.02),
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
                              border: Border.all(color: Colors.white, width: 2),
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
    );
  }
}
