import 'package:flutter/material.dart';

class WalletTopUpScreen extends StatelessWidget {
  const WalletTopUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
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
                      'Top Up Wallet',
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
        ],
      ),
    );
  }
}
