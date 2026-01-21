import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'Sign_In_Screen.dart';
import 'Forgot_Password_OTP_Screen.dart';

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

class ForgotYourPasswordScreen extends StatefulWidget {
  const ForgotYourPasswordScreen({super.key});

  @override
  State<ForgotYourPasswordScreen> createState() =>
      _ForgotYourPasswordScreenState();
}

class _ForgotYourPasswordScreenState extends State<ForgotYourPasswordScreen> {
  static const _brandOrange = Color(0xFFFFA10D);

  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    super.dispose();
  }

  String _generateOTP() {
    // Generate a 6-digit OTP
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString();
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    // Send reset OTP then navigate
    final identifier = _identifierCtrl.text.trim();

    try {
      // Generate OTP
      String otpCode = _generateOTP();

      // Store OTP in Firestore
      await FirebaseFirestore.instance
          .collection('Forgot Password OTP')
          .doc(identifier)
          .set({
            'email': identifier,
            'otpCode': otpCode,
            'timestamp': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(minutes: 10)),
            ),
          });

      // Send email via Cloud Function
      print(
        'About to call sendForgotPasswordOTPEmail with email: $identifier, otpCode: $otpCode',
      );
      await FirebaseFunctions.instance
          .httpsCallable('sendForgotPasswordOTPEmail')
          .call({'email': identifier, 'otpCode': otpCode});
      print('sendForgotPasswordOTPEmail call completed successfully');
      print('Forgot Password OTP email sent successfully');

      if (!mounted) return;
      setState(() => _loading = false);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ForgotPasswordOTPScreen(
            isPhoneVerification: false, // email verification
            emailOrPhone: identifier,
            initialVerificationId: '',
          ),
        ),
      );
    } catch (e) {
      print('Error sending OTP: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

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
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: h * 0.05),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Forgot Your Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.085,
                            fontFamily: 'AbrilFatface',
                            height: 1.05,
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.04),

                      // ✅ circle #1 filled orange
                      _MiniStep123(
                        width: w,
                        accent: _brandOrange,
                        activeIndex: 0,
                      ),

                      SizedBox(height: h * 0.02),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Text(
                          'Please enter your email address or\nphone number below to receive an OTP code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                            height: 1.35,
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.04),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.012),

                      _PillInput(
                        controller: _identifierCtrl,
                        hint: 'Enter Your Email Address',
                        icon: Icons.mail_rounded,
                        keyboardType: TextInputType.emailAddress,
                        contentFontSize: w * 0.038,
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) {
                            return 'Please enter a valid email address';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                          if (!emailRegex.hasMatch(t)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        }, obscure: false,
                      ),

                      SizedBox(height: h * 0.05),

                      SizedBox(
                        width: double.infinity,
                        height: h * 0.062,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white.withOpacity(
                              0.6,
                            ),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Submit',
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

                      SizedBox(height: h * 0.12),

                      // ✅ spaced & Sign In smaller
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: w * 0.037,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: w * 0.02), // spacing
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => SignInScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: _brandOrange,
                                fontSize: w * 0.032, // smaller
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
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------- Mini step indicator (1 active filled) ---------------------

class _MiniStep123 extends StatelessWidget {
  final double width;
  final Color accent;
  final int activeIndex; // 0 -> step 1 is active

  const _MiniStep123({
    required this.width,
    required this.accent,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final dotSize = width * 0.04;
    final lineW = width * 0.18;

    Widget circle(int index) {
      final active = index == activeIndex;
      return Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? accent : Colors.transparent, // ✅ fill active
          border: Border.all(color: accent, width: 3),
        ),
      );
    }

    Widget dashed() {
      return SizedBox(
        width: lineW,
        child: CustomPaint(painter: DashedLinePainter(color: accent)),
      );
    }

    Widget num(String n) {
      return Text(
        n,
        style: TextStyle(
          color: accent,
          fontSize: width * 0.03,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Transform.translate(
              offset: Offset(0, -width * 0.01),
              child: circle(0),
            ),
            SizedBox(height: width * 0.01),
            num('1'),
          ],
        ),
        SizedBox(width: width * 0.02),
        Column(children: [dashed()]),
        SizedBox(width: width * 0.02),
        Column(
          children: [
            Transform.translate(
              offset: Offset(0, -width * 0.01),
              child: circle(1),
            ),
            SizedBox(height: width * 0.01),
            num('2'),
          ],
        ),
        SizedBox(width: width * 0.02),
        Column(children: [dashed()]),
        SizedBox(width: width * 0.02),
        Column(
          children: [
            Transform.translate(
              offset: Offset(0, -width * 0.01),
              child: circle(2),
            ),
            SizedBox(height: width * 0.01),
            num('3'),
          ],
        ),
      ],
    );
  }
}

// --------------------- Input pill ---------------------

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

  const _PillInput({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    this.contentFontSize = 16.0,
    this.validator,
<<<<<<< HEAD
<<<<<<< HEAD
=======
    this.inputFormatters,
>>>>>>> 471e8036e44ef2563c1cbded648c421a861cf700
=======
    this.inputFormatters, required this.obscure, this.suffix,
>>>>>>> 3f164284aacd06766eab331bc31cdc9ab8cffcb4
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
              style: TextStyle(
                color: Colors.white,
                fontSize: contentFontSize,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
              cursorColor: const Color(0xFFFFA10D),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.65),
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

// --------------------- Helpers ---------------------

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: size * 0.45),
        ),
      ),
    );
  }
}
