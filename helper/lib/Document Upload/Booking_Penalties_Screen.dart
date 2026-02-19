import 'package:flutter/material.dart';

class BookingPenaltiesScreen extends StatelessWidget {
  const BookingPenaltiesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Penalties')),
      body: Center(child: Text('No penalties to display.')),
    );
  }
}
