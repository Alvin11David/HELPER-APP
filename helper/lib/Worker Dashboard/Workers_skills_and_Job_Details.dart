import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WorkerSkillsJobDetailsScreen extends StatefulWidget {
  const WorkerSkillsJobDetailsScreen({super.key});

  @override
  State<WorkerSkillsJobDetailsScreen> createState() =>
      _WorkerSkillsJobDetailsScreenState();
}

class _WorkerSkillsJobDetailsScreenState extends State<WorkerSkillsJobDetailsScreen> {
  static const _brandOrange = Color(0xFFFFA10D);

  int _step = 0; // 0,1,2

  final _formStep1 = GlobalKey<FormState>();
  final _formStep2 = GlobalKey<FormState>();

  // Step 1 controllers
  String? _jobCategory;
  final _businessNameCtrl = TextEditingController();
  final _skillsDescCtrl = TextEditingController();
  String _yearsExp = '1';
  String _pricingType = 'Hour/Fixed Price';
  final _amountCtrl = TextEditingController();

  // Step 2 controllers
  final _workplaceCtrl = TextEditingController();
  String? _experienceLevel;

  // Step 3 state
  final List<String> _fakeSelectedImages = []; // placeholder list

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _skillsDescCtrl.dispose();
    _amountCtrl.dispose();
    _workplaceCtrl.dispose();
    super.dispose();
  }

  double get _progress {
    if (_step == 0) return 0.0;
    if (_step == 1) return 0.60;
    return 0.80;
  }

  String get _progressLabel {
    final pct = (_progress * 100).round();
    return '$pct% Complete';
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      if (!(_formStep1.currentState?.validate() ?? false)) return;
      if (_jobCategory == null) {
        _toast('Please select a job category');
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (!(_formStep2.currentState?.validate() ?? false)) return;
      if (_experienceLevel == null) {
        _toast('Please select your experience level');
        return;
      }
      setState(() => _step = 2);
      return;
    }
    // step 2 -> finish
    _toast('Saved (hook API later)');
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step -= 1);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.black.withOpacity(0.85),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final sidePad = w * 0.06;
    final topPad = h * 0.05;

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
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: sidePad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: topPad),

                    // Header row (back + title)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _back,
                          child: Container(
                            width: w * 0.13,
                            height: w * 0.13,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.chevron_left,
                              color: Colors.black,
                              size: w * 0.10,
                            ),
                          ),
                        ),
                        SizedBox(width: w * 0.05),
                        Text(
                          'Skills & Job Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.055,
                            fontFamily: 'AbrilFatface',
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: h * 0.018),

                    // Small helper pill
                    Center(
                      child: _GlassPill(
                        radius: 20,
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.05,
                          vertical: h * 0.007,
                        ),
                        child: Text(
                          'Tell Employers what you do',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: w * 0.032,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.018),

                    // Progress bar + label
                    _ProgressBar(
                      width: w,
                      progress: _progress,
                      label: _progressLabel,
                      accent: _brandOrange,
                    ),

                    SizedBox(height: h * 0.02),

                    // Step body (animated)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: _step == 0
                          ? _stepOne(w, h)
                          : _step == 1
                              ? _stepTwo(w, h)
                              : _stepThree(w, h),
                    ),

                    SizedBox(height: h * 0.03),

                    // Bottom CTA
                    SizedBox(
                      width: double.infinity,
                      height: h * 0.07,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandOrange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _step == 0 ? 'Continue' : 'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.045,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.03),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------- STEP 1 -----------------------
  Widget _stepOne(double w, double h) {
    return Form(
      key: _formStep1,
      child: Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Job Category', w),
          SizedBox(height: h * 0.012),
          _pillDropdown(
            w: w,
            h: h,
            hint: 'Select/ Search your Job category',
            value: _jobCategory,
            items: const [
              'Plumber',
              'Electrician',
              'Carpenter',
              'Cleaner',
              'Mechanic',
              'Painter',
            ],
            onChanged: (v) => setState(() => _jobCategory = v),
          ),

          SizedBox(height: h * 0.018),

          _label('Business Name', w),
          SizedBox(height: h * 0.012),
          _pillTextField(
            w: w,
            h: h,
            controller: _businessNameCtrl,
            hint: 'Enter Your Business Name',
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return 'Business name is required';
              return null;
            },
          ),

          SizedBox(height: h * 0.018),

          _label('Skills & Job Description', w),
          SizedBox(height: h * 0.012),
          _bigTextArea(
            w: w,
            h: h,
            controller: _skillsDescCtrl,
            hint: 'Describe your skills, experience, and services\nyou offer',
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return 'Please describe your skills';
              if ((v ?? '').trim().length < 15) return 'Add a bit more detail';
              return null;
            },
          ),

          SizedBox(height: h * 0.018),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Years Of Experience', w),
                    SizedBox(height: h * 0.012),
                    _pillMiniDropdown(
                      w: w,
                      h: h,
                      value: _yearsExp,
                      items: List.generate(30, (i) => '${i + 1}'),
                      onChanged: (v) => setState(() => _yearsExp = v ?? '1'),
                      leadingText: 'Experience',
                    ),
                  ],
                ),
              ),
              SizedBox(width: w * 0.05),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Pricing Type', w),
                    SizedBox(height: h * 0.012),
                    _pillMiniDropdown(
                      w: w,
                      h: h,
                      value: _pricingType,
                      items: const ['Hour/Fixed Price', 'Per Day', 'Per Job'],
                      onChanged: (v) =>
                          setState(() => _pricingType = v ?? 'Hour/Fixed Price'),
                      leadingText: 'Hour/Fixed Price',
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: h * 0.018),

          _label('Amount', w),
          SizedBox(height: h * 0.012),
          _pillTextField(
            w: w,
            h: h,
            controller: _amountCtrl,
            hint: 'Enter the Amount to be paid per {Hour/Fixed}',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return 'Amount is required';
              if (int.tryParse(t) == null) return 'Enter a valid number';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ----------------------- STEP 2 -----------------------
  Widget _stepTwo(double w, double h) {
    return Form(
      key: _formStep2,
      child: Column(
        key: const ValueKey('step2'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Work Place Location', w),
          SizedBox(height: h * 0.012),
          _pillSearchField(
            w: w,
            h: h,
            controller: _workplaceCtrl,
            hint: 'Search Your work place',
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return 'Work place is required';
              return null;
            },
          ),

          SizedBox(height: h * 0.018),

          _label('Experience Level', w),
          SizedBox(height: h * 0.012),
          _pillDropdown(
            w: w,
            h: h,
            hint: 'Select your Experience Level',
            value: _experienceLevel,
            items: const ['Beginner', 'Intermediate', 'Expert'],
            onChanged: (v) => setState(() => _experienceLevel = v),
          ),

          SizedBox(height: h * 0.018),

          Row(
            children: [
              _label('Select Your Place', w),
              const Spacer(),
              Text(
                'Optional',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: w * 0.032,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.012),

          _mapPlaceholder(w, h),
        ],
      ),
    );
  }

  // ----------------------- STEP 3 -----------------------
  Widget _stepThree(double w, double h) {
    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _mapPlaceholder(w, h, taller: true),

        SizedBox(height: h * 0.02),

        _label('Upload Images', w),
        SizedBox(height: h * 0.012),

        _uploadBox(
          w: w,
          h: h,
          onTap: () {
            // TODO: file/image picker
            setState(() {
              _fakeSelectedImages.add('image_${_fakeSelectedImages.length + 1}');
            });
            _toast('Picked (hook file picker later)');
          },
        ),
      ],
    );
  }

  // ----------------------- UI helpers -----------------------
  Text _label(String t, double w) {
    return Text(
      t,
      style: TextStyle(
        color: Colors.white,
        fontFamily: 'Poppins',
        fontSize: w * 0.038,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _pillTextField({
    required double w,
    required double h,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final fieldH = h * 0.065;
    return Container(
      height: fieldH,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      alignment: Alignment.centerLeft,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: TextStyle(
          color: Colors.black,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: w * 0.038,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: w * 0.035,
          ),
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(vertical: fieldH * 0.22),
        ),
      ),
    );
  }

  Widget _pillSearchField({
    required double w,
    required double h,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    final fieldH = h * 0.065;
    return Container(
      height: fieldH,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: w * 0.038,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.55),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: w * 0.035,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: fieldH * 0.22),
              ),
            ),
          ),
          Icon(Icons.search, color: Colors.black, size: w * 0.06),
        ],
      ),
    );
  }

  Widget _pillDropdown({
    required double w,
    required double h,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final fieldH = h * 0.065;
    return Container(
      height: fieldH,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black, size: w * 0.07),
          hint: Text(
            hint,
            style: TextStyle(
              color: Colors.black.withOpacity(0.65),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: w * 0.034,
            ),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: w * 0.036,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _pillMiniDropdown({
    required double w,
    required double h,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String leadingText,
  }) {
    final fieldH = h * 0.060; // slightly smaller
    final radius = 30.0;

    return Container(
      height: fieldH,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.035),
      child: Row(
        children: [
          Expanded(
            child: Text(
              leadingText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: w * 0.030, // smaller so it always fits
              ),
            ),
          ),

          SizedBox(width: w * 0.02),

          // value dropdown (fixed width, no vertical icon column)
          SizedBox(
            width: w * 0.18,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.black,
                  size: w * 0.07,
                ),
                items: items
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.032,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigTextArea({
    required double w,
    required double h,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    final boxH = h * 0.17;
    return Container(
      height: boxH,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: null,
        expands: true,
        style: TextStyle(
          color: Colors.black,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: w * 0.035,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: w * 0.032,
            height: 1.25,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _mapPlaceholder(double w, double h, {bool taller = false}) {
    final mapH = taller ? h * 0.34 : h * 0.24;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: mapH,
        width: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            // Fake "map" background look
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFEDEDED),
                      const Color(0xFFF7F7F7),
                    ],
                  ),
                ),
                child: const Opacity(
                  opacity: 0.22,
                  child: FlutterLogo(),
                ),
              ),
            ),

            // Pin
            Center(
              child: Icon(
                Icons.location_pin,
                color: Colors.redAccent,
                size: w * 0.10,
              ),
            ),

            // Zoom controls
            Positioned(
              right: w * 0.03,
              top: mapH * 0.35,
              child: Column(
                children: [
                  _zoomBtn(icon: Icons.add, w: w),
                  SizedBox(height: h * 0.01),
                  _zoomBtn(icon: Icons.remove, w: w),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoomBtn({required IconData icon, required double w}) {
    return Container(
      width: w * 0.10,
      height: w * 0.10,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black, size: w * 0.06),
    );
  }

  Widget _uploadBox({
    required double w,
    required double h,
    required VoidCallback onTap,
  }) {
    final boxH = h * 0.22;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: boxH,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.7),
            width: 1.4,
            style: BorderStyle.solid,
          ),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: Colors.white.withOpacity(0.75),
            radius: 18,
            dashWidth: 7,
            dashSpace: 6,
            strokeWidth: 1.6,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_upload_rounded, color: Colors.white, size: w * 0.14),
                SizedBox(height: h * 0.01),
                Text(
                  'Upload File',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: w * 0.04,
                  ),
                ),
                SizedBox(height: h * 0.004),
                Text(
                  'Supported files: PDF/PNG/JPEG/JPG\nMax Size: 5MB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: w * 0.028,
                    height: 1.25,
                  ),
                ),
                if (_fakeSelectedImages.isNotEmpty) ...[
                  SizedBox(height: h * 0.012),
                  Text(
                    '${_fakeSelectedImages.length} file(s) selected',
                    style: TextStyle(
                      color: _brandOrange,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.03,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Progress ----------------

class _ProgressBar extends StatelessWidget {
  final double width;
  final double progress;
  final String label;
  final Color accent;

  const _ProgressBar({
    required this.width,
    required this.progress,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final barH = width * 0.016;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: barH,
            width: double.infinity,
            color: Colors.white.withOpacity(0.9),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: barH,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: width * 0.014),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: width * 0.03,
          ),
        ),
      ],
    );
  }
}

// ---------------- Glass pill ----------------

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
                Colors.white.withOpacity(0.22),
                Colors.white.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.6),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.08),
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

// ---------------- Dashed border painter ----------------

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = dashWidth;
        final next = distance + len;
        final extract = metric.extractPath(distance, next.clamp(0.0, metric.length));
        canvas.drawPath(extract, paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
