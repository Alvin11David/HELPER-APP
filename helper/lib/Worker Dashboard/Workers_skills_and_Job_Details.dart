// ignore_for_file: depend_on_referenced_packages

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

  int _step = 0; // 0,1,2,3 (3 = preview)

  final _formStep1 = GlobalKey<FormState>();
  final _formStep2 = GlobalKey<FormState>();

  // Step 1 controllers/values
  String? _jobCategory;
  final _businessNameCtrl = TextEditingController();
  final _skillsDescCtrl = TextEditingController();
  String? _yearsExp; // required
  String? _pricingType; // required
  final _amountCtrl = TextEditingController();

  // Step 2 controllers/values
  final _workplaceCtrl = TextEditingController();
  String? _experienceLevel;
  bool _pickedPlaceOnMap = false; // optional

  // Step 3 state
  final List<String> _fakeSelectedImages = []; // placeholder list

  @override
  void initState() {
    super.initState();
    _businessNameCtrl.addListener(_recalcProgress);
    _skillsDescCtrl.addListener(_recalcProgress);
    _amountCtrl.addListener(_recalcProgress);
    _workplaceCtrl.addListener(_recalcProgress);
    _recalcProgress();
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _skillsDescCtrl.dispose();
    _amountCtrl.dispose();
    _workplaceCtrl.dispose();
    super.dispose();
  }

  // ✅ Progress increments per required field across Step1+Step2 only
  static const int _totalRequired = 8;
  double _progressValue = 0;

  double get _progress => _progressValue.clamp(0.0, 1.0);

  String get _progressLabel {
    final pct = (_progress * 100).round();
    return '$pct% Complete';
  }

  void _recalcProgress() {
    int done = 0;

    // Step 1 required (6)
    if (_jobCategory != null) done++;
    if (_businessNameCtrl.text.trim().isNotEmpty) done++;
    if (_skillsDescCtrl.text.trim().isNotEmpty) done++;
    if (_yearsExp != null) done++;
    if (_pricingType != null) done++;
    if (_amountCtrl.text.trim().isNotEmpty) done++;

    // Step 2 required (2)
    if (_workplaceCtrl.text.trim().isNotEmpty) done++;
    if (_experienceLevel != null) done++;

    setState(() => _progressValue = done / _totalRequired);
  }

  void _next() {
    FocusScope.of(context).unfocus();

    if (_step == 0) {
      final ok = _formStep1.currentState?.validate() ?? false;
      if (!ok) return;

      if (_jobCategory == null) {
        _toast('Please select a job category');
        return;
      }
      if (_yearsExp == null) {
        _toast('Please select years of experience');
        return;
      }
      if (_pricingType == null) {
        _toast('Please select pricing type');
        return;
      }

      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      final ok = _formStep2.currentState?.validate() ?? false;
      if (!ok) return;

      if (_experienceLevel == null) {
        _toast('Please select your experience level');
        return;
      }

      setState(() => _step = 2);
      return;
    }

    if (_step == 2) {
      // step3 -> preview (job preview)
      if (_fakeSelectedImages.isEmpty) {
        _toast('Please upload at least 1 file (tap Upload File).');
        return;
      }
      setState(() => _step = 3);
      return;
    }

    // submit from preview
    _toast('Submitted ✅ (hook API later)');
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step -= 1);
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step.clamp(0, 3));
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'AbrilFatface')),
        backgroundColor: Colors.black.withOpacity(0.85),
      ),
    );
  }

  // ----------------------------
  // Pickers
  // ----------------------------
  Future<void> _pickYearsExp() async {
    final items = List.generate(31, (i) => i == 30 ? '30+' : '${i + 1}');
    final selected = await _bottomPick(
      title: 'Years of Experience',
      items: items,
      selected: _yearsExp,
    );
    if (selected != null) {
      setState(() => _yearsExp = selected);
      _recalcProgress();
    }
  }

  Future<void> _pickPricingType() async {
    final items = const ['Hourly', 'Fixed Price', 'Per Day', 'Per Job'];
    final selected = await _bottomPick(
      title: 'Pricing Type',
      items: items,
      selected: _pricingType,
    );
    if (selected != null) {
      setState(() => _pricingType = selected);
      _recalcProgress();
    }
  }

  Future<String?> _bottomPick({
    required String title,
    required List<String> items,
    required String? selected,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'AbrilFatface',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.white.withOpacity(0.10),
                        ),
                        itemBuilder: (context, i) {
                          final v = items[i];
                          final isSel = v == selected;
                          return ListTile(
                            onTap: () => Navigator.pop(context, v),
                            title: Text(
                              v,
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'AbrilFatface',
                                fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
                              ),
                            ),
                            trailing: isSel
                                ? Icon(Icons.check_circle,
                                    color: _brandOrange.withOpacity(0.95))
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final sidePad = w * 0.06;
    final topPad = h * 0.05;

    final isPreview = _step == 3;

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
                        Flexible(
                          child: Text(
                            isPreview ? 'Job Preview' : 'Skills & Job Details',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: w * 0.055,
                              fontFamily: 'AbrilFatface',
                              letterSpacing: 0.2,
                            ),
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
                          isPreview
                              ? 'Preview what you have added'
                              : 'Tell Employers what you do',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: w * 0.032,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.018),

                    // ✅ HIDE progress bar on Job Preview screen
                    if (!isPreview) ...[
                      _ProgressBar(
                        width: w,
                        progress: _progress,
                        label: _progressLabel,
                        accent: _brandOrange,
                      ),
                      SizedBox(height: h * 0.02),
                    ] else ...[
                      SizedBox(height: h * 0.01),
                    ],

                    // Step body (animated)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOut),
                        );
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: _step == 0
                          ? _stepOne(w, h)
                          : _step == 1
                              ? _stepTwo(w, h)
                              : _step == 2
                                  ? _stepThree(w, h)
                                  : _jobPreview(w, h),
                    ),

                    SizedBox(height: h * 0.03),

                    // Bottom CTA
                    if (!isPreview)
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
                            _step == 0 ? 'Continue' : _step == 1 ? 'Save' : 'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: w * 0.045,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),

                    // ✅ Preview screen buttons inside the white card (like your image)
                    if (isPreview) SizedBox(height: h * 0.01),

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
            onChanged: (v) {
              setState(() => _jobCategory = v);
              _recalcProgress();
            },
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
                    _designPickerPill(
                      w: w,
                      h: h,
                      text: _yearsExp == null ? 'Experience' : _yearsExp!,
                      onTap: _pickYearsExp,
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
                    _designPickerPill(
                      w: w,
                      h: h,
                      text: _pricingType ?? 'Hour/Fixed Price',
                      onTap: _pickPricingType,
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
            onChanged: (v) {
              setState(() => _experienceLevel = v);
              _recalcProgress();
            },
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
                  fontFamily: 'Inter',
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
            setState(() {
              _fakeSelectedImages.add('file_${_fakeSelectedImages.length + 1}');
            });
            _toast('Picked (hook file picker later)');
          },
        ),
      ],
    );
  }

  // ----------------------- PREVIEW (UI matches image) -----------------------
  Widget _jobPreview(double w, double h) {
    final leftStyle = TextStyle(
      color: Colors.black,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w900,
      fontSize: w * 0.032,
    );

    final rightStyle = TextStyle(
      color: Colors.black.withOpacity(0.75),
      fontFamily: 'Inter',
      fontWeight: FontWeight.w800,
      fontSize: w * 0.032,
    );

    Widget row(String l, String r) {
      return Padding(
        padding: EdgeInsets.only(bottom: h * 0.012),
        child: Row(
          children: [
            Expanded(child: Text(l, style: leftStyle)),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  r.isEmpty ? '-' : r,
                  textAlign: TextAlign.right,
                  style: rightStyle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey('preview'),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: double.infinity,
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Title INSIDE white container
                Center(
                  child: Text(
                    'Preview Section',
                    style: TextStyle(
                      color: const Color.fromRGBO(0, 0, 0, 1),
                      fontFamily: 'AbrilFatface',
                      fontSize: w * 0.060,
                    ),
                  ),
                ),

                SizedBox(height: h * 0.012),

                // ✅ dotted lines like the image (top, between groups, bottom)
                _dashedDivider(color: Colors.black.withOpacity(0.35)),
                SizedBox(height: h * 0.018),

                // Group 1
                row('Business Name', _businessNameCtrl.text.trim()),
                row('Job Category', (_jobCategory ?? '').trim()),
                row('Years Of Experience:', (_yearsExp ?? '').trim()),
                row('Pricing Type', (_pricingType ?? '').trim()),
                row('Pricing', _amountCtrl.text.trim()),
                row('Experience Level', (_experienceLevel ?? '').trim()),

                SizedBox(height: h * 0.004),
                _dashedDivider(color: Colors.black.withOpacity(0.35)),
                SizedBox(height: h * 0.018),

                // Group 2
                row('Job District', 'District'),
                row('Skills & Job Description', _skillsDescCtrl.text.trim()),
                row('Work Place Location', _workplaceCtrl.text.trim()),

                SizedBox(height: h * 0.012),
                _dashedDivider(color: Colors.black.withOpacity(0.35)),
                SizedBox(height: h * 0.016),

                Center(
                  child: Text(
                    'The above are the details you have\nfilled in and they will appear on the\nemployers side.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _brandOrange,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontSize: w * 0.032,
                      height: 1.25,
                    ),
                  ),
                ),

                SizedBox(height: h * 0.02),

                // ✅ Buttons inside container like your image
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: h * 0.060,
                        child: OutlinedButton(
                          onPressed: () => _goToStep(0),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _brandOrange, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              color: _brandOrange,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              fontSize: w * 0.040,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.06),
                    Expanded(
                      child: SizedBox(
                        height: h * 0.060,
                        child: ElevatedButton(
                          onPressed: _next, // submit
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandOrange,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Submit',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              fontSize: w * 0.040,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        fontFamily: 'Inter',
        fontSize: w * 0.038,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _dashedDivider({required Color color}) {
    return CustomPaint(
      painter: _DashedLinePainter(color: color),
      child: const SizedBox(height: 1),
    );
  }

  Widget _designPickerPill({
    required double w,
    required double h,
    required String text,
    required VoidCallback onTap,
  }) {
    final fieldH = h * 0.060;
    final r = fieldH / 2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: fieldH,
        padding: EdgeInsets.symmetric(horizontal: w * 0.045),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: w * 0.038,
                ),
              ),
            ),
            SizedBox(width: w * 0.02),
            SizedBox(
              width: w * 0.08,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_drop_up, color: Colors.black, size: w * 0.085),
                  Transform.translate(
                    offset: Offset(0, -w * 0.03),
                    child: Icon(Icons.arrow_drop_down, color: Colors.black, size: w * 0.085),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        validator: (v) {
          final res = validator?.call(v);
          WidgetsBinding.instance.addPostFrameCallback((_) => _recalcProgress());
          return res;
        },
        onChanged: (_) => _recalcProgress(),
        style: TextStyle(
          color: Colors.black,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: w * 0.038,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontFamily: 'Inter',
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
              validator: (v) {
                final res = validator?.call(v);
                WidgetsBinding.instance.addPostFrameCallback((_) => _recalcProgress());
                return res;
              },
              onChanged: (_) => _recalcProgress(),
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: w * 0.038,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.55),
                  fontFamily: 'Inter',
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
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black,
            size: w * 0.07,
          ),
          hint: Text(
            hint,
            style: TextStyle(
              color: Colors.black.withOpacity(0.65),
              fontFamily: 'Inter',
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
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontSize: w * 0.036,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            onChanged(v);
            _recalcProgress();
          },
        ),
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
        validator: (v) {
          final res = validator?.call(v);
          WidgetsBinding.instance.addPostFrameCallback((_) => _recalcProgress());
          return res;
        },
        onChanged: (_) => _recalcProgress(),
        maxLines: null,
        expands: true,
        style: TextStyle(
          color: Colors.black,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: w * 0.035,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: w * 0.033,
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
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEDEDED), Color(0xFFF7F7F7)],
                  ),
                ),
                child: const Opacity(opacity: 0.22, child: FlutterLogo()),
              ),
            ),
            Center(
              child: Icon(Icons.location_pin, color: Colors.redAccent, size: w * 0.10),
            ),
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
            Positioned(
              left: w * 0.03,
              bottom: w * 0.03,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _pickedPlaceOnMap = !_pickedPlaceOnMap);
                  _toast(_pickedPlaceOnMap ? 'Picked on map (optional)' : 'Unpicked map');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pickedPlaceOnMap ? Colors.green : _brandOrange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                child: Text(
                  _pickedPlaceOnMap ? 'Picked ✓' : 'Pick',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: w * 0.032,
                  ),
                ),
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
                    fontFamily: 'Inter',
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
                    fontFamily: 'Inter',
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
                      fontFamily: 'Inter',
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
            fontFamily: '',
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
        final extract = metric.extractPath(
          distance,
          next.clamp(0.0, metric.length),
        );
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

// ✅ dashed divider used in preview (exact dotted lines like image)
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    const dashWidth = 6.0;
    const dashSpace = 5.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

