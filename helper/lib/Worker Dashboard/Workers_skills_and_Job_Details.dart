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

  int _step = 0; // 0,1,2

  final _formStep1 = GlobalKey<FormState>();
  final _formStep2 = GlobalKey<FormState>();

  // Step 1 controllers/values
  String? _jobCategory;
  final _businessNameCtrl = TextEditingController();
  final _skillsDescCtrl = TextEditingController();
  String? _yearsExp; // ✅ required now (null until picked)
  String? _pricingType; // ✅ required now (null until picked)
  final _amountCtrl = TextEditingController();

  // Step 2 controllers/values
  final _workplaceCtrl = TextEditingController();
  String? _experienceLevel;
  bool _pickedPlaceOnMap = false; // optional (kept optional as your UI)

  // Step 3 state
  final List<String> _fakeSelectedImages = []; // placeholder list

  @override
  void initState() {
    super.initState();
    // Recalc progress when typing changes (so progress updates live)
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

  // ----------------------------
  // ✅ PROGRESS: increments per field across the whole flow
  // Total required fields = 8
  // Step 1 (5): job category, business name, skills, years exp, pricing type, amount => (6 actually)
  // Step 2 (2): work place, experience level
  // Step 3 (0 required here for now) - you said map later; uploads in step3 can remain optional
  //
  // To match your “3 shifts” idea and still keep your current guard:
  // - Step 1 requires all its fields before Continue
  // - Step 2 requires its fields before Save -> step3
  // - Step 3 Save just shows toast (hook API later)
  //
  // Required count = 8 (Step1: 6 + Step2: 2)
  // ----------------------------
  static const int _totalRequired = 8;
  double _progressValue = 0;

  double get _progress => _progressValue.clamp(0.0, 1.0);

  String get _progressLabel {
    final pct = (_progress * 100).round();
    return '$pct% Complete';
  }

  void _recalcProgress() {
    int done = 0;

    // Step 1 required
    if (_jobCategory != null) done++;
    if (_businessNameCtrl.text.trim().isNotEmpty) done++;
    if (_skillsDescCtrl.text.trim().isNotEmpty) done++;
    if (_yearsExp != null) done++;
    if (_pricingType != null) done++;
    if (_amountCtrl.text.trim().isNotEmpty) done++;

    // Step 2 required
    if (_workplaceCtrl.text.trim().isNotEmpty) done++;
    if (_experienceLevel != null) done++;

    setState(() => _progressValue = done / _totalRequired);
  }

  // ----------------------------
  // ✅ Gate navigation exactly like you asked:
  // - Can't proceed unless current step is complete
  // ----------------------------
  bool get _step1Complete {
    final okForm = _formStep1.currentState?.validate() ?? false;
    final okCategory = _jobCategory != null;
    final okYears = _yearsExp != null;
    final okPricing = _pricingType != null;
    return okForm && okCategory && okYears && okPricing;
  }

  bool get _step2Complete {
    final okForm = _formStep2.currentState?.validate() ?? false;
    final okLevel = _experienceLevel != null;
    return okForm && okLevel;
  }

  void _next() {
    FocusScope.of(context).unfocus();

    if (_step == 0) {
      // validate form first
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

    // Step 3 finish
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

  // ----------------------------
  // ✅ Pickers for your “Years Experience” and “Pricing Type”
  // We use a bottom sheet to match your “dope” UI and avoid overflow.
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
                        fontFamily: 'Poppins',
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
                                fontFamily: 'Poppins',
                                fontWeight: isSel ? FontWeight.w900 : FontWeight.w700,
                              ),
                            ),
                            trailing: isSel
                                ? Icon(Icons.check_circle, color: _brandOrange.withOpacity(0.95))
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
                            'Skills & Job Details',
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

                    // ✅ progress bar now live-updates by filled fields
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

          // ✅ REPLACE with your design: two white pills, each has big label + stacked up/down arrows (no DropdownButton)
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
                      text: _yearsExp == null ? 'Experience' : '${_yearsExp!} yr',
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
            // (Uploads not required for progress right now; if you want required later, add to progress calc.)
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

  Widget _designPickerPill({
    required double w,
    required double h,
    required String text,
    required VoidCallback onTap,
  }) {
    // Matches your screenshot: white pill, bold text, stacked up/down arrows on right
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
                  fontFamily: 'Poppins',
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
                    child: Icon(Icons.arrow_drop_down,
                        color: Colors.black, size: w * 0.085),
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
          // refresh progress on validation changes too
          WidgetsBinding.instance.addPostFrameCallback((_) => _recalcProgress());
          return res;
        },
        onChanged: (_) => _recalcProgress(),
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
              validator: (v) {
                final res = validator?.call(v);
                WidgetsBinding.instance.addPostFrameCallback((_) => _recalcProgress());
                return res;
              },
              onChanged: (_) => _recalcProgress(),
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
              child: Icon(
                Icons.location_pin,
                color: Colors.redAccent,
                size: w * 0.10,
              ),
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
                    fontFamily: 'Poppins',
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
