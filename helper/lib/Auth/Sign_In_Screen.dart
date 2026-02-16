import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:helper/Auth/Forgot_Password_Screen.dart';
import 'package:helper/Employer%20Dashboard/Employer_Dashboard_Screen.dart';
import 'package:helper/Intro/Role_Selection_Screen.dart';
import 'package:helper/Worker%20Dashboard/Workers_Dashboard_Screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import 'Phone_Number_&_Email_Address_Screen.dart';
import 'Referral_Code_Screen.dart';

class _UgandaPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty || !newValue.text.startsWith('+256 ')) {
      return const TextEditingValue(
        text: '+256 ',
        selection: TextSelection.collapsed(offset: 5),
      );
    }

    final digitsOnly = newValue.text
        .substring(5)
        .replaceAll(RegExp(r'[^0-9]'), '');

    final limitedDigits = digitsOnly.length > 9
        ? digitsOnly.substring(0, 9)
        : digitsOnly;

    final formattedText = '+256 $limitedDigits';

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) => false;
}

enum _AuthMode { phone, email }

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  static const _brandOrange = Color(0xFFFFA10D);
  static const _pureWhite = Color(0xFFFFFFFF);

  _AuthMode _mode = _AuthMode.phone;

  final _formKey = GlobalKey<FormState>();

  final _phoneCtrl = TextEditingController(text: '+256 ');
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  String? _verificationId; // phone

  @override
  void initState() {
    super.initState();
    _loadLastInputs();
    _phoneCtrl.addListener(_saveInputs);
    _emailCtrl.addListener(_saveInputs);
    _passwordCtrl.addListener(_saveInputs);
  }

  Future<void> _loadLastInputs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _phoneCtrl.text = prefs.getString('last_phone') ?? '+256 ';
      _emailCtrl.text = prefs.getString('last_email') ?? '';
      _passwordCtrl.text = prefs.getString('last_password') ?? '';
    });
  }

  Future<void> _saveInputs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_phone', _phoneCtrl.text);
    await prefs.setString('last_email', _emailCtrl.text);
    await prefs.setString('last_password', _passwordCtrl.text);
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_saveInputs);
    _emailCtrl.removeListener(_saveInputs);
    _passwordCtrl.removeListener(_saveInputs);

    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();

    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode m) {
    if (_mode == m) return;
    FocusScope.of(context).unfocus();
    setState(() => _mode = m);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: Colors.black.withOpacity(0.85),
      ),
    );
  }

  // ✅ format UI "+256 7XXXXXXXX" -> "+2567XXXXXXXX"
  String _normalizeUgPhone(String uiPhone) {
    var phone = uiPhone.trim();
    if (!phone.startsWith('+256 ') || phone.length != 14) return '';
    phone = phone.replaceAll(' ', ''); // +2567xxxxxxxx
    if (!phone.startsWith('+256') || phone.length != 13) return '';
    return phone;
  }

  String _generateReferralCode() {
    final random = Random();
    final digits1 = (100 + random.nextInt(900)).toString(); // 3 digits
    final letters = String.fromCharCodes([
      65 + random.nextInt(26), // A-Z
      65 + random.nextInt(26),
    ]);
    final digits2 = (100 + random.nextInt(900)).toString(); // 3 digits
    return 'UG$digits1$letters$digits2';
  }

  // ✅ Ensures Firestore doc: Sign Up/{uid} exists (for avatars/profile reads)
  Future<void> _ensureUserDocExists(
    User user, {
    required String provider,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('Sign Up')
        .doc(user.uid);
    final snap = await docRef.get();
    if (snap.exists) return;

    // Get FCM token
    String? fcmToken;
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      fcmToken = await messaging.getToken();
    } catch (e) {
      // Handle error if needed, but continue without FCM token
      fcmToken = null;
    }

    // Best-effort: recover from older .add() docs
    String fullName = user.displayName ?? '';
    String email = user.email ?? '';
    String phone = user.phoneNumber ?? '';
    String photoUrl = user.photoURL ?? '';

    try {
      if (email.isNotEmpty) {
        final q = await FirebaseFirestore.instance
            .collection('Sign Up')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          final d = q.docs.first.data();
          fullName = (d['fullName'] ?? fullName).toString();
          phone = (d['phoneNumber'] ?? phone).toString();
          photoUrl = (d['photoUrl'] ?? photoUrl).toString();
          provider = (d['provider'] ?? provider).toString();
        }
      } else if (phone.isNotEmpty) {
        final q = await FirebaseFirestore.instance
            .collection('Sign Up')
            .where('phoneNumber', isEqualTo: phone)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          final d = q.docs.first.data();
          fullName = (d['fullName'] ?? fullName).toString();
          email = (d['email'] ?? email).toString();
          photoUrl = (d['photoUrl'] ?? photoUrl).toString();
          provider = (d['provider'] ?? provider).toString();
        }
      }
    } catch (_) {}

    final payload = {
      'uid': user.uid,
      'provider': provider,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phone,
      'photoUrl': photoUrl,
      'verified': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (fcmToken != null) {
      payload['fcmToken'] = fcmToken;
    }

    await docRef.set(payload, SetOptions(merge: true));
  }

  Future<void> _goToDashboard() async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get user role from Firestore
    final docSnap = await FirebaseFirestore.instance
        .collection('Sign Up')
        .doc(user.uid)
        .get();

    final role = docSnap.data()?['role'] ?? '';

    Widget dashboard;
    if (role == 'worker') {
      dashboard = const WorkersDashboardScreen();
    } else if (role == 'employer') {
      dashboard = const EmployerDashboardScreen();
    } else {
      // No role set, go to role selection
      dashboard = const RoleSelectionScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => dashboard),
      (_) => false,
    );
  }

  // ✅ EMAIL SIGN IN: real FirebaseAuth sign in
  Future<void> _emailSignIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) throw Exception('No user returned.');

    await _ensureUserDocExists(user, provider: 'email');
    await _goToDashboard();
  }

  // ✅ PHONE SIGN IN: send OTP via FirebaseAuth.verifyPhoneNumber then go OTP screen
  Future<void> _phoneSignIn() async {
    final phoneUi = _phoneCtrl.text.trim();
    final phone = _normalizeUgPhone(phoneUi);

    if (phone.isEmpty) {
      _toast('Please enter a valid phone number in format +256 XXXXXXXXX');
      return;
    }

    // Check if phone exists in Sign Up collection
    final snap = await FirebaseFirestore.instance
        .collection('Sign Up')
        .where('phoneNumber', isEqualTo: phone)
        .where('verified', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      _toast('Phone number not registered. Please sign up.');
      setState(() => _loading = false);
      return;
    }

    // Sign in with email auth
    final email = '${phone.replaceAll('+', '').replaceAll(' ', '')}@helper.com';
    try {
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: 'phoneauth',
      );
      final user = userCred.user;
      if (user != null) {
        await _ensureUserDocExists(user, provider: 'phone');
        setState(() => _loading = false);
        await _goToDashboard();
      } else {
        _toast('Sign in failed.');
        setState(() => _loading = false);
      }
    } catch (e) {
      _toast('Sign in error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _onContinue() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      if (_mode == _AuthMode.email) {
        await _emailSignIn();
      } else {
        await _phoneSignIn();
      }

      if (mounted) setState(() => _loading = false);
    } on FirebaseAuthException catch (e) {
      final msg = (e.code == 'user-not-found' || e.code == 'wrong-password')
          ? 'Wrong email or password.'
          : (e.message ?? 'Sign in failed.');
      _toast(msg);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      _toast('Sign in error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ Google sign-in uses FirebaseAuth
  Future<void> _onGoogle() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      UserCredential userCred;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.setCustomParameters({'prompt': 'select_account'});
        userCred = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          if (mounted) setState(() => _loading = false);
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final user = userCred.user;
      if (user == null) throw Exception('Google sign-in failed (no user).');

      await _saveGoogleUserToFirestore(user);

      if (!mounted) return;
      setState(() => _loading = false);

      // Check if user has a role set
      final docSnap = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .get();

      final role = docSnap.data()?['role'] ?? '';

      if (role.isEmpty) {
        // No role set, go to role selection
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          (_) => false,
        );
      } else {
        // Has role, go to appropriate dashboard
        await _goToDashboard();
      }
    } catch (e) {
      if (!mounted) return;
      _toast('Google sign-in failed: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveGoogleUserToFirestore(User user) async {
    final signUpCol = FirebaseFirestore.instance.collection('Sign Up');
    final docRef = signUpCol.doc(user.uid);
    final snap = await docRef.get();

    // Get FCM token
    String? fcmToken;
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      fcmToken = await messaging.getToken();
    } catch (e) {
      // Handle error if needed, but continue without FCM token
      fcmToken = null;
    }

    final payload = <String, dynamic>{
      'uid': user.uid,
      'provider': 'google',
      'email': user.email ?? '',
      'fullName': user.displayName ?? '',
      'photoUrl': user.photoURL ?? '',
      'phoneNumber': user.phoneNumber ?? '',
      'referralCode': _generateReferralCode(),
      'verified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (fcmToken != null) {
      payload['fcmToken'] = fcmToken;
    }

    if (!snap.exists) {
      // New user - set default empty role
      payload['role'] = '';
      await docRef.set({...payload, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      // Existing user - don't overwrite role if it exists, but update FCM token
      final existingData = snap.data();
      if (existingData != null &&
          existingData['role'] != null &&
          existingData['role'].toString().isNotEmpty) {
        // Keep existing role
      } else {
        // No role set yet, set to empty
        payload['role'] = '';
      }
      await docRef.set(payload, SetOptions(merge: true));
    }
  }

  void _onReferralCodeTap() async {
    String identifier;
    String? referralCode;

    if (_mode == _AuthMode.phone) {
      String phoneNumber = _phoneCtrl.text.trim();
      if (!phoneNumber.startsWith('+256 ') || phoneNumber.length != 14) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReferralCodeScreen()),
        );
        return;
      }
      phoneNumber = phoneNumber.replaceAll(' ', '');
      if (!phoneNumber.startsWith('+256') || phoneNumber.length != 13) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReferralCodeScreen()),
        );
        return;
      }

      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('Sign Up')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        referralCode = (doc['referralCode'] ?? '').toString();
      }
    } else {
      identifier = _emailCtrl.text.trim();
      if (identifier.isEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReferralCodeScreen()),
        );
        return;
      }

      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('Sign Up')
          .where('email', isEqualTo: identifier)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        referralCode = (doc['referralCode'] ?? '').toString();
      }
    }

    if (referralCode != null && referralCode.toString().isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.045,
              right: MediaQuery.of(context).size.width * 0.045,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.06,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Your Referral Code Is:',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Text(
                      referralCode!,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.08,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFA10D),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReferralCodeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final sidePad = w * 0.045;

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
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sidePad),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            SizedBox(height: h * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/logo.png',
                                  width: w * 0.09,
                                  height: w * 0.09,
                                ),
                                SizedBox(width: w * 0.02),
                                Text(
                                  'Helper',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: w * 0.05,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h * 0.05),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: w * 0.09,
                                  fontFamily: 'AbrilFatface',
                                  height: 1.05,
                                ),
                              ),
                            ),
                            SizedBox(height: h * 0.03),
                            _GlassPill(
                              radius: 30,
                              padding: EdgeInsets.symmetric(
                                horizontal: w * 0.05,
                                vertical: h * 0.006,
                              ),
                              child: Text(
                                _mode == _AuthMode.phone
                                    ? 'Enter your Phone Number'
                                    : 'Enter your Email Address',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: w * 0.04,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            SizedBox(height: h * 0.02),
                            _SmoothAuthSwitch(
                              height: h * 0.065,
                              mode: _mode,
                              onChanged: _switchMode,
                            ),
                            SizedBox(height: h * 0.02),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, anim) {
                                final slide =
                                    Tween<Offset>(
                                      begin: const Offset(0.02, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOut,
                                      ),
                                    );
                                return FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: slide,
                                    child: child,
                                  ),
                                );
                              },
                              child: _mode == _AuthMode.phone
                                  ? _PhoneBlock(
                                      key: const ValueKey('phoneBlock'),
                                      phoneCtrl: _phoneCtrl,
                                    )
                                  : _EmailBlock(
                                      key: const ValueKey('emailBlock'),
                                      emailCtrl: _emailCtrl,
                                      passwordCtrl: _passwordCtrl,
                                      obscure: _obscure,
                                      onToggleObscure: () =>
                                          setState(() => _obscure = !_obscure),
                                      emailFocusNode: _emailFocusNode,
                                      passwordFocusNode: _passwordFocusNode,
                                    ),
                            ),
                            SizedBox(height: h * 0.025),
                            SizedBox(
                              width: double.infinity,
                              height: h * 0.062,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _onContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _pureWhite,
                                  disabledBackgroundColor: _pureWhite
                                      .withOpacity(0.6),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _loading
                                    ? SizedBox(
                                        width: h * 0.03,
                                        height: h * 0.03,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Continue',
                                            style: TextStyle(
                                              fontSize: w * 0.045,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                          SizedBox(width: w * 0.02),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.black,
                                            size: h * 0.035,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            if (_mode == _AuthMode.email) ...[
                              SizedBox(height: h * 0.02),
                              _OrDivider(),
                              SizedBox(height: h * 0.02),
                              SizedBox(
                                width: double.infinity,
                                height: h * 0.062,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _onGoogle,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _pureWhite,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _GoogleIconSlot(size: w * 0.065),
                                      SizedBox(width: w * 0.025),
                                      Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: w * 0.042,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Inter',
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: h * 0.07),
                            if (_mode == _AuthMode.phone)
                              Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.045,
                                    vertical: h * 0.01,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.25),
                                    ),
                                  ),
                                  child: Text(
                                    'Your phone number is safe and will not be shared. Standard SMS charges may apply.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: w * 0.032,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(height: h * 0.03),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Don\'t have an account?',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: w * 0.037,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: w * 0.02),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PhoneNumberEmailAddressScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: _brandOrange,
                                      fontSize: w * 0.032,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h * 0.03),
                          ],
                        ),
                      ),
                    ),
                    // Back button
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------- Blocks ---------------------

