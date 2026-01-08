import 'package:flutter/material.dart';

class VerificationInformationScreen extends StatefulWidget {
  const VerificationInformationScreen({super.key});

  @override
  State<VerificationInformationScreen> createState() =>
      _VerificationInformationScreenState();
}

class _VerificationInformationScreenState
    extends State<VerificationInformationScreen> {
  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: h * 0.04,
                left: w * 0.04,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: w * 0.13,
                    height: w * 0.13,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.black,
                        size: w * 0.10,
                      ),
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child: Column(
                  children: [
                    SizedBox(height: h * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/logo.png',
                          width: w * 0.08,
                          height: w * 0.08,
                        ),
                        SizedBox(width: w * 0.03),
                        Text(
                          'Helper',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.055,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.05),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'What type of worker\nare you?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.085,
                          fontFamily: 'AbrilFatface',
                          height: 1.05,
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
