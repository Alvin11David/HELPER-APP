// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Workers_Reschedule_screen.dart';
import 'Active_Job_detail.dart';






class WorkerJobsHubScreen extends StatefulWidget {
  final String providerId;
  final int initialTab;

  const WorkerJobsHubScreen({super.key, required this.providerId, this.initialTab = 0});

  @override
  State<WorkerJobsHubScreen> createState() => _WorkerJobsHubScreenState();
}

class _WorkerJobsHubScreenState extends State<WorkerJobsHubScreen> {
  static const _brandOrange = Color(0xFFFFA10D);

  int _tab = 0; // 0 pending, 1 active, 2 completed, 3 cancelled

  // Conflict detection state
  int _conflictCount = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _conflictsSub;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _listenConflictsBadge();
  }

  @override
  void dispose() {
    _conflictsSub?.cancel();
    super.dispose();
  }

  void _listenConflictsBadge() {
    final workerId = widget.providerId;

    _conflictsSub = FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: workerId)
        .where(
          'status',
          whereIn: const ['pending', 'confirmed', 'reschedule_requested'],
        )
        .where('hasConflict', isEqualTo: true)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          setState(() => _conflictCount = snap.docs.length);
        });
  }

  void _setTab(int i) => setState(() => _tab = i);

  Color _tabChipColor(int i) {
    if (_tab == i) return _brandOrange;
    return Colors.white;
  }

  Color _tabChipTextColor(int i) {
    if (_tab == i) return Colors.black;
    return Colors.black.withOpacity(0.75);
  }

  String get _title {
    switch (_tab) {
      case 0:
        return "Pending Jobs";
      case 1:
        return "Active Jobs";
      case 2:
        return "Completed Jobs";
      case 3:
        return "Cancelled Jobs";
      default:
        return "Cancelled Jobs";
    }
  }

  String get _helperPillText {
    switch (_tab) {
      case 0:
        return "View all Pending Jobs here";
      case 1:
        return "View all active Jobs here";
      case 2:
        return "View all completed Jobs here";
      case 3:
        return "View all cancelled Jobs here";
      default:
        return "View all cancelled Jobs here";
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: Colors.black.withOpacity(0.85),
      ),
    );
  }

  // ---------------------- Booking helpers ----------------------

  void _openBookingDetails({
    required String bookingId,
    required Map<String, dynamic> bookingData,
    required int tab,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BookingDetailsSheet(
        bookingId: bookingId,
        bookingData: bookingData,
        tab: tab,
        accent: _brandOrange,
        onViewLocation: () {
          _toast("Open location screen (hook maps later)");
        },
        onAcceptPending: tab == 0
            ? () {
                Navigator.pop(context);
                _acceptBooking(bookingId, bookingData);
              }
            : null,
        onDeletePending: tab == 0
            ? () {
                Navigator.pop(context);
                _cancelBooking(bookingId);
              }
            : null,
        onStartJob: tab == 1
            ? () async {
                Navigator.pop(context);
                await _startJob(bookingId);
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActiveJobScreen()),
                );
              }
            : null,
        onReschedule: tab == 1
            ? () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkerJobRescheduleScreen(
                      bookingId: bookingId,
                      bookingData: bookingData,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }

  Future<void> _acceptBooking(String bookingId, Map<String, dynamic> d) async {
    final workerId = widget.providerId;

    final newStart = (d['startDateTime'] as Timestamp?)?.toDate();
    final newEnd = (d['endDateTime'] as Timestamp?)?.toDate();
    if (newStart == null || newEnd == null) {
      _toast("Missing booking time range");
      return;
    }

    try {
      final overlapSnap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceProviderId', isEqualTo: workerId)
          .where('status', isEqualTo: 'confirmed')
          .where('startDateTime', isLessThan: Timestamp.fromDate(newEnd))
          .where('endDateTime', isGreaterThan: Timestamp.fromDate(newStart))
          .get();

      final conflicts = overlapSnap.docs
          .where((doc) => doc.id != bookingId)
          .toList();
      final hasConflict = conflicts.isNotEmpty;

      final updateData = <String, dynamic>{
        'status': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
        'acceptedAt': FieldValue.serverTimestamp(),
        'workerAcceptedBy': workerId,
        'hasConflict': hasConflict,
      };

      if (hasConflict) {
        updateData['conflictDetectedAt'] = FieldValue.serverTimestamp();
      } else {
        updateData['conflictDetectedAt'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update(updateData);

      if (hasConflict) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in conflicts) {
          batch.update(doc.reference, {
            'hasConflict': true,
            'conflictDetectedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        _toast("Booking accepted (conflict detected)");
      } else {
        _toast("Booking accepted!");
      }

      setState(() => _tab = 1);
    } catch (e) {
      _toast("Error accepting booking: $e");
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final workerId = widget.providerId;
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
            'cancelledAt': FieldValue.serverTimestamp(),
            'cancelledBy': workerId,
          });
      _toast("Booking cancelled!");
      setState(() => _tab = 3);
    } catch (e) {
      _toast("Cancel error: $e");
    }
  }

  Future<void> _startJob(String bookingId) async {
    final workerId = widget.providerId;
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'status': 'in_progress',
            'updatedAt': FieldValue.serverTimestamp(),
            'startedAt': FieldValue.serverTimestamp(),
            'startedBy': workerId,
          });
      _toast("Job started!");
    } catch (e) {
      _toast("Start job error: $e");
    }
  }

  // ---------------------- Streams / UI ----------------------

  Widget _pendingJobsStream(double w, double h) {
    final workerId = widget.providerId;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceProviderId', isEqualTo: workerId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snap.hasError)
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty)
          return const Center(
            child: Text(
              'No pending jobs',
              style: TextStyle(color: Colors.white),
            ),
          );

        return ListView.separated(
          padding: EdgeInsets.only(bottom: h * 0.02),
          itemCount: docs.length,
          separatorBuilder: (_, __) => SizedBox(height: h * 0.012),
          itemBuilder: (_, i) {
            final d = docs[i].data();
            final bookingId = docs[i].id;

            final jobItem = _JobItem(
              employerName: d['employerName'] ?? 'Employer',
              jobDesc: d['jobDescription'] ?? '',
              payment: "${d['amount'] ?? '0'}",
              location: d['jobLocationText'] ?? 'Unknown',
              category: 'Booking',
              duration: d['pricingType'] ?? 'Fixed',
              timeRemaining: 'Pending',
              specialNotes: d['specialNotes'] ?? '',
              pricingType: d['pricingType'] ?? 'Fixed',
              paymentAmount: "${d['amount'] ?? '0'}",
            );

            return _JobCard(
              w: w,
              h: h,
              tab: _tab,
              job: jobItem,
              onTap: () => _openBookingDetails(
                bookingId: bookingId,
                bookingData: d,
                tab: 0,
              ),
              onAccept: () async => await _acceptBooking(bookingId, d),
              onDelete: () async => await _cancelBooking(bookingId),
              onResume: () => _toast('Resume (hook API later)'),
              onPause: () => _toast('Pause (hook API later)'),
            );
          },
        );
      },
    );
  }

  Widget _jobsByStatusStream(double w, double h, String status) {
    final workerId = widget.providerId;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceProviderId', isEqualTo: workerId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snap.hasError)
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty)
          return Center(
            child: Text(
              'No $status jobs',
              style: const TextStyle(color: Colors.white),
            ),
          );

        return ListView.separated(
          padding: EdgeInsets.only(bottom: h * 0.02),
          itemCount: docs.length,
          separatorBuilder: (_, __) => SizedBox(height: h * 0.012),
          itemBuilder: (_, i) {
            final d = docs[i].data();
            final bookingId = docs[i].id;

            final jobItem = _JobItem(
              employerName: d['employerName'] ?? 'Employer',
              jobDesc: d['jobDescription'] ?? '',
              payment: "${d['amount'] ?? '0'}",
              location: d['jobLocationText'] ?? 'Unknown',
              category: 'Booking',
              duration: d['pricingType'] ?? 'Fixed',
              timeRemaining: status,
              specialNotes: d['specialNotes'] ?? '',
              pricingType: d['pricingType'] ?? 'Fixed',
              paymentAmount: "${d['amount'] ?? '0'}",
            );

            return _JobCard(
              w: w,
              h: h,
              tab: _tab,
              job: jobItem,
              onTap: () => _openBookingDetails(
                bookingId: bookingId,
                bookingData: d,
                tab: _tab,
              ),
              onResume: () => _toast('Resume not implemented yet'),
              onPause: () => _toast('Pause not implemented yet'),
              onAccept: () async {},
              onDelete: () async => await _cancelBooking(bookingId),
            );
          },
        );
      },
    );
  }

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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePad),
            child: Column(
              children: [
                SizedBox(height: h * 0.02),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
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
                        _title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.055,
                          fontFamily: 'AbrilFatface',
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.02),
                    _TopAvatar(w: w),
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
                      _helperPillText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: w * 0.03,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: h * 0.018),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Job List',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.04,
                    ),
                  ),
                ),
                SizedBox(height: h * 0.012),
                Row(children: [
                  _TabChip(text: 'Pending', active: _tab == 0, bg: _tabChipColor(0), fg: _tabChipTextColor(0), badgeCount: _conflictCount, onTap: () => _setTab(0)),
                  SizedBox(width: w * 0.02),
                  _TabChip(text: 'Active', active: _tab == 1, bg: _tabChipColor(1), fg: _tabChipTextColor(1), onTap: () => _setTab(1)),
                  SizedBox(width: w * 0.02),
                  _TabChip(text: 'Completed', active: _tab == 2, bg: _tabChipColor(2), fg: _tabChipTextColor(2), onTap: () => _setTab(2)),
                  SizedBox(width: w * 0.02),
                  _TabChip(text: 'Cancelled', active: _tab == 3, bg: _tabChipColor(3), fg: _tabChipTextColor(3), onTap: () => _setTab(3)),
                ]),
                SizedBox(height: h * 0.014),
                Expanded(child: () {
                  if (_tab == 0) return _pendingJobsStream(w, h);
                  if (_tab == 1) return _jobsByStatusStream(w, h, 'confirmed');
                  if (_tab == 2) return _jobsByStatusStream(w, h, 'completed');
                  return _jobsByStatusStream(w, h, 'cancelled');
                }()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------ Models ------------------------------

class _JobItem {
  final String employerName;
  final String jobDesc;
  final String payment;
  final String specialNotes;
  final String location;
  final String category;
  final String duration;
  final String timeRemaining;
  final String pricingType;
  final String paymentAmount;

  _JobItem({
    required this.employerName,
    required this.jobDesc,
    required this.payment,
    required this.specialNotes,
    required this.location,
    required this.category,
    required this.duration,
    required this.timeRemaining,
    required this.pricingType,
    required this.paymentAmount,
  });
}

// ------------------------------ Booking Details Sheet ------------------------------

class _BookingDetailsSheet extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;
  final int tab; // 0 pending, 1 active, 2 completed, 3 cancelled
  final Color accent;

  final VoidCallback onViewLocation;

  // Pending actions
  final VoidCallback? onAcceptPending;
  final VoidCallback? onDeletePending;

  // Active actions
  final VoidCallback? onStartJob;
  final VoidCallback? onReschedule;

  const _BookingDetailsSheet({
    required this.bookingId,
    required this.bookingData,
    required this.tab,
    required this.accent,
    required this.onViewLocation,
    this.onAcceptPending,
    this.onDeletePending,
    this.onStartJob,
    this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    String employerName = (bookingData['employerName'] ?? 'Employer')
        .toString();
    String notes = (bookingData['specialNotes'] ?? '').toString();
    String desc = (bookingData['jobDescription'] ?? '').toString();
    String locationText = (bookingData['jobLocationText'] ?? 'Unknown')
        .toString();
    String pricingType = (bookingData['pricingType'] ?? 'Fixed').toString();
    String amount = "${bookingData['amount'] ?? 0}";

    DateTime? start = (bookingData['startDateTime'] as Timestamp?)?.toDate();
    DateTime? end = (bookingData['endDateTime'] as Timestamp?)?.toDate();

    String durationText;
    if (start != null && end != null) {
      durationText = "${start.toString()} → ${end.toString()}";
    } else {
      durationText = "Not set";
    }

    final title = tab == 0
        ? "Pending Job Details"
        : tab == 1
        ? "Active Job Details"
        : tab == 2
        ? "Completed Job Details"
        : "Cancelled Job Details";

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.02, w * 0.06, h * 0.03),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              SizedBox(height: h * 0.014),
              Text(
                title,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'AbrilFatface',
                  fontSize: w * 0.052,
                ),
              ),
              SizedBox(height: h * 0.012),

              _detailRow(w, "Employer Name:", employerName),
              _detailRow(
                w,
                "Employer Special Notes:",
                notes.isEmpty ? "-" : notes,
              ),
              _detailRow(w, "Job Description:", desc.isEmpty ? "-" : desc),
              _detailRow(w, "Job Location:", locationText, valueColor: accent),
              _detailRow(w, "Job Duration:", durationText),
              SizedBox(height: h * 0.01),
              Divider(color: Colors.black.withOpacity(0.15)),
              _detailRow(w, "Pricing Type:", pricingType),
              _detailRow(w, "Payment Amount:", amount),

              SizedBox(height: h * 0.018),

              if (tab == 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewLocation,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: accent.withOpacity(0.9),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: EdgeInsets.symmetric(vertical: h * 0.016),
                        ),
                        child: Text(
                          'View Location',
                          style: TextStyle(
                            color: accent,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.035,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAcceptPending,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: EdgeInsets.symmetric(vertical: h * 0.016),
                        ),
                        child: Text(
                          'Accept',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.035,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: h * 0.012),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onDeletePending,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.red.withOpacity(0.9),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: EdgeInsets.symmetric(vertical: h * 0.016),
                    ),
                    child: Text(
                      'Delete (Cancel Request)',
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: w * 0.035,
                      ),
                    ),
                  ),
                ),
              ] else if (tab == 1) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewLocation,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: accent.withOpacity(0.9),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: EdgeInsets.symmetric(vertical: h * 0.016),
                        ),
                        child: Text(
                          'View Location',
                          style: TextStyle(
                            color: accent,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.032,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.02),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onStartJob,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: EdgeInsets.symmetric(vertical: h * 0.016),
                        ),
                        child: Text(
                          'Start Job',
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
                SizedBox(height: h * 0.012),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onReschedule,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: accent.withOpacity(0.9),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: EdgeInsets.symmetric(vertical: h * 0.016),
                    ),
                    child: Text(
                      'Reschedule',
                      style: TextStyle(
                        color: accent,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: w * 0.035,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(double w, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: w * 0.032,
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? Colors.black.withOpacity(0.75),
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.032,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------ Widgets ------------------------------

class _JobCard extends StatelessWidget {
  final double w;
  final double h;
  final int tab;
  final _JobItem job;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onDelete;
  final VoidCallback onResume;
  final VoidCallback onPause;

  const _JobCard({
    required this.w,
    required this.h,
    required this.tab,
    required this.job,
    required this.onTap,
    required this.onAccept,
    required this.onDelete,
    required this.onResume,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: h * 0.014,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.036,
                    ),
                  ),
                  SizedBox(height: h * 0.002),
                  Text(
                    job.jobDesc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.65),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: w * 0.03,
                    ),
                  ),
                  SizedBox(height: h * 0.002),
                  Text(
                    job.payment,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.75),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.03,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.03),
            if (tab == 0) ...[
              Column(
                children: [
                  _TinyPillButton(
                    w: w,
                    bg: const Color(0xFF3AD11B),
                    text: 'Accept',
                    icon: Icons.check_rounded,
                    onTap: onAccept,
                  ),
                  SizedBox(height: h * 0.008),
                  _TinyPillButton(
                    w: w,
                    bg: const Color(0xFFE93B2F),
                    text: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    onTap: onDelete,
                  ),
                ],
              ),
            ] else if (tab == 1) ...[
              Column(
                children: [
                  _TinyPillButton(
                    w: w,
                    bg: const Color(0xFF3AD11B),
                    text: 'Resume',
                    icon: Icons.play_arrow_rounded,
                    onTap: onResume,
                  ),
                  SizedBox(height: h * 0.008),
                  _TinyPillButton(
                    w: w,
                    bg: const Color(0xFFE93B2F),
                    text: 'Pause',
                    icon: Icons.pause_rounded,
                    onTap: onPause,
                  ),
                ],
              ),
            ] else ...[
              Padding(
                padding: EdgeInsets.only(top: h * 0.012),
                child: Icon(
                  Icons.more_vert,
                  color: Colors.black,
                  size: w * 0.06,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TinyPillButton extends StatelessWidget {
  final double w;
  final Color bg;
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _TinyPillButton({
    required this.w,
    required this.bg,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.035,
          vertical: w * 0.012,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: w * 0.04),
            SizedBox(width: w * 0.012),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.028,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String text;
  final bool active;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  final int badgeCount;

  const _TabChip({
    required this.text,
    required this.active,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopAvatar extends StatelessWidget {
  final double w;
  const _TopAvatar({required this.w});

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications, color: Colors.black),
            ),
          ],
        ),
      ],
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

class _RescheduleCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _RescheduleCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Reschedule screen (implement separately)')));
  }
}

// Reschedule screen is in `Workers_Reschedule_screen.dart` - imported above.
