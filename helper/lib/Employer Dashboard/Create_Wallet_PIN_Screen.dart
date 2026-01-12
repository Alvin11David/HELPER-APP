import 'package:flutter/material.dart';

class CreateWalletPINScreen extends StatefulWidget {
  const CreateWalletPINScreen({super.key});

  @override
  State<CreateWalletPINScreen> createState() => _CreateWalletPINScreenState();
}

class _CreateWalletPINScreenState extends State<CreateWalletPINScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/normalscreenbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            const Center(child: Text('Create Wallet PIN Screen')),
            Positioned(
              top: screenWidth * 0.1,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
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
                        'Create Wallet PIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
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
    );
  }
}
