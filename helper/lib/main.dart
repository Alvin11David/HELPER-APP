import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:helper/Chats/Chat_List_Screen.dart';
import 'package:helper/Chats/Chat_Screen.dart';
import 'package:helper/Employer%20Dashboard/All_Categories_Screen.dart';
import 'package:helper/Employer%20Dashboard/Create_Wallet_PIN_Screen.dart';
import 'package:helper/Employer%20Dashboard/Set_New_Wallet_PIN_Screen.dart';
import 'package:helper/Wallet/Wallet_Cancelled_screen.dart';
import 'package:helper/Wallet/Wallet_Deposit_Payment_Method_Screen.dart';
import 'package:helper/Wallet/Wallet_TopUp_Screen.dart';
import 'package:helper/Wallet/Wallet_Withdraw_Screen.dart';
import 'package:helper/Worker%20Dashboard/Worker_Details_Screen.dart';
import 'package:helper/Worker%20Dashboard/Worker_Jobs_Hub_Screen';
import 'package:helper/Worker%20Dashboard/Workers_Dashboard_Screen.dart';
import 'package:helper/Worker%20Dashboard/Active_Job_detail.dart';
import 'package:helper/Worker%20Dashboard/Workers_Earning_Detail_Screen.dart';
import 'package:helper/Worker%20Dashboard/Workers_Reschedule_screen.dart';
//import 'package:helper/Worker%20Dashboard/Worker_Jobs_Hub_Screen.dart';
import 'package:helper/Worker%20Dashboard/Workers_skills_and_Job_Details.dart';
import 'firebase_options.dart';
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
import 'package:helper/Employer%20Dashboard/Employer_Dashboard_Screen.dart';
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

final GlobalKey<NavigatorState> appNavKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavKey,
      debugShowCheckedModeBanner: false,
      title: 'Helper App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:  VerificationInformationScreen(),
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