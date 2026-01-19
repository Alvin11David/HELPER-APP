import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JobDetailBookingScreen extends StatefulWidget {
  const JobDetailBookingScreen({super.key});

  @override
  State<JobDetailBookingScreen> createState() => _JobDetailBookingScreenState();
}

class _JobDetailBookingScreenState extends State<JobDetailBookingScreen> {
  static const _brandOrange = Color(0xFFFFA10D);

  int _step = 0; // 0..3

  // -------------------- PHASE 1 (Describe) --------------------
  final _descCtrl = TextEditingController();
  final List<String> _fakePhotos = []; // placeholder
  String? _pickedJobLocation; // placeholder string (map later)

  // -------------------- PHASE 2 (Workers & Pricing) --------------------
  String? _workersCount;
  String? _jobDuration; // Hours / Fixed
  final _amountCtrl = TextEditingController();

  // -------------------- PHASE 3 (Schedule) --------------------
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _startDate;
  DateTime? _endDate;

  TimeOfDay? _timeFrom;
  TimeOfDay? _timeTo;

  // -------------------- PHASE 4 (Summary) --------------------
  final String _businessName = "Business Name";
  final String _profession = "Profession";

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // -------------------- VALIDATION --------------------
  bool get _phase1Complete {
    final okDesc = _descCtrl.text.trim().isNotEmpty;
    final okLocation =
        (_pickedJobLocation != null && _pickedJobLocation!.trim().isNotEmpty);
    return okDesc && okLocation;
  }

  bool get _phase2Complete {
    final okWorkers = _workersCount != null;
    final okDuration = _jobDuration != null;
    final okAmount =
        _amountCtrl.text.trim().isNotEmpty &&
        int.tryParse(_amountCtrl.text.trim()) != null;
    return okWorkers && okDuration && okAmount;
  }

