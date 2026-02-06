import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:helper/Worker Dashboard/Worker_Jobs_Hub_Screen.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class JobDetailBookingScreen extends StatefulWidget {
  /// ✅ REQUIRED so we can read provider bookings + prevent overlaps
  final String serviceProviderId;

  /// Optional (use whatever you have from WorkerDetailsScreen)
  final String businessName;
  final String profession;
  final dynamic amount;
  final String? pricingType;

  const JobDetailBookingScreen({
    super.key,
    required this.serviceProviderId,
    this.businessName = "Business Name",
    this.profession = "Profession",
    this.amount,
    this.pricingType,
  });

  @override
  State<JobDetailBookingScreen> createState() => _JobDetailBookingScreenState();
}

class _JobDetailBookingScreenState extends State<JobDetailBookingScreen> {
  static const _brandOrange = Color(0xFFFFA10D);

  // ===================== STEPS =====================
  int _step = 0; // 0..3

  // ===================== PHASE 1 (Job Details) =====================
  final _descCtrl = TextEditingController();

  // Uploads
  final List<PlatformFile> _pickedFiles = [];
  bool _pickingFiles = false;

  // Job location (required by you)
  String? _jobLocationText;
  GeoPoint? _jobLatLng;

  // Search location
  final TextEditingController _locationSearchCtrl = TextEditingController();
  List<Map<String, String>> _suggestions = [];
  bool _fetchingSuggestions = false;

  // Google Map
  GoogleMapController? _mapCtrl;
  LatLng? _myLatLng;
  LatLng? _pickedLatLng;
  Marker? _pickedMarker;
  bool _locLoading = false;
  String? _locError;

  // OPTIONAL: reverse geocode to get readable address (replace your key)
  final Dio _dio = Dio();
  static const String _googleKey = 'AIzaSyBUJXjLSEFn_8OfVkaaLAIHYGUcGJEDD9w';

  // ===================== PHASE 2 (Workers & Pricing) =====================
  String? _workingDays;
  String? _workingHours; // only for Per Hour
  String? _workingDaysPerJob; // for Per Job (display only, not used in calculations)
  final _amountCtrl = TextEditingController();

  // ===================== PHASE 3 (Schedule / Calendar) =====================
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _startDate;
  DateTime? _endDate;

  TimeOfDay? _timeFrom;
  TimeOfDay? _timeTo;

  // Availability caches for the visible calendar grid
  bool _loadingMonthBookings = false;
  String? _monthBookingsError;

  // Map: dayKey -> status
  final Map<DateTime, _DayStatus> _dayStatus = {}; // normalized day => status

  // ===================== PHASE 4 (Summary) =====================
  String get _businessName => widget.businessName;
  String get _profession => widget.profession;
  String? _pricingType;
  String? _amount;
  //String? _pricingType;

  String? get _jobDuration {
    if (_startDate == null || _endDate == null) return null;
    final days = _endDate!.difference(_startDate!).inDays + 1;
    final timeRange = (_timeFrom == null || _timeTo == null)
        ? ""
        : " (${_timeFrom!.format(context)} - ${_timeTo!.format(context)})";
    return "$days day${days > 1 ? 's' : ''}$timeRange";
  }

