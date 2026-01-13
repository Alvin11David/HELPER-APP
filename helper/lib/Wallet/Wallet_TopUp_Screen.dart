import 'package:flutter/material.dart';

class WalletTopUpScreen extends StatelessWidget {
  const WalletTopUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/normalscreenbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Center(child: Text('Wallet Top Up Screen')),
      ),
    );
  }
}
