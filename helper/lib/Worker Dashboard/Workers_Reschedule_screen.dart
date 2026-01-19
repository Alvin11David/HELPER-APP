import 'dart:ui';
import 'package:flutter/material.dart';
class WorkerJobRescheduleScreen extends StatefulWidget {
  const WorkerJobRescheduleScreen({super.key});

  @override
  State<WorkerJobRescheduleScreen> createState() =>
      _WorkerJobRescheduleScreenState();
}

class _WorkerJobRescheduleScreenState extends State<WorkerJobRescheduleScreen> {
  static const _brandOrange = Color(0xFFFFA10D);
  static const _brandGreen = Color(0xFF24E61F);
  static const _brandRed = Color(0xFFFF2B2B);

  // 0 = list, 1 = reschedule
  int _step = 0;

  // Fake jobs
  final List<_ConflictingJob> _jobs = List.generate(
    6,
    (i) => _ConflictingJob(
      employerName: "Employer Name",
      description: "Job Description here",
      dateRange: "Job Date Range",
    ),
  );

  _ConflictingJob? _selected;

  // Date/time selections (UI only)
  String _selectedDateRangeLabel = "Selected Date Range";
  String _selectedTimeRangeLabel = "Selected Time Range";

  TimeOfDay? _from;
  TimeOfDay? _to;

