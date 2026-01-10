import 'package:flutter/material.dart';

class AddAcademicDocumentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/normalscreenbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Text('Add Academic Document Screen'),
        ),
      ),
    );
  }
}
