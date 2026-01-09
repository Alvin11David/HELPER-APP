// national_id_passport_upload_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class NationalIdPassportUploadScreen extends StatefulWidget {
  const NationalIdPassportUploadScreen({super.key});

  @override
  State<NationalIdPassportUploadScreen> createState() =>
      _NationalIdPassportUploadScreenState();
}

class _NationalIdPassportUploadScreenState
    extends State<NationalIdPassportUploadScreen> {
  static const _brandYellow = Color(0xFFFFC700);

  bool _isNationalId = true; // National ID / Passport
  bool _isFrontSide = true; // Front / Back

  String get _docTypeText => _isNationalId ? 'ID' : 'passport';
  String get _sideText => _isFrontSide ? 'front' : 'back';

  String get _uploadHintText =>
      'Upload the $_sideText part of your $_docTypeText';

  void _pickCamera() {
    // TODO: integrate camera
  }

  void _pickGallery() {
    // TODO: integrate gallery picker
  }

  void _selectNationalId() {
    setState(() => _isNationalId = true);
  }

  void _selectPassport() {
    setState(() => _isNationalId = false);
  }

  void _selectFront() {
    setState(() => _isFrontSide = true);
  }

  void _selectBack() {
    setState(() => _isFrontSide = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final titleSize = w * 0.048;
    final pillText = w * 0.028;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Header row (back + title)
              Positioned(
                    top: screenHeight * 0.04,
                    left: screenWidth * 0.04,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: screenWidth * 0.13,
                            height: screenWidth * 0.13,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.chevron_left,
                                color: Colors.black,
                                size: screenWidth * 0.10,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.06),
                        Text(
                          'National ID/Passport',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
              // Main content
              Positioned(
                top: h * 0.16,
                left: w * 0.06,
                right: w * 0.06,
                bottom: h * 0.04,
                child: Column(
                  children: [
                    // ✅ Dynamic glass pill text
                    _GlassPill(
                      width: double.infinity,
                      radius: 22,
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.05,
                        vertical: h * 0.010,
                      ),
                      child: Text(
                        _uploadHintText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: pillText,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.018),

                    // Toggle (National ID / Passport)
                    _TogglePill(
                      w: w,
                      h: h,
                      leftText: 'National ID',
                      rightText: 'Passport',
                      leftSelected: _isNationalId,
                      onSelectLeft: _selectNationalId,
                      onSelectRight: _selectPassport,
                      leftIcon: 'assets/icons/nationalid.png',
                      rightIcon: 'assets/icons/verify.png',
                    ),

                    SizedBox(height: h * 0.03),

                    // Preview frame + image
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _PreviewFrame(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                child: Image.asset(
                                  _isFrontSide
                                      ? 'assets/images/front.png'
                                      : 'assets/images/back.png',
                                  key: ValueKey(_isFrontSide),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: h * 0.02),

                          Text(
                            _isFrontSide ? 'Front Side' : 'Back Side',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'AbrilFatface',
                              fontSize: w * 0.05,
                            ),
                          ),

                          SizedBox(height: h * 0.016),

                          _PrimaryButton(
                            w: w,
                            h: h,
                            text: 'Take a photo',
                            icon: Icons.photo_camera_rounded,
                            onTap: _pickCamera,
                            background: _brandYellow,
                            textColor: Colors.black,
                            iconColor: Colors.black,
                          ),

                          SizedBox(height: h * 0.014),

                          _PrimaryButton(
                            w: w,
                            h: h,
                            text: 'Gallery',
                            icon: Icons.photo_library_rounded,
                            onTap: _pickGallery,
                            background: Colors.white,
                            textColor: Colors.black,
                            iconColor: Colors.black,
                          ),

                          SizedBox(height: h * 0.012),

                          // ✅ Front / Back controls that update the sentence too
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MiniChip(
                                text: 'Front',
                                selected: _isFrontSide,
                                onTap: _selectFront,
                              ),
                              SizedBox(width: w * 0.03),
                              _MiniChip(
                                text: 'Back',
                                selected: !_isFrontSide,
                                onTap: _selectBack,
                              ),
                            ],
                          ),
                        ],
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

// ------------------ UI pieces ------------------

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
    return ClipRRect(
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
                Colors.white.withOpacity(0.22),
                Colors.white.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.08),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final double w;
  final double h;
  final String leftText;
  final String rightText;
  final bool leftSelected;
  final VoidCallback onSelectLeft;
  final VoidCallback onSelectRight;
  final String leftIcon;
  final String rightIcon;

  const _TogglePill({
    required this.w,
    required this.h,
    required this.leftText,
    required this.rightText,
    required this.leftSelected,
    required this.onSelectLeft,
    required this.onSelectRight,
    required this.leftIcon,
    required this.rightIcon,
  });

  @override
  Widget build(BuildContext context) {
    final pillH = h * 0.055;

    return Container(
      height: pillH,
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.01),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.4),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSelectLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: leftSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(leftIcon, width: w * 0.05, height: w * 0.05),
                    SizedBox(width: w * 0.02),
                    Text(
                      leftText,
                      style: TextStyle(
                        color: leftSelected ? Colors.black : Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onSelectRight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: leftSelected ? Colors.transparent : Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(rightIcon, width: w * 0.05, height: w * 0.05),
                    SizedBox(width: w * 0.02),
                    Text(
                      rightText,
                      style: TextStyle(
                        color: leftSelected ? Colors.white : Colors.black,
                        fontFamily: 'Poppins',
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  final Widget child;
  const _PreviewFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: w * 0.02),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.65), width: 1.6),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _CornerPainter())),
          Center(child: child),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const corner = 18.0;

    canvas.drawLine(const Offset(0, 0), const Offset(corner, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, corner), paint);

    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width - corner, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, corner), paint);

    canvas.drawLine(
        Offset(0, size.height), Offset(corner, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - corner), paint);

    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - corner, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - corner), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PrimaryButton extends StatelessWidget {
  final double w;
  final double h;
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color textColor;
  final Color iconColor;

  const _PrimaryButton({
    required this.w,
    required this.h,
    required this.text,
    required this.icon,
    required this.onTap,
    required this.background,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: h * 0.065,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: w * 0.055),
            SizedBox(width: w * 0.02),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontFamily: 'Poppins',
                fontSize: w * 0.045,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _MiniChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.02),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
            width: 1.2,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: w * 0.034,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
