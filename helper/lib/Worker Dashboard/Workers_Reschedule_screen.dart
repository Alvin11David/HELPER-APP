import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:helper/Components/Worker_Notifications.dart';

class WorkerJobRescheduleScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const WorkerJobRescheduleScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  @override
  State<WorkerJobRescheduleScreen> createState() =>
      _WorkerJobRescheduleScreenState();
}

class _WorkerJobRescheduleScreenState extends State<WorkerJobRescheduleScreen> {
  static const _brandOrange = Color(0xFFFFA10D);
  static const _brandGreen = Color(0xFF24E61F);
  static const _brandRed = Color(0xFFFF2B2B);

  // Date/time selections (UI)
  String _selectedDateRangeLabel = "Select date range";
  String _selectedTimeRangeLabel = "Select time range";

  TimeOfDay? _from;
  TimeOfDay? _to;
  GeoPoint? _proposedLocation;
  bool _attachingLocation = false;
  final TextEditingController _noteController = TextEditingController();

  // Displayed month/year (fixes wrong year/month issues)
  final int _displayYear = DateTime.now().year;
  final int _displayMonth = DateTime.now().month;
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  String get _monthTitle => '${_monthNames[_displayMonth - 1]} $_displayYear';

  // Calendar month helpers
  final Set<int> _unavailableDays = {16, 17, 18, 19, 20, 21};
  final int _currentDay = DateTime.now().day;
  int? _rangeStart;
  int? _rangeEnd;

  void _back() {
    Navigator.of(context).maybePop();
  }


