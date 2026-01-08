// payment_method_screen.dart
// ✅ Responsive
// ✅ AbrilFatface for headings, Poppins for everything else
// ✅ Glassmorphism pill for "Instant Confirmation"
// ✅ Mastercard icon positioned like your screenshot (left badge on top gradient card)
// ✅ Uses your existing bg: assets/background/normalscreenbg.png
// ✅ Uses your mastercard image: assets/images/mastercard.png

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cardNumberCtrl = TextEditingController();
  final _cardHolderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  bool _saveCard = false;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardHolderCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  void _onPay() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // TODO: process payment
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/normalscreenbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.02),

                  // Header row: back + centered title spacer
                  Row(
                    children: [
                      _BackSquareButton(
                        size: w * 0.12,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Payment Method',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'AbrilFatface',
                              fontSize: w * 0.065,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: w * 0.12),
                    ],
                  ),

                  SizedBox(height: h * 0.03),

                  // Top gradient card
                  _PaymentSummaryCard(
                    width: w,
                    height: h,
                    brandText: 'Master Card',
                    amountLabel: 'Amount',
                    amount: 'UGX 25,000',
                    badgeText: 'Not Paid',
                    brandImagePath: 'assets/images/mastercard.png',
                  ),

                  SizedBox(height: h * 0.03),

                  Text(
                    'Card Number',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'Poppins',
                      fontSize: w * 0.036,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: h * 0.01),
                  _WhiteInput(
                    controller: _cardNumberCtrl,
                    hint: 'Enter Your Card Number',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(19),
                    ],
                    suffix: _SmallBrandChip(
                      child: Image.asset(
                        'assets/images/mastercard.png',
                        width: w * 0.06,
                        height: w * 0.06,
                        fit: BoxFit.contain,
                      ),
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Card number is required';
                      if (t.replaceAll(' ', '').length < 12) {
                        return 'Enter a valid card number';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: h * 0.018),

                  Text(
                    'Card Holder Name',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'Poppins',
                      fontSize: w * 0.036,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: h * 0.01),
                  _WhiteInput(
                    controller: _cardHolderCtrl,
                    hint: 'Enter Your Card Holder Name',
                    keyboardType: TextInputType.name,
                    suffix: _SmallIconChip(
                      icon: Icons.person_rounded,
                      size: w * 0.055,
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Card holder name is required';
                      return null;
                    },
                  ),

                  SizedBox(height: h * 0.02),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expires on',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontFamily: 'Poppins',
                                fontSize: w * 0.036,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: h * 0.01),
                            _WhiteInput(
                              controller: _expiryCtrl,
                              hint: '**/**',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9/]'),
                                ),
                                LengthLimitingTextInputFormatter(5),
                              ],
                              suffix: _SmallIconChip(
                                icon: Icons.calendar_month_rounded,
                                size: w * 0.055,
                              ),
                              validator: (v) {
                                final t = (v ?? '').trim();
                                if (t.isEmpty) return 'Required';
                                if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(t)) {
                                  return 'MM/YY';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: w * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '3-digit cvv',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontFamily: 'Poppins',
                                fontSize: w * 0.036,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: h * 0.01),
                            _WhiteInput(
                              controller: _cvvCtrl,
                              hint: 'Enter CVV',
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              suffix: _TextChip(text: '123'),
                              validator: (v) {
                                final t = (v ?? '').trim();
                                if (t.isEmpty) return 'Required';
                                if (t.length != 3) return '3 digits';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h * 0.02),

                  Row(
                    children: [
                      Transform.scale(
                        scale: 1.05,
                        child: Checkbox(
                          value: _saveCard,
                          onChanged: (v) => setState(() => _saveCard = v ?? false),
                          side: BorderSide(color: Colors.white.withOpacity(0.8)),
                          activeColor: Colors.white,
                          checkColor: Colors.black,
                        ),
                      ),
                      Text(
                        'save card for future',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: 'Poppins',
                          fontSize: w * 0.036,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h * 0.02),

                  // Pay button (white)
                  SizedBox(
                    width: double.infinity,
                    height: h * 0.062,
                    child: ElevatedButton(
                      onPressed: _onPay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pay',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Poppins',
                              fontSize: w * 0.045,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: w * 0.03),
                          Icon(Icons.login_rounded,
                              color: Colors.black, size: h * 0.03),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  // Glassmorphism "Instant Confirmation"
                  _GlassPill(
                    width: w * 0.56,
                    radius: 30,
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.05,
                      vertical: h * 0.009,
                    ),
                    child: Text(
                      'Instant Confirmation',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: 'Poppins',
                        fontSize: w * 0.032,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- UI Pieces ----------------

class _BackSquareButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _BackSquareButton({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Icon(
            Icons.chevron_left,
            color: Colors.black,
            size: size * 0.8,
          ),
        ),
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  final double width;
  final double height;
  final String brandText;
  final String amountLabel;
  final String amount;
  final String badgeText;
  final String brandImagePath;

  const _PaymentSummaryCard({
    required this.width,
    required this.height,
    required this.brandText,
    required this.amountLabel,
    required this.amount,
    required this.badgeText,
    required this.brandImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final w = width;
    final h = height;
    final cardH = h * 0.16;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          height: cardH,
          padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.02),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFF6B12B),
                Color(0xFFFF3B2F),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: cardH * 0.12),
              Text(
                brandText,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Poppins',
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: cardH * 0.05),
              Text(
                amountLabel,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.85),
                  fontFamily: 'Poppins',
                  fontSize: w * 0.032,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: cardH * 0.02),
              Text(
                amount,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'AbrilFatface',
                  fontSize: w * 0.07,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),

        // Mastercard badge (positioned like screenshot)
        Positioned(
          top: cardH * 0.18,
          left: w * 0.03,
          child: Container(
            width: w * 0.12,
            height: w * 0.12,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                brandImagePath,
                width: w * 0.08,
                height: w * 0.08,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Not Paid badge (bottom right)
        Positioned(
          right: w * 0.04,
          bottom: cardH * 0.15,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.035,
              vertical: h * 0.006,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Poppins',
                fontSize: w * 0.03,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WhiteInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final bool obscureText;

  const _WhiteInput({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.inputFormatters,
    this.suffix,
    this.validator,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final fieldH = h * 0.055;
    final radius = fieldH / 2;

    return Container(
      height: fieldH,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          SizedBox(width: w * 0.04),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              obscureText: obscureText,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Poppins',
                fontSize: w * 0.036,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.55),
                  fontFamily: 'Poppins',
                  fontSize: w * 0.034,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (suffix != null) ...[
            Padding(
              padding: EdgeInsets.only(right: w * 0.03),
              child: suffix!,
            )
          ] else
            SizedBox(width: w * 0.03),
        ],
      ),
    );
  }
}

class _SmallBrandChip extends StatelessWidget {
  final Widget child;
  const _SmallBrandChip({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _SmallIconChip extends StatelessWidget {
  final IconData icon;
  final double size;

  const _SmallIconChip({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: Colors.black, size: size);
  }
}

class _TextChip extends StatelessWidget {
  final String text;
  const _TextChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double width;

  const _GlassPill({
    required this.child,
    required this.padding,
    required this.radius,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: width,
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.20),
                  Colors.white.withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.06),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