  DateTime get _todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    debugPrint("BOOKING SCREEN providerId: '${widget.serviceProviderId}'");
    if (widget.pricingType != null) {
      _pricingType = widget.pricingType;
    }
    if (widget.amount != null) {
      _amount = widget.amount.toString();
    }
    // Ensure UI shows computed amount when pricing/amount provided by caller
    _recalcAmount();
    if (widget.pricingType == null || widget.amount == null) {
      _fetchServiceProviderData();
    }
    _initLocation();
    _refreshMonthBookings(); // initial calendar availability
    _locationSearchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _locationSearchCtrl.removeListener(_onSearchChanged);
    _locationSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchServiceProviderData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('serviceProviders')
          .doc(widget.serviceProviderId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _pricingType = (data['pricingType'] as String?)?.trim();
          _amount = data['amount']?.toString();

          // ✅ normalize old value
          if ((_pricingType ?? '') == 'Fixed') {
            _pricingType = 'Per Job';
          }

          if (_pricingType == 'Per Day' && _workingDays == null) {
            _workingDays = '1';
          }
          if (_pricingType == 'Per Hour') {
            _workingDays ??= '1';
            _workingHours ??= '1';
          }
        });

        _recalcAmount();
      }
    } catch (e) {
      _toast("Failed to load pricing info: $e");
    }
  }

  // ===================== VALIDATION =====================
  bool get _phase1Complete {
    final okDesc = _descCtrl.text.trim().isNotEmpty;
    final okLocation =
        _jobLocationText != null &&
        _jobLocationText!.trim().isNotEmpty &&
        _jobLatLng != null;
    return okDesc && okLocation;
  }

  int _parseMoney(String s) => int.tryParse(s.replaceAll(',', '').trim()) ?? 0;

  int get _daysSelected => int.tryParse(_workingDays ?? '1') ?? 1;
  int get _hoursSelected => int.tryParse(_workingHours ?? '1') ?? 1;
  int get _baseAmount => int.tryParse((_amount ?? '0').toString()) ?? 0;

  bool get _isPerJob => (_pricingType ?? '').trim() == 'Per Job';
  bool get _isPerDay => (_pricingType ?? '').trim() == 'Per Day';
  bool get _isPerHour => (_pricingType ?? '').trim() == 'Per Hour';
  bool get _isPerWeek => (_pricingType ?? '').trim() == 'Per Week';
  bool get _isPerMonth => (_pricingType ?? '').trim() == 'Per Month';
  bool get _isPerYear => (_pricingType ?? '').trim() == 'Per Year';

  int _computeTotal() {
    final base = _baseAmount;
    if (base <= 0) return 0;

    if (_isPerJob) return base;
    if (_isPerDay) return base * _daysSelected;
    if (_isPerHour) return base * _hoursSelected;

    return base;
  }

  String _amountFormulaText() {
    final fmt = NumberFormat('#,##0');
    final baseFmt = fmt.format(_baseAmount);
    final totalFmt = fmt.format(_computeTotal());

    if (_isPerJob) return "Per job = ($baseFmt)";
    if (_isPerDay) {
      return "$baseFmt per day × $_daysSelected day(s) = ($totalFmt)";
    }
    if (_isPerHour) {
      return "$baseFmt per hour × $_hoursSelected hour(s) = ($totalFmt)";
    }
    if (_isPerWeek) {
      return "$baseFmt per week = ($totalFmt)";
    }
    if (_isPerMonth) {
      return "$baseFmt per month = ($totalFmt)";
    }
    if (_isPerYear) {
      return "$baseFmt per year = ($totalFmt)";
    }

    return "Total = ($totalFmt)";
  }

  void _recalcAmount() {
    final base = int.tryParse((_amount ?? "0").toString()) ?? 0;
    final type = (_pricingType ?? "").trim();

    final days = int.tryParse(_workingDays ?? "1") ?? 1;
    final hours = int.tryParse(_workingHours ?? "1") ?? 1;

    int total;
    if (type == "Per Job") {
      total = base;
    } else if (type == "Per Day") {
      total = base * days;
    } else if (type == "Per Hour") {
      total = base * hours;
    } else if (type == "Per Week" || type == "Per Month" || type == "Per Year") {
      // For Per Week, Per Month, Per Year: just use base amount (no multiplier)
      total = base;
    } else {
      total = base;
    }

    _amountCtrl.text = NumberFormat('#,##0').format(total);
  }

  bool get _phase2Complete {
    final okPricing = (_pricingType != null && _pricingType!.trim().isNotEmpty);
    if (!okPricing) return false;

    // Per Job: no need for days/hours
    if (_isPerJob) return _computeTotal() > 0;

    // Per Day needs days
    if (_isPerDay) return _workingDays != null && _computeTotal() > 0;

    // Per Hour needs days + hours
    if (_isPerHour) {
      return _workingDays != null && _workingHours != null && _computeTotal() > 0;
    }

    // Per Week, Per Month, Per Year: no additional requirements
    if (_isPerWeek || _isPerMonth || _isPerYear) {
      return _computeTotal() > 0;
    }

    return _computeTotal() > 0;
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

  void _next() async {
    FocusScope.of(context).unfocus();

    if (_step == 0) {
      if (!_phase1Complete) {
        _toast(
          "Please add a job description and select job location on the map.",
        );
        return;
      }
      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      if (!_phase2Complete) {
        _toast("Please complete pricing, days/hours, and amount.");
        return;
      }
      setState(() => _step = 2);
      return;
    }

    if (_step == 2) {
      if (_startDate == null) {
        _toast("Please select a start date.");
        return;
      }
      if (_endDate == null) {
        _toast("Please select an end date.");
        return;
      }
      if (_timeFrom == null || _timeTo == null) {
        _toast("Please select time range.");
        return;
      }

      // Final overlap check (date+time)
      final ok = await _validateSelectedRangeOverlap();
      if (!ok) return;

      setState(() => _step = 3);
      return;
    }

    // step 3 -> create booking
    await _createBookingAndGoToWorkerHub();
  }

  // ===================== FILE PICK (PHASE 1) =====================
  Future<void> _pickFiles() async {
    if (_pickingFiles) return;
    setState(() => _pickingFiles = true);

    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
        withData: false,
      );
      if (res == null) return;

      // Limit to 4 files
      final files = res.files.take(4).toList();
      setState(() {
        _pickedFiles
          ..clear()
          ..addAll(files);
      });
      _toast("${_pickedFiles.length} file(s) selected");
    } catch (e) {
      _toast("File pick failed: $e");
    } finally {
      if (mounted) setState(() => _pickingFiles = false);
    }
  }

  // OPTIONAL upload helper (if you later want uploads before payment)
  Future<List<String>> _uploadPickedFiles({
    required String bookingId,
    required String clientId,
  }) async {
    final storage = FirebaseStorage.instance;
    final out = <String>[];

    for (final f in _pickedFiles) {
      if (f.path == null) continue;
      final file = File(f.path!);
      final ext = (f.extension ?? 'file').toLowerCase();
      final name = const Uuid().v4();
      final ref = storage.ref('bookings/$bookingId/$clientId/$name.$ext');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      out.add(url);
    }
    return out;
  }

  // ===================== CREATE BOOKING =====================
  Future<void> _createBookingAndGoToWorkerHub() async {
    try {
      // ✅ current user = employer/client
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _toast("You must be logged in to book.");
        return;
      }

      final providerId = widget.serviceProviderId.trim();
      if (providerId.isEmpty) {
        _toast("BUG: serviceProviderId is empty. Booking not sent.");
        debugPrint("BUG: widget.serviceProviderId='${widget.serviceProviderId}'");
        return;
      }

      // ✅ validate (you already validate per step, but enforce here too)
      if (!_phase1Complete) {
        _toast("Please complete job details first.");
        return;
      }
      if (!_phase2Complete) {
        _toast("Please complete pricing details first.");
        return;
      }
      if (!_phase3Complete) {
        _toast("Please select date and time.");
        return;
      }

      // ✅ build start/end DateTime
      final sDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final eDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

      final from = _timeFrom!;
      final to = _timeTo!;

      final startDateTime = DateTime(
        sDay.year, sDay.month, sDay.day, from.hour, from.minute,
      );

      final endDateTime = DateTime(
        eDay.year, eDay.month, eDay.day, to.hour, to.minute,
      );

      if (!endDateTime.isAfter(startDateTime)) {
        _toast("End time must be after start time.");
        return;
      }

      // ✅ pricing + totals
      final pricingType = (_pricingType ?? "Per Job").trim();

      // base price stored in serviceProviders doc (string/int)
      final baseAmount = int.tryParse((_amount ?? "0").toString()) ?? 0;

      // total shown in _amountCtrl (already formatted)
      final totalAmount = _parseMoney(_amountCtrl.text);

      // ✅ days/hours (only relevant for Per Day/Per Hour)
      final workingDays = int.tryParse(_workingDays ?? '1') ?? 1;
      final workingHours = int.tryParse(_workingHours ?? '1') ?? 1;

      // ✅ create booking doc ref
      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();
      final bookingId = bookingRef.id;

      // ✅ optional attachments upload (only if you want)
      // final attachmentUrls = await _uploadPickedFiles(bookingId: bookingId, clientId: user.uid);
      final attachmentUrls = <String>[]; // keep empty for now

      final bookingData = <String, dynamic>{
        'id': bookingId,

        // employer/client info
        'employerId': user.uid,
        'employerName': widget.businessName,        // if you have real employer name, put it here
        'employerEmail': user.email ?? '',
        'employerPhone': '',

        // provider info
        'serviceProviderId': providerId,

        // job details
        'jobDescription': _descCtrl.text.trim(),
        'jobLocationText': _jobLocationText ?? '',
        'jobLatLng': _jobLatLng, // GeoPoint

        // schedule
        'startDateTime': Timestamp.fromDate(startDateTime),
        'endDateTime': Timestamp.fromDate(endDateTime),

        // pricing
        'pricingType': pricingType,     // "Per Job" / "Per Day" / "Per Hour"
        'baseAmount': baseAmount,       // base price from provider
        'amount': totalAmount,          // ✅ total payable saved in amount
        'workingDays': pricingType == 'Per Job' ? 1 : workingDays,
        'workingHours': pricingType == 'Per Hour' ? workingHours : 0,

        // booking flow state
        'status': 'pending',
        'hasConflict': false,

        // metadata
        'attachments': attachmentUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await bookingRef.set(bookingData);

      _toast("Booking request sent!");

      // ✅ go to worker hub screen
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WorkerJobsHubScreen(providerId: widget.serviceProviderId)),
      );
    } catch (e) {
      debugPrint("CREATE BOOKING ERROR: $e");
      _toast("Failed to send booking: $e");
    }
  }

  // ===================== LOCATION (MAP) =====================
  Future<void> _initLocation() async {
    setState(() {
      _locLoading = true;
      _locError = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception("Location services are OFF. Turn on GPS.");

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception(
          "Location permission denied forever. Enable it in settings.",
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final me = LatLng(pos.latitude, pos.longitude);
      setState(() => _myLatLng = me);

      if (_mapCtrl != null) {
        _mapCtrl!.animateCamera(CameraUpdate.newLatLngZoom(me, 14));
      }
    } catch (e) {
      setState(() => _locError = e.toString());
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    // If you don't want reverse geocoding, you can delete this and just set lat/lng text
    try {
      if (_googleKey == "REPLACE_WITH_YOUR_GOOGLE_MAPS_KEY") return;

      final res = await _dio.get(
        "https://maps.googleapis.com/maps/api/geocode/json",
        queryParameters: {
          "latlng": "${latLng.latitude},${latLng.longitude}",
          "key": _googleKey,
          "language": "en",
        },
      );

      final results = (res.data["results"] as List? ?? []);
      if (results.isEmpty) return;

      final addr = results.first["formatted_address"] as String?;
      if (addr != null && addr.trim().isNotEmpty) {
        setState(() => _jobLocationText = addr.trim());
      }
    } catch (_) {
      // ignore reverse-geocode failures
    }
  }

  void _onSearchChanged() {
    final query = _locationSearchCtrl.text.trim();
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _fetchSuggestions(query);
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _fetchingSuggestions = true);
    try {
      print("Fetching suggestions for: $query");
      final res = await _dio.get(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json",
        queryParameters: {
          "input": query,
          "key": _googleKey,
          // Removed types to allow broader search
        },
      );
      print("API Response: ${res.data}");
      final predictions = (res.data["predictions"] as List? ?? [])
          .take(5)
          .map(
            (p) => {
              "description": p["description"] as String,
              "placeId": p["place_id"] as String,
            },
          )
          .toList();
      print("Parsed suggestions: $predictions");
      setState(() => _suggestions = predictions);
    } catch (e) {
      print("Error fetching suggestions: $e");
      setState(() => _suggestions = []);
    } finally {
      setState(() => _fetchingSuggestions = false);
    }
  }

  Future<void> _selectSuggestion(String description, String placeId) async {
    try {
      final res = await _dio.get(
        "https://maps.googleapis.com/maps/api/place/details/json",
        queryParameters: {
          "place_id": placeId,
          "key": _googleKey,
          "fields": "geometry",
        },
      );
      final location = res.data["result"]["geometry"]["location"];
      final lat = location["lat"];
      final lng = location["lng"];
      setState(() {
        _jobLocationText = description;
        _jobLatLng = GeoPoint(lat, lng);
        _pickedLatLng = LatLng(lat, lng);
        _pickedMarker = Marker(
          markerId: const MarkerId("job_location"),
          position: _pickedLatLng!,
        );
      });
      if (_mapCtrl != null) {
        _mapCtrl!.animateCamera(CameraUpdate.newLatLngZoom(_pickedLatLng!, 14));
      }
      _locationSearchCtrl.clear();
      _suggestions = [];
    } catch (e) {
      // Fallback: just set the text
      setState(() {
        _jobLocationText = description;
        _locationSearchCtrl.clear();
        _suggestions = [];
      });
    }
  }

  void _onMapTap(LatLng latLng) async {
    setState(() {
      _pickedLatLng = latLng;
      _pickedMarker = Marker(
        markerId: const MarkerId("job_location"),
        position: latLng,
      );
      _jobLatLng = GeoPoint(latLng.latitude, latLng.longitude);
      _jobLocationText =
          _jobLocationText ??
          "${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}";
    });

    await _reverseGeocode(latLng);
  }

  // ===================== TIME PICKERS =====================
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

    // If you already selected a date range, validate with time too
    if (_startDate != null && _endDate != null) {
      await _validateSelectedRangeOverlap();
    }
  }

  // ===================== CALENDAR: SELECTION + AVAILABILITY =====================
  void _toggleDay(DateTime day) async {
    final d = DateTime(day.year, day.month, day.day);

    // Block past days
    if (d.isBefore(_todayStart)) {
      _toast("You can't book past dates.");
      return;
    }

    // Block booked
    final status = _dayStatus[d] ?? _DayStatus.available;
    if (status == _DayStatus.booked) {
      _toast("That day is already booked.");
      return;
    }

    // Start new range if none or already completed
    if (_startDate == null || (_startDate != null && _endDate != null)) {
      setState(() {
        _startDate = d;
        _endDate = null;
      });
      return;
    }

    // Start exists, end null -> choose end
    if (d.isBefore(_startDate!)) {
      setState(() {
        _endDate = _startDate;
        _startDate = d;
      });
    } else {
      setState(() => _endDate = d);
    }

    // Validate overlap (date-only ALWAYS now)
    final ok = await _validateSelectedRangeOverlap(dateOnly: true);
    if (!ok) {
      setState(() => _endDate = null);
    }
  }

  Future<void> _refreshMonthBookings() async {
    setState(() {
      _loadingMonthBookings = true;
      _monthBookingsError = null;
    });

    try {
      final grid = _buildMonthGrid(_calendarMonth);
      final nonNullDays = grid.whereType<DateTime>().toList();

      if (nonNullDays.isEmpty) {
        setState(() => _dayStatus.clear());
        return;
      }

      final windowStart = DateTime(
        nonNullDays.first.year,
        nonNullDays.first.month,
        nonNullDays.first.day,
        0,
        0,
        0,
      );

      final windowEndExclusive = DateTime(
        nonNullDays.last.year,
        nonNullDays.last.month,
        nonNullDays.last.day,
        23,
        59,
        59,
      ).add(const Duration(seconds: 1));

      // Any booking that intersects this month window.
      final qs = await FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceProviderId', isEqualTo: widget.serviceProviderId)
          .where('status', whereIn: const ['pending', 'confirmed', 'accepted'])
          .where('startDateTime', isLessThan: Timestamp.fromDate(windowEndExclusive))
          .where('endDateTime', isGreaterThan: Timestamp.fromDate(windowStart))
          .get();

      final bookings = qs.docs.map((d) => d.data()).toList();

      final Map<DateTime, _DayStatus> statusMap = {};
      for (final day in nonNullDays) {
        final dn = DateTime(day.year, day.month, day.day);
        statusMap[dn] = _DayStatus.available;
      }

      // Mark every covered day as booked (no partial).
      for (final b in bookings) {
        final st = (b['startDateTime'] as Timestamp?)?.toDate();
        final en = (b['endDateTime'] as Timestamp?)?.toDate();
        if (st == null || en == null) continue;

        DateTime cursor = DateTime(st.year, st.month, st.day);
        final endDay = DateTime(en.year, en.month, en.day);

        while (!cursor.isAfter(endDay)) {
          final key = DateTime(cursor.year, cursor.month, cursor.day);
          if (statusMap.containsKey(key)) {
            statusMap[key] = _DayStatus.booked;
          }
          cursor = cursor.add(const Duration(days: 1));
        }
      }

      setState(() {
        _dayStatus
          ..clear()
          ..addAll(statusMap);
      });
    } catch (e) {
      setState(() => _monthBookingsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingMonthBookings = false);
    }
  }

  Future<bool> _validateSelectedRangeOverlap({bool dateOnly = false}) async {
    if (_startDate == null || _endDate == null) return true;

    // Build newStart/newEnd (date-only OR date+time)
    final sDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final eDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

    DateTime newStart;
    DateTime newEnd;

    if (dateOnly || _timeFrom == null || _timeTo == null) {
      // Date-only: treat as whole-day interval to prevent overlaps across ranges
      newStart = DateTime(sDay.year, sDay.month, sDay.day, 0, 0, 0);
      newEnd = DateTime(
        eDay.year,
        eDay.month,
        eDay.day,
        23,
        59,
        59,
      ).add(const Duration(seconds: 1));
    } else {
      // Date+time:
      // - If range is multiple days, we apply the same time window across all days for safety.
      //   (If you later want "time only for first day", tell me and I'll adjust.)
      final from = _timeFrom!;
      final to = _timeTo!;

      newStart = DateTime(
        sDay.year,
        sDay.month,
        sDay.day,
        from.hour,
        from.minute,
      );

      // end uses end day + to-time
      newEnd = DateTime(eDay.year, eDay.month, eDay.day, to.hour, to.minute);
      if (!newEnd.isAfter(newStart)) {
        _toast("End time must be after start time.");
        return false;
      }
    }

    try {
      // Overlap rule:
      // existing.start < newEnd AND existing.end > newStart
      final qs = await FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceProviderId', isEqualTo: widget.serviceProviderId)
          .where('status', whereIn: const ['pending', 'confirmed', 'accepted'])
          .where('startDateTime', isLessThan: Timestamp.fromDate(newEnd))
          .where('endDateTime', isGreaterThan: Timestamp.fromDate(newStart))
          .limit(1)
          .get();

      if (qs.docs.isNotEmpty) {
        _toast("That date/time range overlaps with an existing booking.");
        return false;
      }

      return true;
    } catch (e) {
      _toast("Failed to validate booking availability: $e");
      return false;
    }
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

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final sidePad = w * 0.06;

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

                    Center(
                      child: _StepIndicator(
                        width: w,
                        // allow activeIndex 0..3
                        activeIndex: _step,
                        // Order: Job Details -> Payment Details -> Choose Date -> Summary
                        labels: const [
                          'Job Details',
                          'Payment Details',
                          'Choose Date',
                          'Summary',
                        ],
                        accent: _brandOrange,
                      ),
                    ),
                    SizedBox(height: h * 0.019),

                    Center(
                      child: Text(
                        _stepHeadline(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          fontSize: w * 0.045,
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

                    SizedBox(height: h * 0.05),

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
    if (_step == 3) return "Summary";
    if (_step == 2) return "Choose Date";
    if (_step == 1) return "Payment Details";
    return "Job Details";
  }

  String _stepHeadline() {
    if (_step == 0) return "Job Details";
    if (_step == 1) return "Payment Details";
    if (_step == 2) return "Choose Date";
    return "Summary / Preview";
  }

  // ===================== PHASE 1 (Job Details) =====================
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
          subtitle: "Supported files: PDF/PNG/JPEG/JPG\nLimit: 4 files",
          onTap: _pickFiles,
          selectedCount: _pickedFiles.length,
          loading: _pickingFiles,
        ),

        SizedBox(height: h * 0.018),

        Row(
          children: [
            _label("Job Location", w),
            const Spacer(),
            Text(
              "Search for your Job Location",
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

        // Add text field for searching location
        Container(
          width: double.infinity,
          height: h * 0.06,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _locationSearchCtrl,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: Colors.black),
              hintText: "Search for job location...",
              hintStyle: TextStyle(
                color: Colors.black.withOpacity(0.5),
                fontFamily: 'Inter',
                fontSize: w * 0.035,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: h * 0.015,
              ),
            ),
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Inter',
              fontSize: w * 0.035,
            ),
          ),
        ),
        if (_fetchingSuggestions)
          Padding(
            padding: EdgeInsets.only(top: h * 0.010),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_suggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: h * 0.010),
            constraints: BoxConstraints(maxHeight: h * 0.2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return InkWell(
                  onTap: () =>
                      _selectSuggestion(item["description"]!, item["placeId"]!),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04,
                      vertical: h * 0.01,
                    ),
                    child: Text(
                      item["description"]!,
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Inter',
                        fontSize: w * 0.035,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        SizedBox(height: h * 0.010),

        SizedBox(height: h * 0.010),

        _liveJobMap(w, h),

        SizedBox(height: h * 0.010),

        // Location pill (small)
        _pillDisplay(
          w: w,
          h: h * 0.6, // Make it smaller
          leading: Icons.location_on_rounded,
          text: _jobLocationText == null
              ? "Search For The Job Location"
              : _jobLocationText!,
        ),

        if (_locLoading) ...[
          SizedBox(height: h * 0.010),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_locError != null) ...[
          SizedBox(height: h * 0.010),
          Text(
            _locError!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: w * 0.030,
            ),
          ),
        ],
      ],
    );
  }

  Widget _liveJobMap(double w, double h) {
    final mapH = h * 0.26;

    final initial =
        _myLatLng ?? const LatLng(0.3476, 32.5825); // Kampala fallback

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: mapH,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: initial, zoom: 13),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          onMapCreated: (c) {
            _mapCtrl = c;
            if (_myLatLng != null) {
              c.animateCamera(CameraUpdate.newLatLngZoom(_myLatLng!, 14));
            }
          },
          markers: {if (_pickedMarker != null) _pickedMarker!},
          onTap: _onMapTap,
        ),
      ),
    );
  }

  // ===================== PHASE 2 (Workers & Pricing) =====================
  Widget _phase2(double w, double h) {
    return Column(
      key: const ValueKey('phase2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isPerJob) ...[
          _label("Number of Working Days", w),
          SizedBox(height: h * 0.010),
          _pillDropdown(
            w: w,
            h: h,
            hint: "Select the number of working days",
            value: _workingDays,
            items: List.generate(30, (i) => "${i + 1}"),
            onChanged: (v) {
              setState(() => _workingDays = v);
              _recalcAmount();
            },
          ),
          SizedBox(height: h * 0.016),
        ],

        if (_isPerHour) ...[
          _label("Working Hours (per day)", w),
          SizedBox(height: h * 0.010),
          _pillDropdown(
            w: w,
            h: h,
            hint: "Select working hours per day",
            value: _workingHours,
            items: List.generate(12, (i) => "${i + 1}"),
            onChanged: (v) {
              setState(() => _workingHours = v);
              _recalcAmount();
            },
          ),
          SizedBox(height: h * 0.016),
        ],

        if (_isPerJob) ...[
          _label("Number of Working Days", w),
          SizedBox(height: h * 0.010),
          _pillDropdown(
            w: w,
            h: h,
            hint: "Select the number of working days",
            value: _workingDaysPerJob,
            items: List.generate(30, (i) => "${i + 1}"),
            onChanged: (v) {
              setState(() => _workingDaysPerJob = v);
            },
          ),
          SizedBox(height: h * 0.016),
        ],

        _label("Pricing Type", w),
        SizedBox(height: h * 0.010),
        _pillDisplay(
          w: w,
          h: h,
          leading: Icons.payments_rounded,
          text: _pricingType ?? "Loading pricing...",
        ),

        SizedBox(height: h * 0.016),

        _label("Amount", w),
        SizedBox(height: h * 0.006),
        Text(
          _amountFormulaText(),
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
          hint: "Amount (auto-calculated)",
          keyboardType: TextInputType.number,
          inputFormatters: [],
          readOnly: true,
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

  // ===================== PHASE 3 (Calendar + Time) =====================
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
              ? "Select a date range"
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
          text: (_timeFrom == null || _timeTo == null)
              ? "Select time range"
              : "${_timeFrom!.format(context)} → ${_timeTo!.format(context)}",
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

  Widget _calendarCard(double w, double h) {
    // Increase calendar height to ensure all rows are visible on smaller screens
    final cardH = h * 0.60;

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
                  onTap: () async {
                    setState(() {
                      _calendarMonth = DateTime(
                        _calendarMonth.year,
                        _calendarMonth.month - 1,
                      );
                    });
                    await _refreshMonthBookings();
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
                  onTap: () async {
                    setState(() {
                      _calendarMonth = DateTime(
                        _calendarMonth.year,
                        _calendarMonth.month + 1,
                      );
                    });
                    await _refreshMonthBookings();
                  },
                ),
              ],
            ),

            SizedBox(height: h * 0.010),

            if (_loadingMonthBookings)
              const LinearProgressIndicator(minHeight: 3),
            if (_monthBookingsError != null) ...[
              SizedBox(height: h * 0.006),
              Text(
                "Bookings load error: $_monthBookingsError",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: w * 0.030,
                ),
              ),
            ],

            SizedBox(height: h * 0.012),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _legendDot(color: Colors.green.shade400, label: "Available", w: w),
                _legendDot(color: Colors.red.shade400, label: "Booked/Selected", w: w),
                _legendDot(color: Colors.grey.shade400, label: "Past", w: w),
                _legendDot(color: Colors.blue.shade400, label: "Today", w: w),
              ],
            ),

            SizedBox(height: h * 0.012),

            // Weekday labels
            Row(
              children: List.generate(7, (i) {
                return Expanded(
                  child: Center(
                    child: Text(
                      weekdays[i],
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.55),
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: w * 0.030,
                      ),
                    ),
                  ),
                );
              }),
            ),

            SizedBox(height: h * 0.008),

            // Grid
            Expanded(
              child: GridView.builder(
                // keep grid non-scrollable inside the card; card height increased
                physics: const NeverScrollableScrollPhysics(),
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (_, i) {
                  final day = days[i];
                  if (day == null) return const SizedBox.shrink();

                  final normalized = DateTime(day.year, day.month, day.day);
                  final inRange = _inRange(normalized);
                  final isToday = _isSameDay(normalized, DateTime.now());
                  final isPast = normalized.isBefore(_todayStart);

                  final status = _dayStatus[normalized] ?? _DayStatus.available;

                  Color bg;

                  // Past days (grey)
                  if (isPast) {
                    bg = Colors.grey.shade400;
                  } else {
                    // Selected OR booked are red
                    if (inRange || status == _DayStatus.booked) {
                      bg = Colors.red.shade400;
                    } else {
                      // Available future is green
                      bg = Colors.green.shade400;
                    }
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: isPast ? null : () => _toggleDay(normalized),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(
                                color: Colors.blue.shade400,
                                width: 2.2,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "${normalized.day}",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w900,
                          fontSize: w * 0.035,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: h * 0.010),

            // Quick range buttons
            Row(
              children: [
                Expanded(
                  child: _smallChipBtn(
                    w: w,
                    label: "1 Week",
                    onTap: () => _quickRange(days: 7),
                  ),
                ),
                SizedBox(width: w * 0.02),
                Expanded(
                  child: _smallChipBtn(
                    w: w,
                    label: "2 Weeks",
                    onTap: () => _quickRange(days: 14),
                  ),
                ),
                SizedBox(width: w * 0.02),
                Expanded(
                  child: _smallChipBtn(
                    w: w,
                    label: "1 Month",
                    onTap: () => _quickRange(days: 30),
                  ),
                ),
                SizedBox(width: w * 0.02),
                Expanded(
                  child: _smallChipBtn(
                    w: w,
                    label: "Clear",
                    onTap: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickRange({required int days}) async {
    if (_startDate == null) {
      _toast("Tap a start date first.");
      return;
    }

    // date-only quick range
    final end = _startDate!.add(Duration(days: days - 1));

    setState(() => _endDate = DateTime(end.year, end.month, end.day));

    final ok = await _validateSelectedRangeOverlap(dateOnly: true);
    if (!ok) {
      setState(() => _endDate = null);
    }
  }

  // ===================== PHASE 4 (Summary) =====================
  Widget _phase4(double w, double h) {
    return Column(
      key: const ValueKey('phase4'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_summaryCard(w, h)],
    );
  }

  Widget _summaryCard(double w, double h) {
    TextStyle left = TextStyle(
      color: Colors.black,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w900,
      fontSize: w * 0.032,
    );
    TextStyle right = TextStyle(
      color: Colors.black.withOpacity(0.75),
      fontFamily: 'Inter',
      fontWeight: FontWeight.w800,
      fontSize: w * 0.032,
    );

    Widget row(String l, String r) {
      return Padding(
        padding: EdgeInsets.only(bottom: h * 0.010),
        child: Row(
          children: [
            Expanded(child: Text(l, style: left)),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  r.isEmpty ? "-" : r,
                  textAlign: TextAlign.right,
                  style: right,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Summary",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: w * 0.050,
                ),
              ),
            ),
            SizedBox(height: h * 0.015),
            _dashedDivider(color: Colors.black.withOpacity(0.25)),
            SizedBox(height: h * 0.015),

            row("Business", _businessName),
            row("Profession", _profession),
            row("Job Description", _descCtrl.text.trim()),
            row("Working Days", _workingDays ?? ""),
            row("Duration", _jobDuration ?? ""),
            row("Amount", _amountCtrl.text.trim()),
            row("Job Location", _jobLocationText ?? ""),
            row(
              "Dates",
              _startDate == null
                  ? "-"
                  : "${_fmtDate(_startDate!)} → ${_fmtDate(_endDate ?? _startDate!)}",
            ),
            row(
              "Time",
              (_timeFrom == null || _timeTo == null)
                  ? "-"
                  : "${_timeFrom!.format(context)} → ${_timeTo!.format(context)}",
            ),

            SizedBox(height: h * 0.012),
            _dashedDivider(color: Colors.black.withOpacity(0.25)),
            SizedBox(height: h * 0.012),

            Text(
              "If everything is correct, tap Continue to Payment.",
              style: TextStyle(
                color: _brandOrange,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.032,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== SMALL UI HELPERS =====================
  Widget _legendDot({
    required Color color,
    required String label,
    required double w,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: w * 0.015),
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.65),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            fontSize: w * 0.028,
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
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: w * 0.09,
        height: w * 0.09,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: w * 0.06),
      ),
    );
  }

  Widget _smallChipBtn({
    required double w,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: w * 0.09,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            fontSize: w * 0.030,
          ),
        ),
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
    final fieldH = h * 0.065;
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        height: fieldH,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.60),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: w * 0.032,
                ),
              ),
            ),
            const Spacer(),
            Text(
              time == null ? "--:--" : time.format(context),
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.034,
              ),
            ),
            SizedBox(width: w * 0.02),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black,
              size: w * 0.06,
            ),
          ],
        ),
      ),
    );
  }

  // ===================== MONTH GRID =====================
  List<DateTime?> _buildMonthGrid(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = last.day;

    // Monday=1..Sunday=7 => we want grid starting Monday.
    final firstWeekday = first.weekday; // 1..7
    final leading = firstWeekday - 1; // 0..6

    final totalCells = leading + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final gridSize = rows * 7;

    final out = List<DateTime?>.filled(gridSize, null);
    int idx = leading;
    for (int d = 1; d <= daysInMonth; d++) {
      out[idx++] = DateTime(month.year, month.month, d);
    }
    return out;
  }

  // ===================== FORMATTERS =====================
  String _fmtDate(DateTime d) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }

  String _monthName(int m) {
    const months = [
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
    return months[m - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ===================== COMMON WIDGETS (MATCH YOUR STYLE) =====================
  Text _label(String t, double w) {
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

  Widget _pillDisplay({
    required double w,
    required double h,
    required IconData leading,
    required String text,
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
          Icon(leading, color: Colors.black, size: w * 0.06),
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
                fontSize: w * 0.03,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteTextArea({
    required double w,
    required double h,
    required TextEditingController controller,
    required String hint,
  }) {
    final boxH = h * 0.17;
    return Container(
      height: boxH,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.012),
      child: TextField(
        controller: controller,
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

  Widget _pillTextField({
    required double w,
    required double h,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
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
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        style: TextStyle(
          color: Colors.black,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w900,
          fontSize: w * 0.038,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: w * 0.035,
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
              fontWeight: FontWeight.w900,
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
                      fontWeight: FontWeight.w900,
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

  Widget _uploadBox({
    required double w,
    required double h,
    required String subtitle,
    required VoidCallback onTap,
    required int selectedCount,
    required bool loading,
  }) {
    final boxH = h * 0.22;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: loading ? null : onTap,
      child: Container(
        height: boxH,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.4),
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_upload_rounded,
                      color: Colors.white,
                      size: w * 0.14,
                    ),
                    SizedBox(height: h * 0.01),
                    Text(
                      "Upload File",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: w * 0.04,
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
                        height: 1.25,
                      ),
                    ),
                    if (selectedCount > 0) ...[
                      SizedBox(height: h * 0.012),
                      Text(
                        "$selectedCount file(s) selected",
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
    );
  }

  Widget _dashedDivider({required Color color}) {
    return CustomPaint(
      painter: _DashedLinePainter(color: color),
      child: const SizedBox(height: 1),
    );
  }
}

// ===================== ENUMS =====================
enum _DayStatus { available, booked }

// ===================== TOP BAR =====================
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
    return Padding(
      padding: EdgeInsets.only(top: w * 0.05),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
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
          SizedBox(width: w * 0.05),
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
                    fontSize: w * 0.055,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: w * 0.01),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: w * 0.032,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== STEP INDICATOR =====================
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
    final dotSize = width * 0.030;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(labels.length, (i) {
        final isActive = i == activeIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            children: [
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? accent : Colors.white.withOpacity(0.35),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: TextStyle(
                  color: Colors.white.withOpacity(isActive ? 1 : 0.65),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: width * 0.026,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ===================== DASHED LINE =====================
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