  void _pickDay(int day) {
    if (_unavailableDays.contains(day)) return;
    setState(() {
      if (_rangeStart == null) {
        _rangeStart = day;
        _selectedDateRangeLabel = "${_monthNames[_displayMonth - 1]} $day, $_displayYear";
      } else if (_rangeEnd == null) {
        if (day < _rangeStart!) {
          _rangeEnd = _rangeStart;
          _rangeStart = day;
        } else {
          _rangeEnd = day;
        }
        _selectedDateRangeLabel = "${_monthNames[_displayMonth - 1]} $_rangeStart - $_rangeEnd, $_displayYear";
      } else {
        // Reset for new selection
        _rangeStart = day;
        _rangeEnd = null;
        _selectedDateRangeLabel = "${_monthNames[_displayMonth - 1]} $day, $_displayYear";
      }
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
              helpTextStyle: const TextStyle(fontFamily: 'Inter'),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: _brandOrange,
              brightness: Brightness.light,
            ),
            textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Inter'),
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
              helpTextStyle: const TextStyle(fontFamily: 'Inter'),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: _brandOrange,
              brightness: Brightness.light,
            ),
            textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Inter'),
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

  Future<void> _attachLocation() async {
    setState(() => _attachingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled');

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) throw Exception('Location permission denied');

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _proposedLocation = GeoPoint(pos.latitude, pos.longitude);
      });
      _toast('Location attached');
    } catch (e) {
      _toast('Could not attach location: $e');
    } finally {
      setState(() => _attachingLocation = false);
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

  Future<void> _save() async {
    final worker = FirebaseAuth.instance.currentUser;
    if (worker == null) {
      _toast("Not logged in");
      return;
    }

    if (_rangeStart == null || _rangeEnd == null) {
      _toast("Pick a date range");
      return;
    }
    if (_from == null || _to == null) {
      _toast("Pick a time range");
      return;
    }

    final bookingId = widget.bookingId;
    final workerId = worker.uid;

    final startDate = DateTime(_displayYear, _displayMonth, _rangeStart!);
    final endDate = DateTime(_displayYear, _displayMonth, _rangeEnd!);

    final newStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      _from!.hour,
      _from!.minute,
    );

    final newEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      _to!.hour,
      _to!.minute,
    );

    if (!newEnd.isAfter(newStart)) {
      _toast("End must be after start");
      return;
    }

    // Confirm with user before sending
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm reschedule'),
        content: const Text('Make sure you\'ve talked to the employer before rescheduling. Sending will notify the employer to review the proposed schedule. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirm & Send')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final resPayload = {
        'state': 'pending',
        'proposedStart': Timestamp.fromDate(newStart),
        'proposedEnd': Timestamp.fromDate(newEnd),
        'proposedLocationText': null,
        'proposedLatLng': null,
        'note': (_noteController.text).trim(),
        'requestedById': workerId,
        'requestedAt': FieldValue.serverTimestamp(),
        'employerDecisionById': null,
        'decidedAt': null,
      };
      if (_proposedLocation != null) {
        resPayload['proposedLatLng'] = _proposedLocation!;
      }

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': 'reschedule_requested',
        'reschedule': resPayload,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final employerId = (widget.bookingData['employerId'] ?? '').toString();
      if (employerId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'reschedule_request',
          'toUserId': employerId,
          'fromUserId': workerId,
          'bookingId': bookingId,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'title': 'Reschedule request',
          'message': 'Worker proposed a new schedule',
        });
      }

      _toast('Request sent');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving reschedule: $e');
      _toast('Error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _workerBookingsStream(String workerId) {
    return FirebaseFirestore.instance
        .collection('bookings')
      .where('workerUid', isEqualTo: workerId)
        .where('status', whereIn: const ['pending', 'confirmed', 'reschedule_requested'])
        .orderBy('startDateTime', descending: false)
        .snapshots();
  }

  bool _overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  List<Map<String, dynamic>> _findConflicts(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final bookings = docs.map((d) {
      final data = d.data();
      return {
        'id': d.id,
        ...data,
        'start': (data['startDateTime'] as Timestamp).toDate(),
        'end': (data['endDateTime'] as Timestamp).toDate(),
      };
    }).toList();

    final conflicts = <Map<String, dynamic>>[];

    for (int i = 0; i < bookings.length; i++) {
      for (int j = i + 1; j < bookings.length; j++) {
        final a = bookings[i];
        final b = bookings[j];
        if (_overlaps(a['start'], a['end'], b['start'], b['end'])) {
          conflicts.add(a);
          conflicts.add(b);
        }
      }
    }

    // remove duplicates by id
    final seen = <String>{};
    return conflicts.where((c) => seen.add(c['id'])).toList();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: Colors.black.withOpacity(0.85),
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final sidePad = w * 0.06;
    final topPad = h * 0.025;

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
                    SizedBox(width: w * 0.05),
                    Expanded(
                      child: Text(
                        "Schedule",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.055,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.03),
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
                    Stack(
                      children: [
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
                        Positioned(
                          right: 0,
                          top: 0,
                          child: WorkerNotificationsBadge(),
                        ),
                      ],
                    ),
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
                        fontFamily: 'Inter',
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
                    child: _rescheduleView(w, h),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            fontFamily: 'Inter',
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

        // Optional note
        Container(
          padding: EdgeInsets.symmetric(horizontal: w * 0.03),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a note (optional) — reason for reschedule',
              border: InputBorder.none,
            ),
            style: TextStyle(fontFamily: 'Inter', fontSize: w * 0.034),
          ),
        ),

        SizedBox(height: h * 0.02),

        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _attachLocation,
              icon: _attachingLocation ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.location_on_outlined),
              label: Text(_proposedLocation == null ? 'Attach Location (optional)' : 'Location attached', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: _brandOrange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)), padding: EdgeInsets.symmetric(vertical: h * 0.016)),
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
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
                      fontFamily: 'Inter',
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
        ]),
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
                        fontFamily: 'Inter',
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
                    if (_rangeStart != null &&
                        _rangeEnd != null &&
                        day >= _rangeStart! &&
                        day <= _rangeEnd!) {
                      bg = _brandOrange;
                      fg = Colors.white;
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
                                fontFamily: 'Inter',
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
                    fontFamily: 'Inter',
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
                    fontFamily: 'Inter',
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
                      fontFamily: 'Inter',
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
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.05,
          vertical: h * 0.018,
        ),
        child: Column(
          children: [
            Text(
              "Choose Your Time",
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Inter',
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
            fontFamily: 'Inter',
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
                Icon(
                  Icons.access_time_rounded,
                  color: Colors.black.withOpacity(0.7),
                  size: w * 0.05,
                ),
                SizedBox(width: w * 0.02),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.65),
                      fontFamily: 'Inter',
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
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Conflict UI removed: this screen now operates on a single bookingId + bookingData

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
            fontFamily: 'Inter',
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
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.6,
            ),
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

  const _TopIcon({required this.icon, required this.onTap});

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
