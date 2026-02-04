import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart'; // Add this import for NumberFormat
import '../Worker Dashboard/Workers_Dashboard_Screen.dart'; // Add this import

class WorkerSkillsJobDetailsScreen extends StatefulWidget {
  final String? selectedProfession;
  const WorkerSkillsJobDetailsScreen({super.key, this.selectedProfession});

  @override
  State<WorkerSkillsJobDetailsScreen> createState() =>
      _WorkerSkillsJobDetailsScreenState();
}

class _WorkerSkillsJobDetailsScreenState
    extends State<WorkerSkillsJobDetailsScreen> {
  static const _brandOrange = Color(0xFFFFA10D);

  int _step = 0; // 0,1,2,3 (3 = preview)

  final _formStep1 = GlobalKey<FormState>();
  final _formStep2 = GlobalKey<FormState>();

  // Step 1 controllers/values
  String? _jobCategoryId;
  String? _jobCategory;
  final _businessNameCtrl = TextEditingController();
  final _skillsDescCtrl = TextEditingController();
  final _jobCategoryCtrl = TextEditingController();
  String? _yearsExp; // required
  String? _pricingType; // required
  final _amountCtrl = TextEditingController();

  // Step 2 controllers/values
  final _workplaceCtrl = TextEditingController();
  String? _experienceLevel;
  bool _pickedPlaceOnMap = false; // optional

  // Step 3 state
  final List<PlatformFile> _pickedFiles = [];
  final List<String> _existingPortfolioUrls =
      []; // URLs of existing portfolio files

  bool _saving = false;

  // professions loaded from Firestore
  bool _loadingCategories = true;
  List<Map<String, dynamic>> _categories = [];

  String? _workerType;

  // Google Maps state
  GoogleMapController? _mapCtrl;
  LatLng? _pickedLatLng;
  Marker? _pickedMarker;
  bool _loadingLoc = false;
  Position? _myPos;

  // Places autocomplete
  final _places = Dio();
  List<Map<String, dynamic>> _suggestions = [];
  bool _searching = false;

  static const String _googleKey =
      "AIzaSyBUJXjLSEFn_8OfVkaaLAIHYGUcGJEDD9w"; // better: load from env

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _businessNameCtrl.addListener(_recalcProgress);
    _skillsDescCtrl.addListener(_recalcProgress);
    _amountCtrl.addListener(_recalcProgress);
    _jobCategoryCtrl.addListener(_recalcProgress);
    _workplaceCtrl.addListener(_recalcProgress);
    _recalcProgress();
    _loadCategories().then((_) {
      if (widget.selectedProfession != null) {
        setState(() {
          _jobCategory = widget.selectedProfession;
          final category = _categories.firstWhere(
            (cat) =>
                cat['name'].toString().toLowerCase() ==
                _jobCategory!.toLowerCase(),
            orElse: () => {},
          );
          if (category.isNotEmpty) {
            _jobCategoryId = category['id'];
          } else {
            _jobCategoryId = null;
          }
          _jobCategoryCtrl.text = _jobCategory ?? '';
        });
        _recalcProgress();
      }
      _loadWorkerTypeAndProfession();
      _loadExistingServiceProviderData();
    });
    _initMyLocation();
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _skillsDescCtrl.dispose();
    _amountCtrl.dispose();
    _jobCategoryCtrl.dispose();
    _workplaceCtrl.dispose();
    _debounce?.cancel();
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
    if (_jobCategoryCtrl.text.trim().isNotEmpty) done++;
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
      if (_pickedFiles.isEmpty) {
        _toast('Please upload at least 1 file (tap Upload File).');
        return;
      }
      setState(() => _step = 3);
      return;
    }

    // submit from preview
    _submitToBackend();
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

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('professions')
          .orderBy('name')
          .get();

      _categories = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      _toast('Failed to load categories: $e');
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadWorkerTypeAndProfession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        _workerType = data['workerType'] as String?;

        if (_workerType == 'Professional Worker') {
          // Fetch profession from documents
          final docSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('documents')
              .doc('Professional Workers')
              .get();

          if (docSnap.exists &&
              docSnap.data()!.containsKey('Academic Certificate')) {
            final acData =
                docSnap.data()!['Academic Certificate'] as Map<String, dynamic>;
            final profession = acData['profession'] as String?;
            if (profession != null) {
              // Find the category id
              final category = _categories.firstWhere(
                (cat) =>
                    cat['name'].toString().toLowerCase() ==
                    profession.toLowerCase(),
                orElse: () => {},
              );
              setState(() {
                _jobCategory = profession;
                if (category.isNotEmpty) {
                  _jobCategoryId = category['id'];
                } else {
                  _jobCategoryId = null; // Custom profession not in Firestore
                }
                _jobCategoryCtrl.text = _jobCategory ?? '';
              });
              _recalcProgress();
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors, user can select manually
    }
  }

  Future<void> _loadExistingServiceProviderData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('serviceProviders')
          .doc(user.uid)
          .get();

      if (docSnap.exists && docSnap.data() != null) {
        // User already has service provider details - go directly to dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => WorkersDashboardScreen()),
          );
        }
        return;
      }

      // No existing data - user needs to fill the form (normal flow continues)
    } catch (e) {
      // Ignore errors, user can fill form manually
      print('Error loading existing service provider data: $e');
    }
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
    final items = const ['Per Hour', 'Per Day', 'Per Job'];
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

  Future<void> _pickFiles() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpeg', 'jpg'],
      withData: false,
    );

    if (res == null) return;

    // 5MB limit
    final files = res.files.where((f) => (f.size) <= 5 * 1024 * 1024).toList();
    if (files.length != res.files.length) {
      _toast('Some files were skipped (max 5MB).');
    }

    setState(() {
      _pickedFiles.clear();
      _pickedFiles.addAll(files);
    });

    _toast('${_pickedFiles.length} file(s) selected');
  }

  Future<void> _initMyLocation() async {
    setState(() => _loadingLoc = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _toast('Turn on location services');
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        _toast('Location permission denied');
        return;
      }

      _myPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Move map to user location if map already created
      if (_mapCtrl != null && _myPos != null) {
        _mapCtrl!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_myPos!.latitude, _myPos!.longitude),
            14,
          ),
        );
      }
    } catch (e) {
      _toast('Location error: $e');
    } finally {
      if (mounted) setState(() => _loadingLoc = false);
    }
  }

  Future<void> _searchPlaces(String input) async {
    final q = input.trim();
    if (q.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _searching = true);

    try {
      final locBias = _myPos != null
          ? "${_myPos!.latitude},${_myPos!.longitude}"
          : null;

      final res = await _places.get(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json",
        queryParameters: {
          "input": q,
          "key": _googleKey,
          "language": "en",
          // bias results around user
          if (locBias != null) "location": locBias,
          if (locBias != null) "radius": 30000, // 30km bias
          // optional: restrict to Uganda
          "components": "country:ug",
        },
      );

      final preds = (res.data["predictions"] as List? ?? []);
      setState(() {
        _suggestions = preds.map((p) {
          return {"description": p["description"], "place_id": p["place_id"]};
        }).toList();
      });
    } catch (e) {
      _toast("Search failed: $e");
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _selectPlace(String placeId, String description) async {
    FocusScope.of(context).unfocus();
    setState(() => _suggestions = []);

    try {
      final res = await _places.get(
        "https://maps.googleapis.com/maps/api/place/details/json",
        queryParameters: {
          "place_id": placeId,
          "key": _googleKey,
          "fields": "geometry,name,formatted_address",
        },
      );

      final result = res.data["result"];
      final loc = result["geometry"]["location"];
      final lat = (loc["lat"] as num).toDouble();
      final lng = (loc["lng"] as num).toDouble();

      final latLng = LatLng(lat, lng);

      setState(() {
        _workplaceCtrl.text = result["formatted_address"] ?? description;
        _pickedLatLng = latLng;
        _pickedMarker = Marker(
          markerId: const MarkerId("picked"),
          position: latLng,
        );
        _pickedPlaceOnMap = true;
      });

      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      _recalcProgress();
    } catch (e) {
      _toast("Failed to select place: $e");
    }
  }

  Future<void> _submitToBackend() async {
    if (_saving) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _toast('Please sign in first.');
      return;
    }

    setState(() => _saving = true);

    try {
      // 1) Upload files
      final newUrls = await _uploadPickedFiles(user.uid);

      // 2) Combine existing and new portfolio URLs
      final allPortfolioUrls = [..._existingPortfolioUrls, ...newUrls];

      // 2) Save profile
      final doc = FirebaseFirestore.instance
          .collection('serviceProviders')
          .doc(user.uid);

      final searchableText = [
        _businessNameCtrl.text.trim(),
        _jobCategoryId ?? '',
        _jobCategory ?? '',
        _workplaceCtrl.text.trim(),
      ].join(' ').toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

      await doc.set({
        'uid': user.uid,
        'jobCategoryId': _jobCategoryId,
        'jobCategoryName': _jobCategory,
        'businessName': _businessNameCtrl.text.trim(),
        'skillsDescription': _skillsDescCtrl.text.trim(),
        'yearsExperience': _yearsExp,
        'pricingType': _pricingType,
        'amount':
            int.tryParse(_amountCtrl.text.trim().replaceAll(',', '')) ?? 0,
        'workplaceLocationText': _workplaceCtrl.text.trim(),
        'workplaceLatLng': _pickedLatLng == null
            ? null
            : GeoPoint(_pickedLatLng!.latitude, _pickedLatLng!.longitude),
        'experienceLevel': _experienceLevel,
        'pickedPlaceOnMap': _pickedPlaceOnMap,
        'portfolioFiles': allPortfolioUrls, // combined list of download urls
        'updatedAt': FieldValue.serverTimestamp(),
        'onboardingStep': 'skills_job_details_done',

        // 🔍 SEARCH ENGINE FIELDS
        'isActive': true,
        'searchableText': searchableText,
      }, SetOptions(merge: true));

      // Add notification for successful submission
      await FirebaseFirestore.instance.collection('workerNotifications').add({
        'workerId': user.uid,
        'title': 'Profile Submission Successful',
        'message':
            'Your skills and job details have been successfully submitted. Your profile is now active and visible to employers.',
        'type': 'profile_submission',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _toast('Your workplace has been successfully registered');
      // Navigate to WorkersDashboardScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WorkersDashboardScreen()),
      );
    } catch (e) {
      _toast('Submit failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<List<String>> _uploadPickedFiles(String uid) async {
    final storage = FirebaseStorage.instance;
    final out = <String>[];

    for (final f in _pickedFiles) {
      if (f.path == null) continue;
      final file = File(f.path!);

      final ext = (f.extension ?? 'file').toLowerCase();
      final name = const Uuid().v4();
      final ref = storage.ref('serviceProviders/$uid/portfolio/$name.$ext');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      out.add(url);
    }
    return out;
  }

  Future<void> _pickJobCategory() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPickerSheet(items: _categories),
    );

    if (selected != null) {
      setState(() {
        _jobCategoryId = selected['id']?.toString();
        _jobCategory = (selected['name'] ?? '').toString();
        _jobCategoryCtrl.text = _jobCategory ?? '';
      });
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.015,
                    ),
                    Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.015,
                    ),
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
                                fontWeight: isSel
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                            ),
                            trailing: isSel
                                ? Icon(
                                    Icons.check_circle,
                                    color: _brandOrange.withOpacity(0.95),
                                  )
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
                            _step == 0
                                ? 'Continue'
                                : _step == 1
                                ? 'Save'
                                : 'Continue',
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
          _pillTextFieldWithIcon(
            w: w,
            h: h,
            controller: _jobCategoryCtrl,
            hint: 'Enter or select Your Job Category',
            onIconTap: _loadingCategories ? () {} : () => _pickJobCategory(),
            onChanged: (v) => setState(() => _jobCategory = v),
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return 'Job category is required';
              return null;
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
              if ((v ?? '').trim().isEmpty) {
                return 'Please describe your skills';
              }
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
            inputFormatters: [
              NumberTextInputFormatter(),
            ], // Replace digitsOnly with custom formatter
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return 'Amount is required';
              if (int.tryParse(t.replaceAll(',', '')) == null) {
                return 'Enter a valid number'; // Parse without commas
              }
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
          if (_suggestions.isNotEmpty) ...[
            SizedBox(height: h * 0.01),
            _suggestionsBox(w, h),
          ],

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

          _liveMap(w, h),
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
        SizedBox(height: h * 0.02),
        _label('Upload Work Images', w),
        SizedBox(height: h * 0.012),
        _uploadBox(w: w, h: h, onTap: _pickFiles),
      ],
    );
  }

  // ----------------------- PREVIEW (UI  image) -----------------------
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
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.06,
              vertical: h * 0.02,
            ),
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
                          onPressed: _saving
                              ? null
                              : _next, // Disable when saving
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandOrange,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _saving
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                ) // White progress indicator
                              : Text(
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
    final fieldH = h * 0.070;
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
                  Icon(
                    Icons.arrow_drop_up,
                    color: Colors.black,
                    size: w * 0.06,
                  ),
                  Transform.translate(
                    offset: Offset(0, -w * 0.02),
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black,
                      size: w * 0.06,
                    ),
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
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _recalcProgress(),
          );
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

  Widget _pillTextFieldWithIcon({
    required double w,
    required double h,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onIconTap,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
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
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _recalcProgress(),
          );
          return res;
        },
        onChanged: (v) {
          onChanged?.call(v);
          _recalcProgress();
        },
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
          suffixIcon: IconButton(
            icon: Icon(Icons.arrow_drop_down, color: Colors.black, size: w * 0.06),
            onPressed: onIconTap,
          ),
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
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _recalcProgress(),
                );
                return res;
              },
              onChanged: (v) {
                _recalcProgress();
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  _searchPlaces(v);
                });
              },
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
      child: Theme(
        data: Theme.of(context).copyWith(
          popupMenuTheme: PopupMenuThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
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
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                  ),
                )
                .toList(),
            onChanged: (v) {
              onChanged(v);
              _recalcProgress();
            },
          ),
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
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _recalcProgress(),
          );
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

  Widget _liveMap(double w, double h, {bool taller = false}) {
    final mapH = taller ? h * 0.34 : h * 0.24;

    final initial = _myPos != null
        ? LatLng(_myPos!.latitude, _myPos!.longitude)
        : const LatLng(0.3476, 32.5825); // Kampala fallback

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
            if (_myPos != null) {
              c.animateCamera(CameraUpdate.newLatLngZoom(initial, 14));
            }
          },
          markers: {if (_pickedMarker != null) _pickedMarker!},
          onTap: (latLng) async {
            setState(() {
              _pickedLatLng = latLng;
              _pickedMarker = Marker(
                markerId: const MarkerId("picked"),
                position: latLng,
              );
              _pickedPlaceOnMap = true;
            });

            // Optional: reverse geocode (address) so field is filled too
            await _reverseGeocode(latLng);
            _recalcProgress();
          },
        ),
      ),
    );
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      final res = await _places.get(
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
        setState(() => _workplaceCtrl.text = addr);
      }
    } catch (e) {
      // don't block user if reverse geocode fails
    }
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
                  _toast(
                    _pickedPlaceOnMap
                        ? 'Picked on map (optional)'
                        : 'Unpicked map',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pickedPlaceOnMap
                      ? Colors.green
                      : _brandOrange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
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

  Widget _suggestionsBox(double w, double h) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.white,
        constraints: BoxConstraints(maxHeight: h * 0.28),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.black.withOpacity(0.08)),
          itemBuilder: (_, i) {
            final s = _suggestions[i];
            return ListTile(
              title: Text(
                s["description"] ?? "",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: w * 0.033,
                ),
              ),
              onTap: () async {
                final placeId = s["place_id"];
                final desc = s["description"] ?? "";
                await _selectPlace(placeId, desc);
              },
            );
          },
        ),
      ),
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
                Icon(
                  Icons.cloud_upload_rounded,
                  color: Colors.white,
                  size: w * 0.14,
                ),
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
                if (_pickedFiles.isNotEmpty ||
                    _existingPortfolioUrls.isNotEmpty) ...[
                  SizedBox(height: h * 0.012),
                  Text(
                    '${_existingPortfolioUrls.length + _pickedFiles.length} file(s) total (${_existingPortfolioUrls.length} existing, ${_pickedFiles.length} new)',
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

// ---------------- Category picker sheet ----------------

class _CategoryPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  const _CategoryPickerSheet({required this.items});

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((e) {
      final name = (e['name'] ?? '').toString().toLowerCase();
      return name.contains(q.toLowerCase());
    }).toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: Container(
        color: Colors.black.withOpacity(0.85),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search category...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => q = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.white.withOpacity(0.1)),
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final name = (item['name'] ?? '').toString();
                    return ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final intValue = int.tryParse(newValue.text.replaceAll(',', ''));
    if (intValue == null) return oldValue;

    final formatted = NumberFormat('#,###').format(intValue);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
