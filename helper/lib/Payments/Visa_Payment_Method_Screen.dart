import 'package:flutter/material.dart';

class VisaPaymentMethodScreen extends StatelessWidget {
  const VisaPaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