class _PhoneBlock extends StatelessWidget {
  final TextEditingController phoneCtrl;

  const _PhoneBlock({super.key, required this.phoneCtrl});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            color: Colors.white,
            fontSize: w * 0.040,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: h * 0.012),
        _PillInput(
          controller: phoneCtrl,
          hint: '+256 712345678',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [_UgandaPhoneFormatter()],
          contentFontSize: w * 0.038,
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Phone number is required';
            if (!t.startsWith('+256 ')) {
              return 'Phone number must start with +256';
            }
            final digits = t.substring(5);
            if (digits.length != 9) return 'Enter exactly 9 digits after +256';
            if (!RegExp(r'^[0-9]{9}$').hasMatch(digits)) {
              return 'Enter valid 9-digit number';
            }
            return null;
          },
        ),
        SizedBox(height: h * 0.014),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              final state = context
                  .findAncestorStateOfType<_SignInScreenState>();
              state?._onReferralCodeTap();
            },
            child: Text(
              'Referral Code?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: w * 0.035,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailBlock extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;

  const _EmailBlock({
    super.key,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.emailFocusNode,
    required this.passwordFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: TextStyle(
            color: Colors.white,
            fontSize: w * 0.040,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: h * 0.012),
        _PillInput(
          controller: emailCtrl,
          hint: 'Enter Your Email Address',
          icon: Icons.mail_rounded,
          keyboardType: TextInputType.emailAddress,
          contentFontSize: w * 0.038,
          validator: (v) {
            final t = (v ?? '').trim();
            if (t.isEmpty) return 'Email is required';
            final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
            if (!ok) return 'Enter a valid email';
            return null;
          },
          focusNode: emailFocusNode,
          onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
        ),
        SizedBox(height: h * 0.018),
        Text(
          'Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: w * 0.040,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        SizedBox(height: h * 0.012),
        _PillInput(
          controller: passwordCtrl,
          hint: 'Enter Your Password',
          icon: Icons.lock_rounded,
          keyboardType: TextInputType.visiblePassword,
          obscure: obscure,
          contentFontSize: w * 0.038,
          suffix: IconButton(
            onPressed: onToggleObscure,
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          validator: (v) {
            final t = (v ?? '');
            if (t.isEmpty) return 'Password is required';
            if (t.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
          focusNode: passwordFocusNode,
        ),
        SizedBox(height: h * 0.014),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                final state = context
                    .findAncestorStateOfType<_SignInScreenState>();
                state?._onReferralCodeTap();
              },
              child: Text(
                'Referral Code?',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: w * 0.035,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ForgotYourPasswordScreen(),
                  ),
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: w * 0.035,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --------------------- Switch ---------------------

class _SmoothAuthSwitch extends StatelessWidget {
  final double height;
  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

  const _SmoothAuthSwitch({
    required this.height,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final radius = height / 2;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentW = constraints.maxWidth / 2;

          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 230),
                curve: Curves.easeOut,
                alignment: mode == _AuthMode.phone
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: segmentW,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(radius),
                      onTap: () => onChanged(_AuthMode.phone),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: w * 0.06,
                              color: mode == _AuthMode.phone
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            SizedBox(width: w * 0.02),
                            Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: w * 0.044,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Inter',
                                color: mode == _AuthMode.phone
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(radius),
                      onTap: () => onChanged(_AuthMode.email),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mail_rounded,
                              size: w * 0.06,
                              color: mode == _AuthMode.email
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            SizedBox(width: w * 0.02),
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: w * 0.044,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Inter',
                                color: mode == _AuthMode.email
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// --------------------- Input ---------------------

class _PillInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  final double contentFontSize;

  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;

  const _PillInput({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    required this.contentFontSize,
    this.obscure = false,
    this.suffix,
    this.inputFormatters,
    this.validator,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final fieldH = h * 0.065;
    final radius = fieldH / 2;

    return Container(
      height: fieldH,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        children: [
          SizedBox(width: w * 0.04),
          Icon(icon, color: Colors.white, size: w * 0.06),
          SizedBox(width: w * 0.025),
          Container(
            width: 1.2,
            height: fieldH * 0.55,
            color: Colors.white.withOpacity(0.6),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              focusNode: focusNode,
              onFieldSubmitted: onFieldSubmitted,
              style: TextStyle(
                color: Colors.white,
                fontSize: contentFontSize,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
              cursorColor: const Color(0xFFFFA10D),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: contentFontSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.only(
                  top: fieldH * 0.20,
                  bottom: fieldH * 0.20,
                ),
              ),
            ),
          ),
          if (suffix != null)
            Padding(
              padding: EdgeInsets.only(right: w * 0.02),
              child: suffix!,
            )
          else
            SizedBox(width: w * 0.02),
        ],
      ),
    );
  }
}

// --------------------- OR divider ---------------------

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.25)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.03),
          child: Text(
            'Or',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: w * 0.035,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: Colors.white.withOpacity(0.25)),
        ),
      ],
    );
  }
}

// --------------------- Google icon slot ---------------------

class _GoogleIconSlot extends StatelessWidget {
  final double size;
  const _GoogleIconSlot({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/google.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
    );
  }
}

// --------------------- Glass pill ---------------------

class _GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const _GlassPill({
    required this.child,
    required this.padding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