  bool get _phase3Complete {
    final okRange = _startDate != null && _endDate != null;
    final okTime = _timeFrom != null && _timeTo != null;
    if (!okRange || !okTime) return false;

    final fromMin = _timeFrom!.hour * 60 + _timeFrom!.minute;
    final toMin = _timeTo!.hour * 60 + _timeTo!.minute;
    return toMin > fromMin;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: Colors.black.withOpacity(0.88),
      ),
    );
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step -= 1);
  }

  void _next() {
    FocusScope.of(context).unfocus();

    if (_step == 0) {
      if (!_phase1Complete) {
        if (_descCtrl.text.trim().isEmpty) _toast('Please describe the job');
        if (_pickedJobLocation == null)
          _toast('Please pick a job location on the map');
        return;
      }
      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      if (!_phase2Complete) {
        if (_workersCount == null) _toast('Please select number of workers');
        if (_jobDuration == null) _toast('Please select job duration type');
        final t = _amountCtrl.text.trim();
        if (t.isEmpty || int.tryParse(t) == null)
          _toast('Enter a valid amount');
        return;
      }
      setState(() => _step = 2);
      return;
    }

    if (_step == 2) {
      if (!_phase3Complete) {
        if (_startDate == null || _endDate == null)
          _toast('Please select a date range');
        if (_timeFrom == null || _timeTo == null)
          _toast('Please select a time range');
        return;
      }
      setState(() => _step = 3);
      return;
    }

    // step 3 -> payment
    _toast('Continue to payment (hook later)');
  }

  // -------------------- TIME PICKERS --------------------
  Future<void> _pickTime({required bool isFrom}) async {
    final initial = isFrom
        ? (_timeFrom ?? const TimeOfDay(hour: 9, minute: 0))
        : (_timeTo ?? const TimeOfDay(hour: 17, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.black.withOpacity(0.85),
              hourMinuteTextColor: Colors.white,
              dialHandColor: _brandOrange,
              dialBackgroundColor: Colors.white.withOpacity(0.10),
              dayPeriodTextColor: Colors.white,
              entryModeIconColor: Colors.white,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontFamily: 'Inter'),
              bodySmall: TextStyle(fontFamily: 'Inter'),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _timeFrom = picked;
      } else {
        _timeTo = picked;
      }
    });
  }

  // -------------------- DATE RANGE PICK --------------------
  void _toggleDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);

    if (_startDate == null || (_startDate != null && _endDate != null)) {
      setState(() {
        _startDate = d;
        _endDate = null;
      });
      return;
    }

    // start exists, end null
    if (d.isBefore(_startDate!)) {
      setState(() {
        _endDate = _startDate;
        _startDate = d;
      });
      return;
    }

    setState(() => _endDate = d);
  }

  bool _inRange(DateTime d) {
    if (_startDate == null) return false;
    final day = DateTime(d.year, d.month, d.day);
    final start = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );
    if (_endDate == null) return day == start;

    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    return (day.isAtSameMomentAs(start) || day.isAfter(start)) &&
        (day.isAtSameMomentAs(end) || day.isBefore(end));
  }

  bool _isEdge(DateTime d) {
    if (_startDate == null) return false;
    final day = DateTime(d.year, d.month, d.day);
    final start = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );
    if (_endDate == null) return day == start;

    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    return day == start || day == end;
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final sidePad = w * 0.06;
    final topPad = h * 0.035;

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
                    _TopBar(
                      title: _stepTitle(),
                      subtitle: _businessName,
                      onBack: _back,
                    ),

                    SizedBox(height: h * 0.018),

                    // stepper (dots + dashed)
                    Center(
                      child: _StepIndicator(
                        width: w,
                        activeIndex: _step < 3 ? _step : 2,
                        labels: const [
                          'Job Details',
                          'Choose Date',
                          'Payment Details',
                        ],
                        accent: _brandOrange,
                      ),
                    ),

                    SizedBox(height: h * 0.019),

                    // phase title (small centered)
                    Center(
                      child: Text(
                        _stepHeadline(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          fontSize: w * 0.040,
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.018),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) {
                        final slide =
                            Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOut,
                              ),
                            );
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: _step == 0
                          ? _phase1(w, h)
                          : _step == 1
                          ? _phase2(w, h)
                          : _step == 2
                          ? _phase3(w, h)
                          : _phase4(w, h),
                    ),

                    SizedBox(height: h * 0.022),

                    // CTA button
                    SizedBox(
                      width: double.infinity,
                      height: h * 0.070,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandOrange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _step == 3 ? 'Continue to Payment' : 'Continue →',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w900,
                              fontSize: w * 0.045,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.030),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stepTitle() {
    if (_step == 3) return "Payments";
    if (_step == 2) return "Choose Date";
    return "Job Details";
  }

  String _stepHeadline() {
    if (_step == 0)
      return "Choose Date"; // your first mock shows "Choose Date" even on details
    if (_step == 1) return "Choose Date";
    if (_step == 2) return "Choose Date";
    return "Choose Date";
  }

  // -------------------- PHASE 1 --------------------
  Widget _phase1(double w, double h) {
    return Column(
      key: const ValueKey('phase1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Describe the job", w),
        SizedBox(height: h * 0.010),
        _whiteTextArea(
          w: w,
          h: h,
          controller: _descCtrl,
          hint:
              "Explain what needs to be done, tools required\nand any special instructions...",
        ),

        SizedBox(height: h * 0.018),

        Row(
          children: [
            _label("Attach Photos", w),
            const Spacer(),
            Text(
              "Optional",
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: w * 0.032,
              ),
            ),
          ],
        ),
        SizedBox(height: h * 0.010),
        _uploadBox(
          w: w,
          h: h,
          subtitle: "Supported files: PDF/PNG/JPEG/JPG\nLimit: 4 images",
          onTap: () {
            setState(() => _fakePhotos.add("img_${_fakePhotos.length + 1}"));
            _toast("Picked (hook file picker later)");
          },
        ),

        SizedBox(height: h * 0.018),

        Row(
          children: [
            _label("Job Location", w),
            const Spacer(),
            Text(
              "Tap the map to select",
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: w * 0.030,
              ),
            ),
          ],
        ),
        SizedBox(height: h * 0.010),
        _mapPlaceholder(
          w: w,
          h: h,
          heightFactor: 0.24,
          onTapPick: () {
            setState(() => _pickedJobLocation = "Kampala");
            _toast("Picked job location (placeholder)");
          },
        ),
      ],
    );
  }

  // -------------------- PHASE 2 --------------------
  Widget _phase2(double w, double h) {
    return Column(
      key: const ValueKey('phase2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _label("Job Location", w),
            const Spacer(),
            Text(
              "Tap the map to select",
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: w * 0.030,
              ),
            ),
          ],
        ),
        SizedBox(height: h * 0.010),
        _mapPlaceholder(
          w: w,
          h: h,
          heightFactor: 0.28,
          onTapPick: () {
            setState(() => _pickedJobLocation = "Kampala");
            _toast("Picked job location (placeholder)");
          },
        ),

        SizedBox(height: h * 0.018),

        _label("Number of Workers", w),
        SizedBox(height: h * 0.010),
        _pillDropdown(
          w: w,
          h: h,
          hint: "Select the number of workers",
          value: _workersCount,
          items: List.generate(10, (i) => "${i + 1}"),
          onChanged: (v) => setState(() => _workersCount = v),
        ),

        SizedBox(height: h * 0.016),

        _label("Job Duration", w),
        SizedBox(height: h * 0.010),
        _pillDropdown(
          w: w,
          h: h,
          hint: "Select either Hours/ Fixed",
          value: _jobDuration,
          items: const ["Hours", "Fixed"],
          onChanged: (v) => setState(() => _jobDuration = v),
        ),

        SizedBox(height: h * 0.016),

        _label("Amount", w),
        SizedBox(height: h * 0.006),
        Text(
          "Business Name's Hourly/Fixed Price is (Amount)",
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: w * 0.030,
          ),
        ),
        SizedBox(height: h * 0.010),
        _pillTextField(
          w: w,
          h: h,
          controller: _amountCtrl,
          hint: "Enter the Amount to pay",
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        SizedBox(height: h * 0.010),
        Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Colors.white.withOpacity(0.85),
              size: w * 0.050,
            ),
            SizedBox(width: w * 0.02),
            Expanded(
              child: Text(
                "Enter Amount your wallet can afford",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: w * 0.030,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------- PHASE 3 --------------------
  Widget _phase3(double w, double h) {
    return Column(
      key: const ValueKey('phase3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Selected Date Range", w),
        SizedBox(height: h * 0.010),
        _pillDisplay(
          w: w,
          h: h,
          leading: Icons.calendar_month_rounded,
          text: _startDate == null
              ? "Selected Date Range"
              : "${_fmtDate(_startDate!)}  →  ${_fmtDate(_endDate ?? _startDate!)}",
        ),

        SizedBox(height: h * 0.014),

        _calendarCard(w, h),

        SizedBox(height: h * 0.018),

        _label("Selected Time Range", w),
        SizedBox(height: h * 0.010),
        _pillDisplay(
          w: w,
          h: h,
          leading: Icons.access_time_rounded,
          text: "Selected Time Range",
        ),

        SizedBox(height: h * 0.012),

        Center(
          child: Text(
            "Choose Your Time",
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: w * 0.040,
            ),
          ),
        ),

        SizedBox(height: h * 0.012),

        Row(
          children: [
            Expanded(
              child: _timePill(
                w: w,
                h: h,
                label: "From",
                time: _timeFrom,
                onTap: () => _pickTime(isFrom: true),
              ),
            ),
            SizedBox(width: w * 0.04),
            Expanded(
              child: _timePill(
                w: w,
                h: h,
                label: "To",
                time: _timeTo,
                onTap: () => _pickTime(isFrom: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------- PHASE 4 --------------------
  Widget _phase4(double w, double h) {
    return Column(
      key: const ValueKey('phase4'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _businessCard(w, h),

        SizedBox(height: h * 0.016),

        _breakdownCard(w, h),

        SizedBox(height: h * 0.012),

        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _step = 0),
              child: Text(
                "Edit Job details",
                style: TextStyle(
                  color: _brandOrange,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: w * 0.032,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _step = 2),
              child: Text(
                "Edit Schedule",
                style: TextStyle(
                  color: _brandOrange,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: w * 0.032,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------- COMPONENTS --------------------
  Widget _label(String t, double w) {
    return Text(
      t,
      style: TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
        fontSize: w * 0.038,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _whiteTextArea({
    required double w,
    required double h,
    required TextEditingController controller,
    required String hint,
  }) {
    final boxH = h * 0.15;
    return Container(
      height: boxH,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: EdgeInsets.only(
        left: w * 0.04,
        right: w * 0.04,
        top: h * 0.006,
        bottom: h * 0.018,
      ),
      child: TextFormField(
        controller: controller,
        maxLines: null,
        expands: true,
        style: TextStyle(
          color: Colors.black,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: w * 0.034,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: w * 0.032,
            height: 1.20,
          ),
          border: InputBorder.none,
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
  }) {
    final fieldH = h * 0.062;
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
        style: TextStyle(
          color: Colors.black,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
          fontSize: w * 0.038,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: w * 0.034,
          ),
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(vertical: fieldH * 0.22),
        ),
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
    final fieldH = h * 0.062;
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
            size: w * 0.075,
          ),
          hint: Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black.withOpacity(0.60),
              fontFamily: 'Inter',
              fontWeight: FontWeight.w900,
              fontSize: w * 0.032,
            ),
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
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.035,
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

  Widget _pillDisplay({
    required double w,
    required double h,
    required IconData leading,
    required String text,
  }) {
    final fieldH = h * 0.060;
    return Container(
      height: fieldH,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.045),
      child: Row(
        children: [
          Icon(leading, color: Colors.black, size: w * 0.055),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.034,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timePill({
    required double w,
    required double h,
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    final fieldH = h * 0.060;
    final r = fieldH / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: w * 0.030,
          ),
        ),
        SizedBox(height: h * 0.008),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: fieldH,
            padding: EdgeInsets.symmetric(horizontal: w * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: Colors.black,
                  size: w * 0.05,
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Text(
                    time == null ? "00:00 AM/PM" : time.format(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black.withOpacity(
                        time == null ? 0.55 : 1.0,
                      ),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.033,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapPlaceholder({
    required double w,
    required double h,
    required double heightFactor,
    required VoidCallback onTapPick,
  }) {
    final mapH = h * heightFactor;
    return GestureDetector(
      onTap: onTapPick,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: mapH,
          width: double.infinity,
          color: Colors.white,
          child: Stack(
            children: [
              // fake map background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEDEDED), Color(0xFFF8F8F8)],
                    ),
                  ),
                ),
              ),

              Center(
                child: Container(
                  width: w * 0.20,
                  height: w * 0.20,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.redAccent,
                      size: w * 0.10,
                    ),
                  ),
                ),
              ),

              Positioned(
                right: w * 0.03,
                top: mapH * 0.32,
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
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final boxH = h * 0.19;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: boxH,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
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
                Icon(
                  Icons.cloud_upload_rounded,
                  color: Colors.white,
                  size: w * 0.14,
                ),
                SizedBox(height: h * 0.008),
                Text(
                  "Upload File",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: w * 0.040,
                  ),
                ),
                SizedBox(height: h * 0.004),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: w * 0.028,
                    height: 1.20,
                  ),
                ),
                if (_fakePhotos.isNotEmpty) ...[
                  SizedBox(height: h * 0.010),
                  Text(
                    "${_fakePhotos.length} file(s) selected",
                    style: TextStyle(
                      color: _brandOrange,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.030,
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

  Widget _calendarCard(double w, double h) {
    final cardH = h * 0.42;

    final monthName = _monthName(_calendarMonth.month);
    final year = _calendarMonth.year;

    final days = _buildMonthGrid(_calendarMonth);
    final weekdays = const ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: cardH,
        width: double.infinity,
        color: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: h * 0.015,
        ),
        child: Column(
          children: [
            // month header
            Row(
              children: [
                _circleIconBtn(
                  w: w,
                  icon: Icons.chevron_left,
                  onTap: () {
                    setState(() {
                      _calendarMonth = DateTime(
                        _calendarMonth.year,
                        _calendarMonth.month - 1,
                      );
                    });
                  },
                ),
                const Spacer(),
                Text(
                  "$monthName $year",
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: w * 0.040,
                  ),
                ),
                const Spacer(),
                _circleIconBtn(
                  w: w,
                  icon: Icons.chevron_right,
                  onTap: () {
                    setState(() {
                      _calendarMonth = DateTime(
                        _calendarMonth.year,
                        _calendarMonth.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),

            SizedBox(height: h * 0.012),

            // weekdays
            Row(
              children: weekdays
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: w * 0.028,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            SizedBox(height: h * 0.010),

            // grid
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, i) {
                  final day = days[i];
                  if (day == null) return const SizedBox.shrink();

                  final isToday = _isSameDate(day, DateTime.now());
                  final inRange = _inRange(day);
                  final edge = _isEdge(day);

                  Color bg = Colors.transparent;
                  Color txt = Colors.black.withOpacity(0.80);

                  if (inRange) {
                    bg = edge
                        ? Colors.redAccent
                        : Colors.grey.withOpacity(0.20);
                    txt = edge ? Colors.white : Colors.black;
                  }

                  // match your legend vibe: current day green
                  if (isToday) {
                    bg = Colors.green;
                    txt = Colors.white;
                  }

                  return GestureDetector(
                    onTap: () => _toggleDay(day),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${day.day}",
                          style: TextStyle(
                            color: txt,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.032,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: h * 0.010),

            // legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _legendDot(w, Colors.redAccent, "Unavailable days"),
                _legendDot(w, Colors.grey.withOpacity(0.35), "Available days"),
                _legendDot(
                  w,
                  const Color.fromARGB(255, 0, 255, 8),
                  "Current day",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(double w, Color c, String t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: w * 0.035,
          height: w * 0.035,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        SizedBox(width: w * 0.018),
        Text(
          t,
          style: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: w * 0.026,
          ),
        ),
      ],
    );
  }

  Widget _circleIconBtn({
    required double w,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w * 0.09,
        height: w * 0.09,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.07),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: Colors.black, size: w * 0.06),
        ),
      ),
    );
  }

  Widget _businessCard(double w, double h) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Positioned(
            left: w * 0.10 + w * 0.03,
            top: 0,
            right: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: w * 0.038,
                  ),
                ),
                SizedBox(height: h * 0.002),
                Text(
                  _profession,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.55),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: w * 0.030,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownCard(double w, double h) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.016),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Job Cost Breakdown",
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'AbrilFatface',
                fontSize: w * 0.050,
              ),
            ),
          ),

          SizedBox(height: h * 0.010),

          _dashedDivider(color: Colors.black.withOpacity(0.35)),

          SizedBox(height: h * 0.012),

          _kv(
            "Selected Date Range",
            _startDate == null
                ? "Range"
                : "${_fmtDate(_startDate!)} - ${_fmtDate(_endDate ?? _startDate!)}",
            w,
          ),
          _kv(
            "Selected Time Range",
            (_timeFrom == null || _timeTo == null)
                ? "Range"
                : "${_timeFrom!.format(context)} - ${_timeTo!.format(context)}",
            w,
          ),

          SizedBox(height: h * 0.010),
          _dashedDivider(color: Colors.black.withOpacity(0.35)),
          SizedBox(height: h * 0.010),

          _kv("Number of Workers", _workersCount ?? "Number", w),
          _kv(
            "Number of Hours",
            _jobDuration == null
                ? "Number"
                : (_jobDuration == "Hours" ? "Number" : "—"),
            w,
          ),
          _kv("Hourly Pricing", "Amount", w),

          SizedBox(height: h * 0.012),

          Row(
            children: [
              Text(
                "Total",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: w * 0.040,
                ),
              ),
              const Spacer(),
              Text(
                _amountCtrl.text.trim().isEmpty
                    ? "Amount"
                    : _amountCtrl.text.trim(),
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: w * 0.040,
                ),
              ),
            ],
          ),

          SizedBox(height: h * 0.012),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.black.withOpacity(0.8),
                size: w * 0.05,
              ),
              SizedBox(width: w * 0.02),
              Expanded(
                child: Text(
                  "The Pricing is entirely set by the worker",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: w * 0.030,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, double w) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.008),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black.withOpacity(0.80),
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: w * 0.030,
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          Text(
            v,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black.withOpacity(0.75),
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: w * 0.030,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedDivider({required Color color}) {
    return SizedBox(
      width: double.infinity,
      height: 1.6,
      child: CustomPaint(painter: _DashedLinePainter(color: color)),
    );
  }

  // -------------------- CALENDAR HELPERS --------------------
  List<DateTime?> _buildMonthGrid(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    final daysInMonth = nextMonth.difference(first).inDays;

    // We want Monday as first day (MON..SUN)
    final weekday = first.weekday; // 1=Mon..7=Sun
    final leadingEmpty = weekday - 1;

    final List<DateTime?> grid = [];
    for (int i = 0; i < leadingEmpty; i++) {
      grid.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      grid.add(DateTime(month.year, month.month, d));
    }

    // pad to complete 6 rows (42 cells) for stable UI
    while (grid.length < 42) {
      grid.add(null);
    }
    return grid;
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "${d.year}-$mm-$dd";
  }

  String _monthName(int m) {
    const names = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return names[m - 1];
  }
}

// ======================= TOP BAR =======================

class _TopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
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

        SizedBox(width: w * 0.06),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontSize: w * 0.052,
                ),
              ),
              SizedBox(height: h * 0.002),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: w * 0.03,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: w * 0.03),

        SizedBox(
          width: 100,
          height: 80,
          child: Stack(
            children: [
              Positioned(
                top: 20,
                right: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.black),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: w * 0.0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.0,
                    vertical: h * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 254, 8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Available",
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.026,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================= STEPPER =======================

class _DotStepper extends StatelessWidget {
  final int activeIndex;
  final Color accent;

  const _DotStepper({required this.activeIndex, required this.accent});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    Widget dot(bool active) {
      return Container(
        width: w * 0.028,
        height: w * 0.028,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? accent : Colors.transparent,
          border: Border.all(color: accent, width: 2),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
      );
    }

    Widget dashed() {
      return SizedBox(
        width: w * 0.18,
        height: 2,
        child: CustomPaint(painter: _DashedLinePainter(color: accent)),
      );
    }

    // labels
    TextStyle labelStyle(bool on) => TextStyle(
      color: Colors.white.withOpacity(on ? 0.95 : 0.75),
      fontFamily: 'Inter',
      fontWeight: FontWeight.w800,
      fontSize: w * 0.026,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            dot(activeIndex >= 0),
            SizedBox(width: w * 0.02),
            dashed(),
            SizedBox(width: w * 0.02),
            dot(activeIndex >= 1),
            SizedBox(width: w * 0.02),
            dashed(),
            SizedBox(width: w * 0.02),
            dot(activeIndex >= 2),
            SizedBox(width: w * 0.02),
            dashed(),
            SizedBox(width: w * 0.02),
            dot(activeIndex >= 3),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: Text("Job Details", style: labelStyle(activeIndex == 0)),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  "Choose Date",
                  style: labelStyle(activeIndex == 2 || activeIndex == 1),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  "Payment Details",
                  style: labelStyle(activeIndex == 3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = 2;

    const dashWidth = 7.0;
    const dashSpace = 6.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ======================= DASHED BORDER =======================

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
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
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
  bool shouldRepaint(covariant _DashedBorderPainter old) {
    return old.color != color ||
        old.radius != radius ||
        old.dashWidth != dashWidth ||
        old.dashSpace != dashSpace ||
        old.strokeWidth != strokeWidth;
  }
}

class _StepIndicator extends StatelessWidget {
  final double width;
  final int activeIndex;
  final List<String> labels;
  final Color accent;

  const _StepIndicator({
    required this.width,
    required this.activeIndex,
    required this.labels,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final dot = width * 0.02;
    final lineW = width * 0.18;

    Widget dotW(bool active) {
      return Container(
        width: dot * 1.45,
        height: dot * 1.45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? accent : Colors.transparent,
          border: Border.all(color: accent, width: 2),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
      );
    }

    Widget dashed() {
      return SizedBox(
        width: lineW,
        child: CustomPaint(painter: _DashedLinePainter(color: accent)),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            dotW(activeIndex >= 0),
            SizedBox(width: width * 0.02),
            dashed(),
            SizedBox(width: width * 0.02),
            dotW(activeIndex >= 1),
            SizedBox(width: width * 0.02),
            dashed(),
            SizedBox(width: width * 0.02),
            dotW(activeIndex >= 2),
          ],
        ),
        SizedBox(height: width * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (t) => Expanded(
                  child: Text(
                    t,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accent,
                      fontSize: width * 0.032,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