  // Calendar month
  final String _monthTitle = "January 2026";
  final Set<int> _unavailableDays = {16, 17, 18, 19, 20, 21};
  final int _currentDay = 7;
  int? _pickedDay;

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step = 0);
  }

  void _openReschedule(_ConflictingJob job) {
    setState(() {
      _selected = job;
      _step = 1;
    });
  }

  void _pickDay(int day) {
    if (_unavailableDays.contains(day)) return;
    setState(() {
      _pickedDay = day;
      _selectedDateRangeLabel = "Jan $day, 2026";
    });
  }

  Future<void> _pickFrom() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _from ?? const TimeOfDay(hour: 0, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              dialBackgroundColor: Colors.white,
              hourMinuteTextColor: Colors.black,
              dayPeriodTextColor: Colors.black,
              dialTextColor: Colors.black,
              entryModeIconColor: _brandOrange,
              helpTextStyle: const TextStyle(fontFamily: 'Poppins'),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: _brandOrange,
              brightness: Brightness.light,
            ),
            textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _from = picked;
        _recalcTimeRangeLabel();
      });
    }
  }

  Future<void> _pickTo() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _to ?? const TimeOfDay(hour: 0, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              dialBackgroundColor: Colors.white,
              hourMinuteTextColor: Colors.black,
              dayPeriodTextColor: Colors.black,
              dialTextColor: Colors.black,
              entryModeIconColor: _brandOrange,
              helpTextStyle: const TextStyle(fontFamily: 'Poppins'),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: _brandOrange,
              brightness: Brightness.light,
            ),
            textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _to = picked;
        _recalcTimeRangeLabel();
      });
    }
  }

  void _recalcTimeRangeLabel() {
    if (_from == null && _to == null) {
      _selectedTimeRangeLabel = "Selected Time Range";
      return;
    }
    final f = _from != null ? _fmt(_from!) : "--:--";
    final t = _to != null ? _fmt(_to!) : "--:--";
    _selectedTimeRangeLabel = "$f - $t";
  }

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? "AM" : "PM";
    return "$h:$m $p";
  }

  void _save() {
    if (_pickedDay == null) {
      _toast("Pick an available day");
      return;
    }
    if (_from == null || _to == null) {
      _toast("Select a time range");
      return;
    }

    _toast("Saved (hook API later)");
    // TODO: send update to backend / firebase
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
    final topPad = h * 0.045;

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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePad),
            child: Column(
              children: [
                SizedBox(height: topPad),

                // Header
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
                    SizedBox(width: w * 0.04),
                    Expanded(
                      child: Text(
                        "Schedule",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.055,
                          fontFamily: 'AbrilFatface',
                        ),
                      ),
                    ),
                    const _TopAvatar(),
                    SizedBox(width: w * 0.02),
                    _TopIcon(icon: Icons.notifications_none_rounded, onTap: () {}),
                  ],
                ),

                SizedBox(height: h * 0.012),

                Center(
                  child: _GlassPill(
                    radius: 18,
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.05,
                      vertical: h * 0.007,
                    ),
                    child: Text(
                      "Schedule Jobs to avoid double booking",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: w * 0.03,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.016),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: _step == 0
                        ? _listView(w, h)
                        : _rescheduleView(w, h),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------- Step 0 (List) ---------------------------

  Widget _listView(double w, double h) {
    return ListView(
      key: const ValueKey("list"),
      padding: EdgeInsets.only(bottom: h * 0.02),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Contradicting Jobs",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w900,
                  fontSize: w * 0.04,
                ),
              ),
            ),
            Text(
              "Reschedule one of these Jobs",
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: w * 0.028,
              ),
            ),
          ],
        ),
        SizedBox(height: h * 0.012),

        for (int i = 0; i < _jobs.length; i++) ...[
          _ConflictCard(
            job: _jobs[i],
            onReschedule: () => _openReschedule(_jobs[i]),
            onMore: () => _toast("More actions (hook later)"),
          ),
          if (i != _jobs.length - 1) ...[
            SizedBox(height: h * 0.014),
            Center(
              child: Text(
                "And",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w900,
                  fontSize: w * 0.04,
                ),
              ),
            ),
            SizedBox(height: h * 0.014),
          ],
        ],
      ],
    );
  }

  // --------------------------- Step 1 (Reschedule) ---------------------------

  Widget _rescheduleView(double w, double h) {
    return ListView(
      key: const ValueKey("reschedule"),
      padding: EdgeInsets.only(bottom: h * 0.02),
      children: [
        Text(
          "Reschedule Job Date and Time",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            fontSize: w * 0.04,
          ),
        ),
        SizedBox(height: h * 0.012),

        _pillRow(
          w: w,
          h: h,
          icon: Icons.calendar_month_outlined,
          text: _selectedDateRangeLabel,
        ),

        SizedBox(height: h * 0.012),

        _calendarCard(w, h),

        SizedBox(height: h * 0.014),

        _pillRow(
          w: w,
          h: h,
          icon: Icons.access_time_rounded,
          text: _selectedTimeRangeLabel,
        ),

        SizedBox(height: h * 0.012),

        _timeCard(w, h),

        SizedBox(height: h * 0.02),

        SizedBox(
          width: double.infinity,
          height: h * 0.07,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandOrange,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Save",
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: w * 0.045,
                  ),
                ),
                SizedBox(width: w * 0.02),
                Icon(Icons.arrow_forward, color: Colors.black, size: w * 0.06),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pillRow({
    required double w,
    required double h,
    required IconData icon,
    required String text,
  }) {
    final hh = h * 0.06;
    return Container(
      height: hh,
      padding: EdgeInsets.symmetric(horizontal: w * 0.045),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black, size: w * 0.06),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.034,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarCard(double w, double h) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.012, w * 0.04, h * 0.02),
        child: Column(
          children: [
            // Month header row
            Row(
              children: [
                _circleIconBtn(
                  w: w,
                  icon: Icons.chevron_left,
                  onTap: () => _toast("Prev month (hook later)"),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _monthTitle,
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: w * 0.04,
                      ),
                    ),
                  ),
                ),
                _circleIconBtn(
                  w: w,
                  icon: Icons.chevron_right,
                  onTap: () => _toast("Next month (hook later)"),
                ),
              ],
            ),

            SizedBox(height: h * 0.01),

            // Weekday row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _Weekday("MON"),
                _Weekday("TUE"),
                _Weekday("WED"),
                _Weekday("THU"),
                _Weekday("FRI"),
                _Weekday("SAT"),
                _Weekday("SUN"),
              ],
            ),

            SizedBox(height: h * 0.012),

            // Days grid (simple mock: 1..31 with spacing)
            LayoutBuilder(
              builder: (context, c) {
                final cell = c.maxWidth / 7;
                return Wrap(
                  spacing: 0,
                  runSpacing: h * 0.008,
                  children: List.generate(31, (i) {
                    final day = i + 1;

                    Color bg = const Color(0xFFEDEDED);
                    Color fg = Colors.black;

                    if (_unavailableDays.contains(day)) {
                      bg = _brandRed;
                      fg = Colors.white;
                    }
                    if (day == _currentDay) {
                      bg = _brandGreen;
                      fg = Colors.white;
                    }
                    if (_pickedDay == day) {
                      bg = _brandOrange;
                      fg = Colors.black;
                    }

                    return SizedBox(
                      width: cell,
                      height: cell * 0.85,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _pickDay(day),
                          child: Container(
                            width: cell * 0.58,
                            height: cell * 0.58,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "$day",
                              style: TextStyle(
                                color: fg,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w900,
                                fontSize: w * 0.032,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

            SizedBox(height: h * 0.014),

            // Legend
            Row(
              children: [
                _legendDot(color: _brandRed),
                SizedBox(width: w * 0.02),
                Text(
                  "Unavailable days",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.75),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: w * 0.028,
                  ),
                ),
                SizedBox(width: w * 0.04),
                _legendDot(color: const Color(0xFFEDEDED)),
                SizedBox(width: w * 0.02),
                Text(
                  "Available days",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.75),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: w * 0.028,
                  ),
                ),
                SizedBox(width: w * 0.04),
                _legendDot(color: _brandGreen),
                SizedBox(width: w * 0.02),
                Expanded(
                  child: Text(
                    "Current day",
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.75),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: w * 0.028,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeCard(double w, double h) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.018),
        child: Column(
          children: [
            Text(
              "Choose Your Time",
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.045,
              ),
            ),
            SizedBox(height: h * 0.012),

            Row(
              children: [
                Expanded(
                  child: _timeField(
                    w: w,
                    label: "From",
                    value: _from == null ? "00:00 AM/PM" : _fmt(_from!),
                    onTap: _pickFrom,
                  ),
                ),
                SizedBox(width: w * 0.04),
                Expanded(
                  child: _timeField(
                    w: w,
                    label: "To",
                    value: _to == null ? "00:00 AM/PM" : _fmt(_to!),
                    onTap: _pickTo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeField({
    required double w,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            fontSize: w * 0.032,
          ),
        ),
        SizedBox(height: w * 0.02),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: w * 0.03),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.black.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    color: Colors.black.withOpacity(0.7), size: w * 0.05),
                SizedBox(width: w * 0.02),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.65),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.03,
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

  Widget _circleIconBtn({
    required double w,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w * 0.10,
        height: w * 0.10,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: w * 0.06),
      ),
    );
  }

  Widget _legendDot({required Color color}) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    );
  }
}

// --------------------------- Conflict card ---------------------------

class _ConflictCard extends StatelessWidget {
  final _ConflictingJob job;
  final VoidCallback onReschedule;
  final VoidCallback onMore;

  const _ConflictCard({
    required this.job,
    required this.onReschedule,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.032),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.employerName,
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: w * 0.036,
                  ),
                ),
                SizedBox(height: w * 0.01),
                Text(
                  job.description,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.75),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: w * 0.028,
                  ),
                ),
                SizedBox(height: w * 0.01),
                Text(
                  job.dateRange,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.75),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: w * 0.028,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: w * 0.02),
          Column(
            children: [
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: onReschedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1FE21A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text(
                    "Reschedule",
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: w * 0.01),
              GestureDetector(
                onTap: onMore,
                child: Icon(Icons.more_vert, color: Colors.black, size: w * 0.06),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConflictingJob {
  final String employerName;
  final String description;
  final String dateRange;

  _ConflictingJob({
    required this.employerName,
    required this.description,
    required this.dateRange,
  });
}

// --------------------------- Weekday ---------------------------

class _Weekday extends StatelessWidget {
  final String t;
  const _Weekday(this.t);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          t,
          style: TextStyle(
            color: Colors.black.withOpacity(0.75),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            fontSize: 10.5,
          ),
        ),
      ),
    );
  }
}

// ------------------------------ Glass pill + Top UI helpers ------------------------------

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

class _TopAvatar extends StatelessWidget {
  const _TopAvatar();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      width: w * 0.10,
      height: w * 0.10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white.withOpacity(0.35)),
        image: const DecorationImage(
          image: AssetImage('assets/images/person.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIcon({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w * 0.10,
        height: w * 0.10,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: w * 0.06),
        ),
      ),
    );
  }
}
