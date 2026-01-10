import 'package:flutter/material.dart';
import 'package:helper/Auth/OTP_Verification_Screen.dart';
import 'package:helper/Auth/Password_Reset_Screen.dart';
import 'package:helper/Auth/Referral_Code_Screen.dart';
import 'package:helper/Document Upload/Academic_Certificate_Upload_Screen.dart';
import 'package:helper/Document Upload/Add_Profession_Screen.dart';
import 'package:helper/Document Upload/Document_Upload_screen.dart';
import 'package:helper/Document Upload/Face_Scan_Screen.dart';
import 'package:helper/Document Upload/National_ID_Passport_Back_Upload_Screen.dart';
import 'package:helper/Document Upload/National_ID_Passport_Back_Scan_Screen.dart';
import 'package:helper/Document Upload/National_ID_Passport_Front_Scan_Screen.dart';
import 'package:helper/Document Upload/Select_Worker_Type_Screen.dart';
import 'package:helper/Document Upload/Verification_Information_Screen.dart';
import 'package:helper/Payments/Airtel_Payment_Method_Screen.dart';
import 'package:helper/Payments/Mastercard_Payment_Method_Screen.dart';
import 'package:helper/Payments/Registration_Payment_Screen.dart';
import 'package:helper/Payments/Visa_Payment_Method_Screen.dart';
import 'package:helper/intro/Role_Selection_Screen.dart';
import 'package:helper/intro/Splash_Screen.dart';
import 'package:helper/Auth/Phone_Number_&_Email_Address_Screen.dart';
import 'package:helper/Auth/Forgot_Password_Screen.dart';
import 'package:helper/Payments/MTN_Payment_Method_Screen.dart';
import 'package:helper/Document Upload/National_ID_Passport_Front_Upload_Screen.dart';
import 'package:helper/Document Upload/Professional_License_Upload.dart';
import 'package:helper/Document Upload/Selfie_Verification_Upload.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Helper App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SelfieCaptureScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
