import 'dart:async';
import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helper/Escrow/Cancellation_Code_Screen.dart';
import 'package:helper/Escrow/Finished_Job_Code_Screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  static const _brandOrange = Color(0xFFFFA10D);

  int _tab = 0; // 0 pending, 1 active, 2 completed, 3 cancelled

  @override
  void initState() {
    super.initState();
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
        return "My Bookings";
      case 1:
        return "Active Bookings";
      case 2:
        return "Completed Bookings";
      default:
        return "Cancelled Bookings";
    }
  }

  String get _helperPillText {
    switch (_tab) {
      case 0:
        return "View all Pending Bookings here";
      case 1:
        return "View all active Bookings here";
      case 2:
        return "View all completed Bookings here";
      default:
        return "View all cancelled Bookings here";
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
        onCancelPending: tab == 0
            ? () {
                Navigator.pop(context);
                _cancelBooking(bookingId);
              }
            : null,
        onTerminateActive: tab == 1
            ? () {
                Navigator.pop(context);
                _confirmTerminate(bookingId);
              }
            : null,
        onVerifyCancellation: (tab == 1 || tab == 3)
            ? () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CancellationCodeScreen(bookingId: bookingId),
                  ),
                );
              }
            : null,
        onVerifyCompletion: tab == 2
            ? () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FinishedJobCodeScreen(bookingId: bookingId),
                  ),
                );
              }
            : null,
      ),
    );
  }

  Future<void> _confirmTerminate(String bookingId) async {
    final shouldTerminate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate job?'),
        content: const Text(
          'This will terminate the active job and cancel the booking with escrow. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, terminate'),
          ),
        ],
      ),
    );

    if (shouldTerminate == true) {
      await _requestCancellation(bookingId);
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    await _requestCancellation(bookingId);
  }

  Future<void> _requestCancellation(String bookingId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'cancelBookingWithEscrow',
      );
      await callable.call({'bookingId': bookingId});
      if (!mounted) return;
      _toast(
        'Cancellation started. The worker was sent a 6-digit code to confirm.',
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      _toast('Cancellation Successful: ${e.message ?? e.code}');
    } catch (e) {
      if (!mounted) return;
      _toast('Cancellation Successful: $e');
    }
  }

  Widget _pendingBookingsStream(double w, double h) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          'Please log in to view bookings',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('employerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        // Filter by status client-side and sort by createdAt descending
        final filteredDocs =
            snap.data?.docs
                .where((doc) => doc.data()['status'] == 'pending')
                .toList() ??
            [];
        filteredDocs.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text(
              'No pending bookings',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.only(bottom: h * 0.02),
          itemCount: filteredDocs.length,
          separatorBuilder: (_, __) => SizedBox(height: h * 0.012),
          itemBuilder: (_, i) {
            final d = filteredDocs[i].data();
            final bookingId = filteredDocs[i].id;

            final jobItem = _BookingItem(
              serviceProviderId: d['serviceProviderId'] ?? '',
              jobDesc: d['jobDescription'] ?? '',
              payment: "${d['amount'] ?? '0'}",
              location: d['jobLocationText'] ?? 'Unknown',
              pricingType: d['pricingType'] ?? 'Fixed',
              status: d['status'] ?? 'pending',
              startDateTime: (d['startDateTime'] as Timestamp?)?.toDate(),
              endDateTime: (d['endDateTime'] as Timestamp?)?.toDate(),
              createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
            );

            return _BookingCard(
              w: w,
              h: h,
              tab: _tab,
              booking: jobItem,
              onTap: () => _openBookingDetails(
                bookingId: bookingId,
                bookingData: d,
                tab: 0,
              ),
              onCancel: () async => await _cancelBooking(bookingId),
            );
          },
        );
      },
    );
  }

  Widget _bookingsByStatusStream(double w, double h, String status) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          'Please log in to view bookings',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('employerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        // Filter by status client-side and sort by createdAt descending
        final filteredDocs =
            snap.data?.docs
                .where((doc) => doc.data()['status'] == status)
                .toList() ??
            [];
        filteredDocs.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text(
              'No $status bookings',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.only(bottom: h * 0.02),
          itemCount: filteredDocs.length,
          separatorBuilder: (_, __) => SizedBox(height: h * 0.012),
          itemBuilder: (_, i) {
            final d = filteredDocs[i].data();
            final bookingId = filteredDocs[i].id;

            final jobItem = _BookingItem(
              serviceProviderId: d['serviceProviderId'] ?? '',
              jobDesc: d['jobDescription'] ?? '',
              payment: "${d['amount'] ?? '0'}",
              location: d['jobLocationText'] ?? 'Unknown',
              pricingType: d['pricingType'] ?? 'Fixed',
              status: d['status'] ?? status,
              startDateTime: (d['startDateTime'] as Timestamp?)?.toDate(),
              endDateTime: (d['endDateTime'] as Timestamp?)?.toDate(),
              createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
            );

            return _BookingCard(
              w: w,
              h: h,
              tab: _tab,
              booking: jobItem,
              onTap: () => _openBookingDetails(
                bookingId: bookingId,
                bookingData: d,
                tab: _tab,
              ),
              onCancel: () async {},
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
                    'Booking List',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.04,
                    ),
                  ),
                ),
                SizedBox(height: h * 0.012),
                Row(
                  children: [
                    _TabChip(
                      text: 'Pending',
                      active: _tab == 0,
                      bg: _tabChipColor(0),
                      fg: _tabChipTextColor(0),
                      onTap: () => _setTab(0),
                    ),
                    SizedBox(width: w * 0.02),
                    _TabChip(
                      text: 'Active',
                      active: _tab == 1,
                      bg: _tabChipColor(1),
                      fg: _tabChipTextColor(1),
                      onTap: () => _setTab(1),
                    ),
                    SizedBox(width: w * 0.02),
                    _TabChip(
                      text: 'Completed',
                      active: _tab == 2,
                      bg: _tabChipColor(2),
                      fg: _tabChipTextColor(2),
                      onTap: () => _setTab(2),
                    ),
                    SizedBox(width: w * 0.02),
                    _TabChip(
                      text: 'Cancelled',
                      active: _tab == 3,
                      bg: _tabChipColor(3),
                      fg: _tabChipTextColor(3),
                      onTap: () => _setTab(3),
                    ),
                  ],
                ),
                SizedBox(height: h * 0.014),
                Expanded(
                  child: () {
                    if (_tab == 0) return _pendingBookingsStream(w, h);
                    if (_tab == 1) {
                      return _bookingsByStatusStream(w, h, 'confirmed');
                    }
                    if (_tab == 2) {
                      return _bookingsByStatusStream(w, h, 'completed');
                    }
                    return _bookingsByStatusStream(w, h, 'cancelled');
                  }(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------ Models ------------------------------

class _BookingItem {
  final String serviceProviderId;
  final String jobDesc;
  final String payment;
  final String location;
  final String pricingType;
  final String status;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final DateTime? createdAt;

  _BookingItem({
    required this.serviceProviderId,
    required this.jobDesc,
    required this.payment,
    required this.location,
    required this.pricingType,
    required this.status,
    this.startDateTime,
    this.endDateTime,
    this.createdAt,
  });
}

// ------------------------------ Booking Details Sheet ------------------------------

class _BookingDetailsSheet extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;
  final int tab; // 0 pending, 1 active, 2 completed, 3 cancelled
  final Color accent;

  final VoidCallback onViewLocation;
  final VoidCallback? onCancelPending;
  final VoidCallback? onTerminateActive;
  final VoidCallback? onVerifyCancellation;
  final VoidCallback? onVerifyCompletion;

  const _BookingDetailsSheet({
    required this.bookingId,
    required this.bookingData,
    required this.tab,
    required this.accent,
    required this.onViewLocation,
    this.onCancelPending,
    this.onTerminateActive,
    this.onVerifyCancellation,
    this.onVerifyCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final startDateTime = (bookingData['startDateTime'] as Timestamp?)
        ?.toDate();
    final endDateTime = (bookingData['endDateTime'] as Timestamp?)?.toDate();
    final createdAt = (bookingData['createdAt'] as Timestamp?)?.toDate();

    return Container(
      height: h * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.06,
              vertical: h * 0.02,
            ),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Booking Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'AbrilFatface',
                    fontSize: w * 0.05,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.white, size: w * 0.06),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(w * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Provider ID
                  _DetailRow(
                    label: 'Service Provider',
                    value: bookingData['serviceProviderId'] ?? 'N/A',
                  ),
                  SizedBox(height: h * 0.02),

                  // Job Description
                  _DetailRow(
                    label: 'Job Description',
                    value: bookingData['jobDescription'] ?? 'N/A',
                  ),
                  SizedBox(height: h * 0.02),

                  // Location
                  _DetailRow(
                    label: 'Location',
                    value: bookingData['jobLocationText'] ?? 'N/A',
                  ),
                  SizedBox(height: h * 0.02),

                  // Pricing
                  _DetailRow(
                    label: 'Pricing Type',
                    value: bookingData['pricingType'] ?? 'N/A',
                  ),
                  SizedBox(height: h * 0.01),
                  _DetailRow(
                    label: 'Amount',
                    value: 'UGX ${bookingData['amount'] ?? '0'}',
                  ),
                  SizedBox(height: h * 0.02),

                  // Schedule
                  if (startDateTime != null) ...[
                    _DetailRow(
                      label: 'Start Date & Time',
                      value:
                          '${startDateTime.day}/${startDateTime.month}/${startDateTime.year} ${startDateTime.hour}:${startDateTime.minute.toString().padLeft(2, '0')}',
                    ),
                    SizedBox(height: h * 0.01),
                  ],
                  if (endDateTime != null) ...[
                    _DetailRow(
                      label: 'End Date & Time',
                      value:
                          '${endDateTime.day}/${endDateTime.month}/${endDateTime.year} ${endDateTime.hour}:${endDateTime.minute.toString().padLeft(2, '0')}',
                    ),
                    SizedBox(height: h * 0.02),
                  ],

                  // Status
                  _DetailRow(
                    label: 'Status',
                    value: (bookingData['status'] ?? 'pending').toUpperCase(),
                  ),
                  SizedBox(height: h * 0.02),

                  // Created At
                  if (createdAt != null) ...[
                    _DetailRow(
                      label: 'Created At',
                      value:
                          '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                    ),
                    SizedBox(height: h * 0.02),
                  ],

                  // Actions
                  if (tab == 0 && onCancelPending != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onCancelPending,
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
                          'Cancel Booking',
                          style: TextStyle(
                            color: Colors.red,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.035,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (tab == 1 && onTerminateActive != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onTerminateActive,
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
                          'Terminate Job',
                          style: TextStyle(
                            color: Colors.red,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.035,
                          ),
                        ),
                      ),
                    ),
                    if ((tab == 1 || tab == 3) &&
                        onVerifyCancellation != null) ...[
                      SizedBox(height: h * 0.012),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onVerifyCancellation,
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
                            'Enter Cancellation Code',
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
                    if (tab == 2 && onVerifyCompletion != null) ...[
                      SizedBox(height: h * 0.012),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: onVerifyCompletion,
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
                            'Enter Completion Code',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.6),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: w * 0.032,
          ),
        ),
        SizedBox(height: w * 0.01),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            fontSize: w * 0.035,
          ),
        ),
      ],
    );
  }
}

