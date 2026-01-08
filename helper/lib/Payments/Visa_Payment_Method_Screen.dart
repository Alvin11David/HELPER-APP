import 'package:flutter/material.dart';

class VisaPaymentMethodScreen extends StatefulWidget {
  const VisaPaymentMethodScreen({super.key});

  @override
  State<VisaPaymentMethodScreen> createState() =>
      _VisaPaymentMethodScreenState();
}

class _VisaPaymentMethodScreenState extends State<VisaPaymentMethodScreen> {
  final TextEditingController _cardNumberController = TextEditingController();

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
                      colors: [Color(0xFF1534CC), Color(0xFFFFFFFF)],
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
                                  fontWeight: FontWeight.w500,
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
                        fontSize: screenWidth * 0.045,
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
                                fontSize: screenWidth * 0.045,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w900,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter Your Card Number',
                                hintStyle: TextStyle(
                                  color: Colors.black54,
                                  fontSize: screenWidth * 0.045,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w900,
                                ),
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              cursorColor: Colors.black,
                              keyboardType: TextInputType.number,
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
                        fontSize: screenWidth * 0.045,
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
                                fontSize: screenWidth * 0.045,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w900,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter Your Card Holder Name',
                                hintStyle: TextStyle(
                                  color: Colors.black54,
                                  fontSize: screenWidth * 0.045,
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
                                fontSize: screenWidth * 0.045,
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
                                        fontSize: screenWidth * 0.045,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w900,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '**/**',
                                        hintStyle: TextStyle(
                                          color: Colors.black54,
                                          fontSize: screenWidth * 0.045,
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
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.012),
                            Container(
                              width: screenWidth * (200 / 375),
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
                                        fontSize: screenWidth * 0.045,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w900,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter CVV',
                                        hintStyle: TextStyle(
                                          color: Colors.black54,
                                          fontSize: screenWidth * 0.045,
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
