// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class ActiveJobScreen extends StatefulWidget {
  final String? bookingId;
  final Map<String, dynamic>? bookingData;

  const ActiveJobScreen({super.key, this.bookingId, this.bookingData});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  static const _brandOrange = Color(0xFFFFA10D);
  static const String _googleApiKey = 'AIzaSyBUJXjLSEFn_8OfVkaaLAIHYGUcGJEDD9w';

  int _phase = 0; // 0 = summary, 1 = time & payment

  // Timer for countdown
  Timer? _countdownTimer;

  // Map-related fields
  GoogleMapController? _mapController;
  LatLng? _userPosition;
  LatLng? _employerPosition;
  Set<Marker> _mapMarkers = {};
  final Set<Polyline> _polylines = {};
  final bool _loadingLocation = false;
  StreamSubscription<Position>? _positionStream;

  // ---- Data (populated from bookingData when available) ----
  late Map<String, dynamic> bookingData;
  String status = "Available";
  String jobId = "ID Number";
  String jobCountdown = "00:00:00";
  String elapsedTime = "00:00:00";
  String totalTime = "00:00:00";

  String employerName = "Name";
  String jobCategory = "Category";
  String jobLocation = "Location";
  String jobDescription = "Description";

  String type = "Hour/Fixed";
  String amount = "Amount";

  bool _hasActiveJob = false;

  /// Get current user position
  Future<LatLng?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them.'),
          ),
        );
      }
      return null;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please enable them in settings.',
            ),
          ),
        );
      }
      return null;
    }

    try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _userPosition = currentPos;
        _updateMapMarkers();
      });

      return currentPos;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Update map markers based on user position and employer position
  void _updateMapMarkers() {
    _mapMarkers.clear();

    // User location marker
    if (_userPosition != null) {
      _mapMarkers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: _userPosition!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }

    // Employer location marker
    if (_employerPosition != null) {
      _mapMarkers.add(
        Marker(
          markerId: const MarkerId('employer'),
          position: _employerPosition!,
          infoWindow: const InfoWindow(title: 'Job Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    setState(() {
      _mapMarkers = _mapMarkers;
    });
  }

  /// Decode polyline from Google Maps API response
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  /// Show directions between user and employer
  Future<void> _showDirections() async {
    if (_userPosition == null || _employerPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location data not available'),
        ),
      );
      return;
    }

    try {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${_userPosition!.latitude},${_userPosition!.longitude}&destination=${_employerPosition!.latitude},${_employerPosition!.longitude}&key=$_googleApiKey';

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final polylinePoints = _decodePolyline(
          route['overview_polyline']['points'],
        );

        // Calculate bounds
        double minLat = double.infinity;
        double maxLat = -double.infinity;
        double minLng = double.infinity;
        double maxLng = -double.infinity;
        for (var point in polylinePoints) {
          if (point.latitude < minLat) minLat = point.latitude;
          if (point.latitude > maxLat) maxLat = point.latitude;
          if (point.longitude < minLng) minLng = point.longitude;
          if (point.longitude > maxLng) maxLng = point.longitude;
        }

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylinePoints,
              color: Colors.orange,
              width: 5,
            ),
          );
        });

        // Animate camera to fit the route
        if (_mapController != null) {
          final bounds = LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          );
          _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        }

        // Start location tracking
        _positionStream?.cancel();
        _positionStream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // Update every 5 meters
          ),
        ).listen((Position position) {
          final current = LatLng(position.latitude, position.longitude);
          setState(() {
            _userPosition = current;
            _updateMapMarkers();
          });

          if (_mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newLatLng(current));
          }

          // Check distance to destination
          if (_employerPosition != null) {
            final distance = Geolocator.distanceBetween(
              current.latitude,
              current.longitude,
              _employerPosition!.latitude,
              _employerPosition!.longitude,
            );
            if (distance < 50) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You have reached the destination!'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to fetch directions')),
          );
        }
      }
    } catch (e) {
      print('Error fetching directions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _back() {
    if (_phase == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _phase = 0);
    }
  }

  void _goPhase(int v) {
    if (_phase == v) return;
    setState(() => _phase = v);
  }

  /// Format Duration to HH:MM:SS
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Calculate and update job timer
  void _updateJobTimer() {
    if (bookingData.isEmpty) return;

    final startDt = bookingData['startDateTime'];
    final endDt = bookingData['endDateTime'];
    final startedAtDt = bookingData['startedAt'];

    if (startDt == null || endDt == null) return;

    // Convert Timestamps to DateTime
    final startDateTime = (startDt is Timestamp) ? startDt.toDate() : (startDt as DateTime?);
    final endDateTime = (endDt is Timestamp) ? endDt.toDate() : (endDt as DateTime?);
    final startedAt = (startedAtDt is Timestamp) ? startedAtDt.toDate() : (startedAtDt as DateTime?);

    if (startDateTime == null || endDateTime == null) return;

    final now = DateTime.now();

    // Total duration: endDateTime - startDateTime
    final totalDuration = endDateTime.difference(startDateTime);
    final totalTimeStr = _formatDuration(totalDuration);

    // Elapsed time: now - startedAt (or startDateTime if startedAt is null or hasn't started yet)
    final elapsedStart = startedAt ?? startDateTime;
    final elapsedDuration = now.difference(elapsedStart);
    final elapsedTimeStr = _formatDuration(elapsedDuration);

    // Countdown: endDateTime - startDateTime (same as total time, counts down as elapsed time increases)
    // This aligns with total time so they always match
    final remainingDuration = totalDuration.inSeconds > elapsedDuration.inSeconds
        ? totalDuration - elapsedDuration
        : Duration.zero;
    final remainingStr = _formatDuration(remainingDuration);

    setState(() {
      totalTime = totalTimeStr;
      elapsedTime = elapsedTimeStr;
      jobCountdown = remainingStr;
    });
  }

  /// Check if job scheduled start time has been reached
  bool _isScheduleTimeReached() {
    if (bookingData.isEmpty) return false;
    
    final startDt = bookingData['startDateTime'];
    if (startDt == null) return true;
    
    final startDateTime = (startDt is Timestamp) ? startDt.toDate() : (startDt as DateTime?);
    if (startDateTime == null) return true;
    
    return DateTime.now().isAfter(startDateTime);
  }

  /// Get formatted scheduled start time for warning message
  String _getScheduledStartTime() {
    if (bookingData.isEmpty) return 'Unknown';
    
    final startDt = bookingData['startDateTime'];
    if (startDt == null) return 'Unknown';
    
    final startDateTime = (startDt is Timestamp) ? startDt.toDate() : (startDt as DateTime?);
    if (startDateTime == null) return 'Unknown';
    
    return DateFormat('MMM d, yyyy at h:mm a').format(startDateTime);
  }

  /// Start periodic timer to update countdown
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _updateJobTimer(); // Initial update
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateJobTimer();
    });
  }

  Future<void> _handleJobCompleted() async {
    try {
      _countdownTimer?.cancel();
      setState(() {
        status = 'Completed (Awaiting Employer)';
      });

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Calculate elapsed seconds since startedAt (or startDateTime if startedAt is null)
      final startDt = bookingData['startedAt'] ?? bookingData['startDateTime'];
      DateTime? startDateTime;
      if (startDt is Timestamp) {
        startDateTime = startDt.toDate();
      } else if (startDt is DateTime) {
        startDateTime = startDt;
      }

      final now = DateTime.now();
      final elapsedSeconds = (startDateTime != null && now.isAfter(startDateTime))
          ? now.difference(startDateTime).inSeconds
          : 0;

      // Update worker totals and set status to Available
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'jobsCompleted': FieldValue.increment(1),
        'hoursWorkedSeconds': FieldValue.increment(elapsedSeconds),
        'status': 'Available',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update booking status to completed pending employer confirmation
      if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
        final employerId = (bookingData['employerId'] ?? '').toString();
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .update({
              'status': 'completed_pending',
              'completion.status': 'pending',
              'completion.requestedById': uid,
              'completion.requestedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (employerId.isNotEmpty) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'type': 'job_completed_request',
            'toUserId': employerId,
            'fromUserId': uid,
            'bookingId': widget.bookingId,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
            'title': 'Job completion request',
            'message': 'Worker marked the job as completed. Please confirm.',
          });
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completion sent to employer for confirmation'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete job: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _bookingSub;

  @override
  void initState() {
    super.initState();
    bookingData = widget.bookingData ?? <String, dynamic>{};

    final statusValue = (bookingData['status'] ?? '').toString();
    final startReached = _isScheduleTimeReached();

    if (!startReached) {
      bookingData = <String, dynamic>{};
    }

    if ((statusValue == 'in_progress' || statusValue == 'started') && startReached) {
      _hasActiveJob = true;
      status = 'On Job';
    } else if (statusValue == 'completed_pending') {
      status = 'Completed (Awaiting Employer)';
    } else if (statusValue == 'completed') {
      status = 'Completed';
    } else {
      status = 'Available';
    }
    
    // Extract employer location from booking
    if (_hasActiveJob && widget.bookingId != null && widget.bookingId!.isNotEmpty) {
      final docRef = FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);
      _bookingSub = docRef.snapshots().listen((snap) {
        if (snap.exists) {
          final data = snap.data();
          if (data != null) {
            setState(() {
              bookingData.addAll(data);
              // Update type from pricingType
              type = data['pricingType'] ?? 'Unknown';
              final liveStatus = (data['status'] ?? '').toString();
              if (liveStatus == 'in_progress' || liveStatus == 'started') {
                status = 'On Job';
              } else if (liveStatus == 'completed_pending') {
                status = 'Completed (Awaiting Employer)';
              } else if (liveStatus == 'completed') {
                status = 'Completed';
              } else {
                status = 'Available';
              }
              
              // Extract employer location
              final jobLatLng = data['jobLatLng'] as GeoPoint?;
              if (jobLatLng != null) {
                _employerPosition = LatLng(jobLatLng.latitude, jobLatLng.longitude);
              }
            });
            // Start/restart the countdown timer when booking data updates
            final statusValue = (data['status'] ?? '').toString();
            if (statusValue == 'completed_pending' || statusValue == 'completed') {
              _countdownTimer?.cancel();
            } else {
              _startCountdownTimer();
            }
            // Update markers
            _updateMapMarkers();
          }
        }
      });
    } else if (widget.bookingData != null && widget.bookingData!.isNotEmpty) {
      if (_hasActiveJob) {
        type = bookingData['pricingType'] ?? 'Unknown';
      }
      
      // Extract employer location from initial booking data
      if (_hasActiveJob) {
        final jobLatLng = bookingData['jobLatLng'] as GeoPoint?;
        if (jobLatLng != null) {
          _employerPosition = LatLng(jobLatLng.latitude, jobLatLng.longitude);
        }
      }
      
      final statusValue = (bookingData['status'] ?? '').toString();
      if (statusValue != 'completed_pending' && statusValue != 'completed') {
        if (_hasActiveJob) {
          _startCountdownTimer();
        }
      }
    }
    
    // Get user's current location
    if (_hasActiveJob) {
      _getCurrentLocation();
    }
  }


  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bookingSub?.cancel();
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    // Populate display fields from bookingData if provided
    final b = bookingData;
    if (_hasActiveJob && b.isNotEmpty) {
      employerName = (b['employerName'] ?? employerName).toString();
      jobLocation = (b['jobLocationText'] ?? jobLocation).toString();
      jobDescription = (b['jobDescription'] ?? jobDescription).toString();
      amount = (b['amount'] != null) ? b['amount'].toString() : amount;
      type = (b['pricingType'] ?? type).toString();
    }
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final sidePad = w * 0.06;
    final topPad = h * 0.03;

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
              // Body
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) {
                  final slide =
                      Tween<Offset>(
                        begin: Offset(_phase == 0 ? -0.04 : 0.04, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeOut),
                      );
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: _phase == 0
                    ? _phaseSummary(w, h, sidePad, topPad)
                    : _phasePayment(w, h, sidePad, topPad),
              ),

              // Top bar
              Positioned(
                top: h * 0.02,
                left: sidePad,
                right: sidePad,
                child: Row(
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
                        'Active Job',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontSize: w * 0.055,
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
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- PHASE 0 ----------------

  Widget _phaseSummary(double w, double h, double sidePad, double topPad) {
    return SingleChildScrollView(
      key: const ValueKey('phase0'),
      padding: EdgeInsets.fromLTRB(sidePad, h * 0.16, sidePad, h * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_hasActiveJob)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: h * 0.018,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No active job currently',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w * 0.04,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: h * 0.006),
                  Text(
                    'Job details will appear here when the job day starts.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: w * 0.032,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),

          if (!_hasActiveJob) SizedBox(height: h * 0.018),

          _sectionTitle('Job Status', w),
          SizedBox(height: h * 0.012),
          _WhiteCard(
            child: Column(
              children: [
                _InfoRow(
                  label: 'Status:',
                  value: status,
                  valueColor: Colors.green,
                ),
                _InfoRow(label: 'Job ID:', value: jobId),
                _InfoRow(label: 'Job Countdown:', value: jobCountdown),
              ],
            ),
          ),

          SizedBox(height: h * 0.018),

          // Show warning if job hasn't started yet
          if (_hasActiveJob && !_isScheduleTimeReached())
            Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.015),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                border: Border.all(color: Colors.orange, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⏰ Scheduled Job',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: h * 0.008),
                  Text(
                    'This job is scheduled to start on ${_getScheduledStartTime()}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: w * 0.032,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: h * 0.008),
                  Text(
                    'Please wait for the scheduled start time before beginning the job.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: w * 0.03,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),

          if (_hasActiveJob && !_isScheduleTimeReached()) SizedBox(height: h * 0.018),

          _sectionTitle('Employer & Job Summary', w),
          SizedBox(height: h * 0.012),
          _WhiteCard(
            child: Column(
              children: [
                _InfoRow(label: 'Employer Name:', value: employerName),
                _InfoRow(label: 'Job Category:', value: jobCategory),
                _InfoRow(label: 'Job Location:', value: jobLocation),
                _InfoRow(label: 'Job Description:', value: jobDescription),
                SizedBox(height: h * 0.012),
                Row(
                  children: [
                    Expanded(
                      child: _OrangeMiniButton(
                        text: 'Call Now',
                        icon: Icons.call,
                        onTap: () {
                          // TODO: show incoming/outgoing call UI
                        },
                      ),
                    ),
                    SizedBox(width: w * 0.04),
                    Expanded(
                      child: _OrangeMiniButton(
                        text: 'Message',
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: () {
                          // TODO: open chat
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: h * 0.018),

          _sectionTitle('Location & Navigation', w),
          SizedBox(height: h * 0.012),

          _MapCard(
            w: w,
            h: h,
            userPosition: _userPosition,
            employerPosition: _employerPosition,
            mapMarkers: _mapMarkers,
            mapPolylines: _polylines,
            onMapCreated: _onMapCreated,
            onNavigate: _showDirections,
          ),

          SizedBox(height: h * 0.018),

          _sectionTitle('Time & Payment Tracking', w),
          SizedBox(height: h * 0.012),
          _WhiteCard(
            child: Column(
              children: [
                _InfoRow(label: 'Type:', value: type),
                _InfoRow(label: 'Total Time:', value: totalTime),
                _InfoRow(label: 'Elapsed Time:', value: elapsedTime),
                _InfoRow(label: 'Amount:', value: amount),
              ],
            ),
          ),

          SizedBox(height: h * 0.02),

          SizedBox(height: h * 0.015),

          Center(
            child: _GlassPill(
              radius: 20,
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.05,
                vertical: h * 0.007,
              ),
              child: Text(
                'Payment is held in Escrow',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: w * 0.03,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),

          SizedBox(height: h * 0.06),

          // Job Completed button (green)
          SizedBox(
            width: double.infinity,
            height: h * 0.078,
            child: ElevatedButton(
              onPressed: () {
                _handleJobCompleted();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E539),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              child: Text(
                'Job Completed',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),

          SizedBox(height: h * 0.015),

          // Terminate job (big red)
          SizedBox(
            width: double.infinity,
            height: h * 0.078,
            child: ElevatedButton(
              onPressed: () {
                // TODO: confirm dialog -> terminate
                _showTerminateDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE80B0B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              child: Text(
                'Terminate Job',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PHASE 1 ----------------

  Widget _phasePayment(double w, double h, double sidePad, double topPad) {
    return SingleChildScrollView(
      key: const ValueKey('phase1'),
      padding: EdgeInsets.fromLTRB(sidePad, h * 0.16, sidePad, h * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Time & Payment Tracking', w),
          SizedBox(height: h * 0.012),
          _WhiteCard(
            child: Column(
              children: [
                _InfoRow(label: 'Type:', value: type),
                _InfoRow(label: 'Total Time:', value: totalTime),
                _InfoRow(label: 'Elapsed Time:', value: elapsedTime),
                _InfoRow(label: 'Amount:', value: amount),
              ],
            ),
          ),

          SizedBox(height: h * 0.015),

          Center(
            child: _GlassPill(
              radius: 20,
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.05,
                vertical: h * 0.007,
              ),
              child: Text(
                'Payment is held in Escrow',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: w * 0.03,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),

          SizedBox(height: h * 0.06),

          // Job Completed button (green)
          SizedBox(
            width: double.infinity,
            height: h * 0.078,
            child: ElevatedButton(
              onPressed: () {
                _handleJobCompleted();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E539),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              child: Text(
                'Job Completed',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),

          SizedBox(height: h * 0.015),

          // Terminate job (big red)
          SizedBox(
            width: double.infinity,
            height: h * 0.078,
            child: ElevatedButton(
              onPressed: () {
                // TODO: confirm dialog -> terminate
                _showTerminateDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE80B0B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              child: Text(
                'Terminate Job',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTerminateDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final w = MediaQuery.of(ctx).size.width;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Terminate Job?',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: w * 0.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This will end the active job. You can hook the real termination API later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: w * 0.032,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.35),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Terminated (hook API later)',
                                    style: TextStyle(fontFamily: 'Inter'),
                                  ),
                                  backgroundColor: Colors.black.withOpacity(
                                    0.85,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandOrange,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Terminate',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w900,
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
          ),
        );
      },
    );
  }

  Text _sectionTitle(String t, double w) {
    return Text(
      t,
      style: TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w900,
        fontSize: w * 0.038,
      ),
    );
  }
}

// --------------------------- UI Parts ---------------------------

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _BulletIcon(size: w * 0.055),
          const SizedBox(width: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w900,
              fontSize: w * 0.033,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? Colors.black.withOpacity(0.85),
              fontFamily: 'Inter',
              fontWeight: FontWeight.normal,
              fontSize: w * 0.032,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletIcon extends StatelessWidget {
  final double size;
  const _BulletIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Center(
        child: Icon(
          Icons.info_outline_rounded,
          size: size * 0.82,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _OrangeMiniButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _OrangeMiniButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: w * 0.11,
        decoration: BoxDecoration(
          color: const Color(0xFFFFA10D),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: w * 0.05),
            SizedBox(width: w * 0.02),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.034,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final double w;
  final double h;
  final LatLng? userPosition;
  final LatLng? employerPosition;
  final Set<Marker> mapMarkers;
  final Set<Polyline> mapPolylines;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback onNavigate;

  const _MapCard({
    required this.w,
    required this.h,
    this.userPosition,
    this.employerPosition,
    required this.mapMarkers,
    required this.mapPolylines,
    required this.onMapCreated,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final mapH = h * 0.22;

    // Default center to San Francisco if no positions available
    final defaultCenter = LatLng(37.7749, -122.4194);
    final initialCenter = userPosition ?? employerPosition ?? defaultCenter;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: mapH,
        width: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialCenter,
                zoom: 14.0,
              ),
              markers: mapMarkers,
              polylines: mapPolylines,
              onMapCreated: onMapCreated,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),

            // Zoom controls
            Positioned(
              right: w * 0.03,
              top: mapH * 0.30,
              child: Column(
                children: [
                  _ZoomBtn(icon: Icons.add, w: w),
                  SizedBox(height: h * 0.01),
                  _ZoomBtn(icon: Icons.remove, w: w),
                ],
              ),
            ),

            // Navigate button
            Positioned(
              left: 0,
              right: 0,
              bottom: mapH * 0.12,
              child: Center(
                child: GestureDetector(
                  onTap: onNavigate,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.12,
                      vertical: w * 0.028,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA10D),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                          size: w * 0.05,
                        ),
                        SizedBox(width: w * 0.02),
                        Text(
                          'Navigate',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.034,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final double w;

  const _ZoomBtn({required this.icon, required this.w});

  @override
  Widget build(BuildContext context) {
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
}

class _PhaseDots extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;
  final Color accent;

  const _PhaseDots({
    required this.activeIndex,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    Widget dot(int i) {
      final active = i == activeIndex;
      return GestureDetector(
        onTap: () => onTap(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 18 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: active ? accent : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [dot(0), dot(1)]);
  }
}

class _TopAvatar extends StatelessWidget {
  final double w;
  const _TopAvatar({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w * 0.10,
      height: w * 0.10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white.withOpacity(0.35)),
        image: const DecorationImage(
          image: AssetImage('assets/images/person.png'), // change if needed
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  final double w;
  final IconData icon;
  final VoidCallback onTap;

  const _TopIcon({required this.w, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