// ------------------------------ Booking Card ------------------------------

class _BookingCard extends StatelessWidget {
  final double w;
  final double h;
  final int tab;
  final _BookingItem booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _BookingCard({
    required this.w,
    required this.h,
    required this.tab,
    required this.booking,
    required this.onTap,
    required this.onCancel,
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
                    'Service Provider: ${booking.serviceProviderId.substring(0, min(8, booking.serviceProviderId.length))}...',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.036,
                    ),
                  ),
                  SizedBox(height: h * 0.002),
                  Text(
                    booking.jobDesc,
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
                    'UGX ${booking.payment} (${booking.pricingType})',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.75),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.03,
                    ),
                  ),
                  SizedBox(height: h * 0.002),
                  Text(
                    booking.location,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.6),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: w * 0.028,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.03),
            if (tab == 0 && onCancel != null) ...[
              _TinyPillButton(
                w: w,
                bg: const Color(0xFFE93B2F),
                text: 'Cancel',
                icon: Icons.cancel_outlined,
                onTap: onCancel!,
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

  const _TabChip({
    required this.text,
    required this.active,
    required this.bg,
    required this.fg,
    required this.onTap,
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
            borderRadius: BorderRadius.circular(17),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: fg,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final double radius;
  final EdgeInsets padding;
  final Widget child;

  const _GlassPill({
    required this.radius,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: child,
    );
  }
}
