import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:helper/Document%20Upload/Booking_Penalties_Screen.dart';
import 'package:helper/Document%20Upload/Document_Upload_screen.dart';
import 'package:helper/Document%20Upload/National_ID_Passport_Front_Upload_Screen.dart';
import 'package:helper/Document%20Upload/Professional_License_Upload.dart';
import 'package:helper/Document%20Upload/Selfie_Verification_Upload.dart';
import 'package:intl/intl.dart';
import 'package:helper/Components/User_Name.dart';
import '../Components/Side_Bar.dart';
import 'package:helper/Components/user_avatar_circle.dart';
import 'package:helper/Components/Bottom_Nav_Bar.dart';
import 'Worker_Jobs_Hub_Screen.dart';
import 'WorkerSearchBar.dart';
import 'Active_Job_detail.dart';
import 'Worker_Details_Screen.dart';
import 'package:helper/Chats/Chat_Screen.dart';
import 'Workers_skills_and_Job_Details.dart';
import 'Worker_Notifications.dart';
import 'Workers_Earning_Detail_Screen.dart';
import 'package:helper/Wallet/Wallet_Cancelled_screen.dart';

class WorkersDashboardScreen extends StatefulWidget {
  const WorkersDashboardScreen({super.key});

  @override
  State<WorkersDashboardScreen> createState() => _WorkersDashboardScreenState();
}

class _WorkersDashboardScreenState extends State<WorkersDashboardScreen> {
  Future<void> _fetchJobSuggestions(String input) async {
    final workerUid = FirebaseAuth.instance.currentUser?.uid;
    if (workerUid == null || input.trim().isEmpty) {
      setState(() {
        _jobSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('workerUid', isEqualTo: workerUid)
        .get();
    final jobs = <String>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final jobName = (data['jobCategoryName'] ?? '').toString();
      if (jobName.toLowerCase().contains(input.trim().toLowerCase()) &&
          jobName.isNotEmpty) {
        jobs.add(jobName);
      }
    }
    setState(() {
      _jobSuggestions = jobs.toList();
      _showSuggestions = _jobSuggestions.isNotEmpty && _focusNode.hasFocus;
    });
  }

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<SideBarState> _sidebarKey = GlobalKey();
  late final UserAvatarCircle _avatarWidget;

  List<String> _jobSuggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  String workerStatus =
      'Available'; // Can be 'Available', 'On Job', 'Not Available'
  bool _isCallDialogShowing = false;
  Map<String, dynamic>? activeJobData; // Store active job details for display
  String? _activeServiceProviderId;
  String? _selectedBookingId;
  Map<String, dynamic>? _selectedBookingData;

  // Next job countdown
  Timer? _nextJobTimer;
  String _nextJobCountdown = '00:00:00';
  bool _nextJobStarted = false;

  @override
  void initState() {
    super.initState();
    _avatarWidget = UserAvatarCircle();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
    Future<void> fetchJobSuggestions(String input) async {
      final workerUid = FirebaseAuth.instance.currentUser?.uid;
      if (workerUid == null || input.trim().isEmpty) {
        setState(() {
          _jobSuggestions = [];
          _showSuggestions = false;
        });
        return;
      }
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('workerUid', isEqualTo: workerUid)
          .get();
      final jobs = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final jobName = (data['jobCategoryName'] ?? '').toString();
        if (jobName.toLowerCase().contains(input.trim().toLowerCase()) &&
            jobName.isNotEmpty) {
          jobs.add(jobName);
        }
      }
      setState(() {
        _jobSuggestions = jobs.toList();
        _showSuggestions = _jobSuggestions.isNotEmpty && _focusNode.hasFocus;
      });
    }

    print('=== WORKER DASHBOARD INIT STATE ===');

    // Request notification permissions
    FirebaseMessaging.instance.requestPermission().then((settings) {
      print('FCM permission status: ${settings.authorizationStatus}');
    });

    // Set online status
    final uid = FirebaseAuth.instance.currentUser?.uid;
    print('Current user UID: $uid');
    print('Current user: ${FirebaseAuth.instance.currentUser}');
    print('🔥 WORKER DASHBOARD: Current user object printed above!');

    if (uid != null) {
      print('Setting user online and saving FCM token...');

      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      // Save FCM token
      FirebaseMessaging.instance
          .getToken()
          .then((token) {
            print('FCM token obtained: ${token != null ? "YES" : "NO"}');
            print('FCM token value: ${token?.substring(0, 50)}...');
            if (token != null) {
              FirebaseFirestore.instance.collection('users').doc(uid).update({
                'fcmToken': token,
              });
              print('FCM token saved to Firestore successfully');

              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ FCM token saved'),
                    duration: Duration(seconds: 2),
                  ),
                );
              });
            } else {
              print('FCM token is null, cannot save to Firestore');

              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ FCM token is null'),
                    duration: Duration(seconds: 3),
                  ),
                );
              });
            }
          })
          .catchError((error) {
            print('Error getting FCM token: $error');

            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ FCM token error: $error'),
                  duration: const Duration(seconds: 3),
                ),
              );
            });
          });
    }

    print('Setting up FCM listeners...');

    // Start next job countdown timer
    _startNextJobCountdownTimer();

    // Set up FCM listener for incoming calls
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('=== FCM onMessage RECEIVED ===');
      print('Message data: ${message.data}');
      print(
        'Message notification: ${message.notification?.title} - ${message.notification?.body}',
      );

      if (message.data['type'] == 'call') {
        print(
          'Call notification detected! Call ID: ${message.data['callId']}, Caller: ${message.data['callerName']}',
        );
        print('Attempting to show IncomingCallDialog...');

        try {
          if (!_isCallDialogShowing) {
            _isCallDialogShowing = true;
          }
          print('IncomingCallDialog showDialog called successfully');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ IncomingCallDialog shown'),
              duration: Duration(seconds: 3),
            ),
          );
        } catch (e) {
          print('ERROR showing IncomingCallDialog: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Dialog error: $e'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else if (message.data['type'] == 'review') {
        print(
          'Review notification received! Review ID: ${message.data['reviewId']}, Reviewer: ${message.data['reviewerName']}, Rating: ${message.data['rating']}',
        );
        // Let review notifications show as system notifications instead of snackbars
        // The notification will appear in the phone's notification tray like WhatsApp
      } else {
        print(
          'Received FCM message but type is not handled. Type: ${message.data['type']}',
        );
        // Only show snackbar for truly unknown message types
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❓ Unknown message type: ${message.data['type']}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('=== FCM onMessageOpenedApp RECEIVED ===');
      print('Message data: ${message.data}');

      if (message.data['type'] == 'call') {
        print('App opened from call notification');
        try {
          if (!_isCallDialogShowing) {
            _isCallDialogShowing = true;
            showDialog(
              context: context,
              builder: (context) => IncomingCallDialog(
                callId: message.data['callId']!,
                callerName: message.data['callerName']!,
              ),
            ).then((_) => _isCallDialogShowing = false);
          }
          print('IncomingCallDialog shown from opened app');
        } catch (e) {
          print('ERROR showing IncomingCallDialog from opened app: $e');
        }
      }
    });

    // Handle initial message if app was launched from notification
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      print('=== FCM getInitialMessage CHECKED ===');
      if (message != null) {
        print('Initial message found: ${message.data}');
        if (message.data['type'] == 'call') {
          print('App launched from call notification');
          try {
            if (!_isCallDialogShowing) {
              _isCallDialogShowing = true;
              showDialog(
                context: context,
                builder: (context) => IncomingCallDialog(
                  callId: message.data['callId']!,
                  callerName: message.data['callerName']!,
                ),
              ).then((_) => _isCallDialogShowing = false);
            }
            print('IncomingCallDialog shown from initial message');
          } catch (e) {
            print('ERROR showing IncomingCallDialog from initial message: $e');
          }
        }
      } else {
        print('No initial message found');
      }
    });

    // BACKUP: Set up Firestore listener for incoming calls (in case FCM fails)
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      print('Setting up Firestore listener for incoming calls...');

      FirebaseFirestore.instance
          .collection('calls')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'ringing')
          .snapshots()
          .listen((snapshot) {
            print('=== FIRESTORE CALL LISTENER TRIGGERED ===');
            print('Found ${snapshot.docs.length} ringing calls');

            for (var doc in snapshot.docs) {
              final callData = doc.data();
              final callId = doc.id;
              final callerName = callData['callerName'] ?? 'Unknown Caller';

              print('Incoming call detected: $callId from $callerName');

              // Show dialog if not already showing
              if (!_isCallDialogShowing) {
                _isCallDialogShowing = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => IncomingCallDialog(
                      callId: callId,
                      callerName: callerName,
                    ),
                  ).then((_) => _isCallDialogShowing = false);
                });
              }
            }
          });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 Firestore call listener active'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      });
    }

    print('=== WORKER DASHBOARD INIT STATE COMPLETE ===');
  }

  @override
  void dispose() {
    _nextJobTimer?.cancel();
    // Set offline status
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
    super.dispose();
  }

  void _startNextJobCountdownTimer() {
    _nextJobTimer?.cancel();
    _nextJobTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateNextJobCountdown();
    });
  }

  void _updateNextJobCountdown() async {
    final workerUid = FirebaseAuth.instance.currentUser?.uid;
    if (workerUid == null) return;

    try {
      // If there is an active job, do not count down
      final activeSnap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('workerUid', isEqualTo: workerUid)
          .where('status', whereIn: const ['in_progress', 'started'])
          .limit(1)
          .get();
      if (activeSnap.docs.isNotEmpty) {
        _setNextJobCountdown('00:00:00', false);
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('workerUid', isEqualTo: workerUid)
          .where(
            'status',
            whereIn: const ['confirmed', 'in_progress', 'started'],
          )
          .orderBy('startDateTime')
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _setNextJobCountdown('00:00:00', false);
        return;
      }

      final nextJob = snap.docs.first.data();
      final startDt = nextJob['startDateTime'];

      if (startDt == null) return;

      final startDateTime = (startDt is Timestamp)
          ? startDt.toDate()
          : (startDt as DateTime?);
      if (startDateTime == null) return;

      final now = DateTime.now();

      if (now.isAfter(startDateTime)) {
        // Job has started
        _setNextJobCountdown('00:00:00', true);
      } else {
        // Still counting down
        final remaining = startDateTime.difference(now);
        final hours = remaining.inHours;
        final minutes = (remaining.inMinutes % 60);
        final seconds = (remaining.inSeconds % 60);
        final formattedTime =
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        _setNextJobCountdown(formattedTime, false);
      }
    } catch (e) {
      print('Error updating next job countdown: $e');
    }
  }

  void _setNextJobCountdown(String value, bool started) {
    if (_nextJobCountdown == value && _nextJobStarted == started) return;
    if (!mounted) return;
    setState(() {
      _nextJobCountdown = value;
      _nextJobStarted = started;
    });
  }

  bool _isSelectableBookingStatus(String s) {
    final v = s.toLowerCase();
    return v == 'confirmed' || v == 'started' || v == 'in_progress';
  }

  int _bookingPriority(Map<String, dynamic> d) {
    // lower = higher priority
    final s = (d['status'] ?? '').toString().toLowerCase();
    if (s == 'started' || s == 'in_progress') return 0; // active first
    if (s == 'confirmed') return 1; // upcoming next
    return 9;
  }

  void _ensureSelectedBooking(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) {
      _selectedBookingId = null;
      _selectedBookingData = null;
      return;
    }

    // if nothing selected yet OR selected not found anymore => pick first
    final stillExists =
        _selectedBookingId != null &&
        docs.any((d) => d.id == _selectedBookingId);

    if (!stillExists) {
      _selectedBookingId = docs.first.id;
      _selectedBookingData = docs.first.data();
      return;
    }

    // keep selection data fresh
    final selected = docs.firstWhere((d) => d.id == _selectedBookingId);
    _selectedBookingData = selected.data();
  }

  Widget _buildActiveJobCard(Map<String, dynamic> data, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Employer Name:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  data['employerName'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Color(0xFFFFA10D),
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Text(
                'Job Type:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  data['pricingType'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Color(0xFFFFA10D),
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Text(
                'Job Location:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  data['jobLocationText'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Color(0xFFFFA10D),
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Text(
                'Time Remaining:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _computeRemainingTime(data),
                style: const TextStyle(
                  color: Color(0xFFFFA10D),
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: () {
                final businessName = (data['employerName'] ?? 'Employer')
                    .toString();
                final providerId =
                    (data['serviceProviderId'] ??
                            data['workerUid'] ??
                            FirebaseAuth.instance.currentUser?.uid ??
                            '')
                        .toString();
                final employerId = (data['employerId'] ?? '').toString();
                if (providerId.isEmpty || employerId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to open chat.')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatPartnerName: businessName,
                      providerId: providerId,
                      employerId: employerId,
                    ),
                  ),
                );
              },
              child: Container(
                width: screenWidth * 0.4,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA10D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Message',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiActiveJobCard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    double screenWidth,
  ) {
    // Ensure selection + selection data
    _ensureSelectedBooking(docs);

    if (_selectedBookingData == null) {
      return const Center(
        child: Text(
          'No active job currently',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final selectedId = _selectedBookingId!;
    final selectedData = _selectedBookingData!;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- selector chips ---
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final d = doc.data();
                final isSelected = doc.id == selectedId;

                final employer = (d['employerName'] ?? 'Employer').toString();
                final status = (d['status'] ?? '').toString();

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedBookingId = doc.id;
                      _selectedBookingData = d;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFA10D)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFA10D)
                            : Colors.black12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          employer.length > 14
                              ? employer.substring(0, 14)
                              : employer,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // --- your existing short detail card UI ---
          _buildActiveJobCard(selectedData, screenWidth),
        ],
      ),
    );
  }

  String? _getActiveProviderId() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return _activeServiceProviderId ?? uid;
  }

  Widget _serviceProviderCards(double w) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('serviceProviders')
          .where('workerUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No service provider cards yet',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final hasActive =
            _activeServiceProviderId != null &&
            docs.any((d) => d.id == _activeServiceProviderId);
        if (!hasActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _activeServiceProviderId = docs.first.id);
            }
          });
        }

        return SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: docs.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == docs.length) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkerSkillsJobDetailsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.black, size: 28),
                    ),
                  ),
                );
              }

              final doc = docs[index];
              final data = doc.data();
              final isSelected = doc.id == _activeServiceProviderId;
              final title = (data['jobCategoryName'] ?? 'Job').toString();
              final sub = (data['businessName'] ?? '').toString();

              return GestureDetector(
                onTap: () {
                  if (_activeServiceProviderId == doc.id) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerDetailsScreen(
                          providerId: doc.id,
                          data: data,
                          workerId: uid,
                          isWorkerView: true,
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() => _activeServiceProviderId = doc.id);
                },
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF79F1A)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkerDetailsScreen(
                                    providerId: doc.id,
                                    data: data,
                                    workerId: uid,
                                    isWorkerView: true,
                                  ),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.more_vert,
                                color: Colors.black87,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (sub.isNotEmpty)
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _acceptPendingBooking(String bookingId) async {
    final workerId = FirebaseAuth.instance.currentUser?.uid;
    if (workerId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'status': 'confirmed',
            'updatedAt': FieldValue.serverTimestamp(),
            'acceptedAt': FieldValue.serverTimestamp(),
            'workerAcceptedBy': workerId,
            'workerUid': workerId,
          });

      await FirebaseFirestore.instance.collection('workerNotifications').add({
        'workerId': workerId,
        'title': 'Booking accepted',
        'message': 'You accepted a booking request.',
        'type': 'booking_accepted',
        'bookingId': bookingId,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job accepted'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept job: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _declinePendingBooking(String bookingId) async {
    final workerId = FirebaseAuth.instance.currentUser?.uid;
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (workerId != null) {
        await FirebaseFirestore.instance.collection('workerNotifications').add({
          'workerId': workerId,
          'title': 'Booking declined',
          'message': 'You declined a booking request.',
          'type': 'booking_declined',
          'bookingId': bookingId,
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job declined'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to decline job: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Color getStatusColor() {
    if (workerStatus == 'Available') return const Color(0xFF00E539);
    if (workerStatus == 'On Job') return const Color(0xFFE80B0B);
    return Colors.red; // Not Available
  }

  String _mapBookingStatusToDisplay(String? bookingStatus) {
    switch (bookingStatus) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
      case 'started':
        return 'On Job';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Available';
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _computeRemainingTime(Map<String, dynamic> data) {
    final startDt = data['startDateTime'];
    final endDt = data['endDateTime'];
    final startedAtDt = data['startedAt'];

    if (startDt == null || endDt == null) return '00:00:00';

    final startDateTime = (startDt is Timestamp)
        ? startDt.toDate()
        : (startDt as DateTime?);
    final endDateTime = (endDt is Timestamp)
        ? endDt.toDate()
        : (endDt as DateTime?);
    final startedAt = (startedAtDt is Timestamp)
        ? startedAtDt.toDate()
        : (startedAtDt as DateTime?);

    if (startDateTime == null || endDateTime == null) return '00:00:00';

    final totalDuration = endDateTime.difference(startDateTime);
    final elapsedStart = startedAt ?? startDateTime;
    final elapsedDuration = DateTime.now().difference(elapsedStart);

    final remainingDuration =
        totalDuration.inSeconds > elapsedDuration.inSeconds
        ? Duration(seconds: totalDuration.inSeconds - elapsedDuration.inSeconds)
        : Duration.zero;

    return _formatDuration(remainingDuration);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  Future<void> _showNotifications() async {
    print('=== _showNotifications called ===');

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('=== No current user ===');
      return;
    }
    print('=== Current user: ${currentUser.uid} ===');

    // For worker dashboard, receiver is worker
    bool isEmployer = false;

    List<String> notifications = [];

    try {
      // Try to fetch unread messages - use a simpler approach
      List<String> notifications = [];

      try {
        // Fetch unread messages - simplified query to avoid index requirements
        final messageSnapshot = await FirebaseFirestore.instance
            .collectionGroup('messages')
            .where('receiverId', isEqualTo: currentUser.uid)
            .get();

        print('=== Message snapshot: ${messageSnapshot.docs.length} docs ===');

        // Filter unread messages in memory
        final unreadMessages = messageSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['read'] == false;
        });

        for (var doc in unreadMessages) {
          final data = doc.data();
          final senderId = data['senderId'] as String?;
          if (senderId == null) continue;

          String name = '';
          if (!isEmployer) {
            // Sender is employer, from serviceProviders
            try {
              final senderDoc = await FirebaseFirestore.instance
                  .collection('serviceProviders')
                  .doc(senderId)
                  .get();
              if (senderDoc.exists) {
                final senderData = senderDoc.data();
                name = senderData?['businessName'] ?? '';
              }
            } catch (e) {
              print('=== Error fetching sender: $e ===');
            }
          }
          if (name.isNotEmpty) {
            notifications.add('Message from $name');
          }
        }
      } catch (e) {
        print('=== Error fetching messages: $e ===');
        // Continue with worker notifications even if messages fail
      }

      // Fetch worker notifications - simplified query
      try {
        final workerNotifSnapshot = await FirebaseFirestore.instance
            .collection('workerNotifications')
            .where('workerId', isEqualTo: currentUser.uid)
            .get();

        print(
          '=== Worker notifications: ${workerNotifSnapshot.docs.length} docs ===',
        );

        // Filter unread notifications in memory
        final unreadWorkerNotifications = workerNotifSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['read'] == false;
        });

        for (var doc in unreadWorkerNotifications) {
          final data = doc.data();
          final title = data['title'] as String?;
          final message = data['message'] as String?;
          if (title != null && message != null) {
            notifications.add('$title: $message');
          }
        }

        // Mark worker notifications as read
        for (var doc in unreadWorkerNotifications) {
          try {
            await doc.reference.update({'read': true});
          } catch (e) {
            print('=== Error marking notification as read: $e ===');
          }
        }
      } catch (e) {
        print('=== Error fetching worker notifications: $e ===');
        // Continue even if worker notifications fail
      }

      print('=== Total notifications: ${notifications.length} ===');

      if (!mounted) {
        print('=== Widget not mounted ===');
        return;
      }

      if (notifications.isEmpty) {
        print('=== No notifications to show ===');
        return;
      }

      // Show each notification as a SnackBar with delay
      for (int i = 0; i < notifications.length; i++) {
        print('=== Showing notification ${i + 1}: ${notifications[i]} ===');

        // Wait before showing next notification (if there are multiple)
        if (i < notifications.length - 1) {
          await Future.delayed(const Duration(seconds: 7));
        }
      }
    } catch (e) {
      print('=== Error in _showNotifications: $e ===');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load notifications. Please check your connection and try again.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final workerUid = FirebaseAuth.instance.currentUser?.uid;
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:$minute $amPm';
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background/normalscreenbg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  // Fixed header
                  SizedBox(
                    height: 70,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 20,
                          left: w * 0.04,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _sidebarKey.currentState?.toggleDrawer(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.menu,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  UserName(),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 20,
                          right: w * 0.04,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const UserAvatarCircle(
                                size: 40,
                                backgroundColor: Colors.white,
                                iconColor: Colors.black,
                                borderWidth: 0,
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const WorkerNotifications(),
                                    ),
                                  );
                                },
                                child: Container(
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Search bar and suggestions (extracted)
                          WorkerSearchBar(),
                          SizedBox(height: 20),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'Your Service Cards',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _serviceProviderCards(w),
                          SizedBox(height: 20),
                          // Status
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 8,
                              left: 16,
                              right: 16,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Status: ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    height: 1.25,
                                  ),
                                ),
                                const Spacer(),
                                if (workerUid == null)
                                  const Text(
                                    'Not Available',
                                    style: TextStyle(
                                      color: Color(0xFFE80B0B),
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      height: 1.25,
                                    ),
                                  )
                                else
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('bookings')
                                        .where(
                                          'workerUid',
                                          isEqualTo: workerUid,
                                        )
                                        .where(
                                          'status',
                                          whereIn: ['in_progress', 'started'],
                                        )
                                        .limit(1)
                                        .snapshots(),
                                    builder: (ctx, snap) {
                                      if (snap.hasData &&
                                          snap.data!.docs.isNotEmpty) {
                                        return const Text(
                                          'On Job',
                                          style: TextStyle(
                                            color: Color(0xFFE80B0B),
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            height: 1.25,
                                          ),
                                        );
                                      }
                                      return const Text(
                                        'Available',
                                        style: TextStyle(
                                          color: Color(0xFF00E539),
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          height: 1.25,
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          // Pending Jobs
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pending Jobs',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: w * 0.045,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (workerUid == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Not signed in'),
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WorkerJobsHubScreen(
                                          providerId: workerUid,
                                          initialTab: 0,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    child: Text(
                                      'View All',
                                      style: TextStyle(
                                        color: Color(0xFFF79F1A),
                                        fontSize: w * 0.04,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                            child: Container(
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child:
                                  StreamBuilder<
                                    QuerySnapshot<Map<String, dynamic>>
                                  >(
                                    stream: () {
                                      if (workerUid == null) return null;
                                      return FirebaseFirestore.instance
                                          .collection('bookings')
                                          .where(
                                            'workerUid',
                                            isEqualTo: workerUid,
                                          )
                                          .where('status', isEqualTo: 'pending')
                                          .orderBy(
                                            'createdAt',
                                            descending: true,
                                          )
                                          .limit(1)
                                          .snapshots();
                                    }(),
                                    builder: (context, snap) {
                                      if (snap.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      }

                                      final docs = snap.data?.docs ?? [];
                                      if (docs.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'You have no new job requests',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      }

                                      final doc = docs.first;
                                      final d = doc.data();
                                      final bookingId = doc.id;
                                      final employerName =
                                          (d['employerName'] ?? 'Employer')
                                              .toString();
                                      final jobCategory =
                                          (d['jobCategoryName'] ?? 'Job')
                                              .toString();
                                      final jobLocation =
                                          (d['jobLocationText'] ?? 'Unknown')
                                              .toString();

                                      return Stack(
                                        children: [
                                          Positioned(
                                            top: 10,
                                            left: 10,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: _avatarWidget,
                                                ),
                                                const SizedBox(width: 10),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      employerName,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      jobCategory,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      jobLocation,
                                                      style: const TextStyle(
                                                        color: Colors.black54,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: Text(
                                              time,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: screenWidth * 0.2,
                                            right: screenWidth * 0.09,
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _declinePendingBooking(
                                                          bookingId,
                                                        ),
                                                    child: Container(
                                                      width: screenWidth * 0.35,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                      child: const Center(
                                                        child: Text(
                                                          'Decline',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _acceptPendingBooking(
                                                          bookingId,
                                                        ),
                                                    child: Container(
                                                      width: screenWidth * 0.35,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                      child: const Center(
                                                        child: Text(
                                                          'Accept',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                            ),
                          ),
                          SizedBox(height: 20),
                          // Next Job Countdown Card
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _nextJobStarted
                                          ? '🚀 Job has began!'
                                          : 'Time to Next Job',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _nextJobCountdown,
                                      style: TextStyle(
                                        color: _nextJobStarted
                                            ? Colors.green
                                            : Colors.black,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          // Active Job
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Active Job',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: w * 0.045,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    final id = _selectedBookingId;
                                    final data = _selectedBookingData;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ActiveJobScreen(
                                          bookingId: id,
                                          bookingData: data,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    child: Text(
                                      'View Job',
                                      style: TextStyle(
                                        color: Color(0xFFF79F1A),
                                        fontSize: w * 0.04,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                            child: Container(
                              height: 280,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child:
                                  StreamBuilder<
                                    QuerySnapshot<Map<String, dynamic>>
                                  >(
                                    stream: workerUid == null
                                        ? null
                                        : FirebaseFirestore.instance
                                              .collection('bookings')
                                              .where(
                                                'workerUid',
                                                isEqualTo: workerUid,
                                              )
                                              .where(
                                                'status',
                                                whereIn: [
                                                  'confirmed',
                                                  'in_progress',
                                                  'started',
                                                ],
                                              )
                                              .orderBy(
                                                'updatedAt',
                                                descending: true,
                                              )
                                              .snapshots(),
                                    builder: (ctx, snap) {
                                      if (snap.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      }

                                      final docs = snap.data?.docs ?? [];
                                      if (docs.isEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Text(
                                                  'No active job currently',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 6),
                                                Text(
                                                  'Job details will appear here when the job day starts.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      return _buildMultiActiveJobCard(
                                        docs,
                                        screenWidth,
                                      );
                                    },
                                  ),
                            ),
                          ),
                          SizedBox(height: 20),
                          // Earnings
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Your Earnings Summary',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: w * 0.045,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const WorkerEarningsScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    child: Text(
                                      'View All',
                                      style: TextStyle(
                                        color: Color(0xFFF79F1A),
                                        fontSize: w * 0.04,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                            child: Container(
                              height: 170,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Amount:',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        StreamBuilder<DocumentSnapshot>(
                                          stream:
                                              FirebaseAuth
                                                      .instance
                                                      .currentUser !=
                                                  null
                                              ? FirebaseFirestore.instance
                                                    .collection('Sign Up')
                                                    .doc(
                                                      FirebaseAuth
                                                          .instance
                                                          .currentUser!
                                                          .uid,
                                                    )
                                                    .snapshots()
                                              : null,
                                          builder: (ctx, snap) {
                                            int amount = 0;
                                            if (snap.hasData &&
                                                snap.data!.exists) {
                                              final data =
                                                  snap.data!.data()
                                                      as Map<String, dynamic>?;
                                              amount = data?['amount'] ?? 0;
                                            }

                                            return Text(
                                              'UGX ${NumberFormat('#,###').format(amount)}',
                                              style: const TextStyle(
                                                color: Color(0xFFFFA10D),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Text(
                                          'Jobs Completed:',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser
                                                    ?.uid,
                                              )
                                              .snapshots(),
                                          builder: (ctx, snap) {
                                            final data =
                                                snap.data?.data()
                                                    as Map<String, dynamic>?;
                                            final jobsCompleted =
                                                (data?['jobsCompleted'] ?? 0)
                                                    .toString();
                                            return Text(
                                              jobsCompleted,
                                              style: const TextStyle(
                                                color: Color(0xFFFFA10D),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Text(
                                          'Hours Worked:',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser
                                                    ?.uid,
                                              )
                                              .snapshots(),
                                          builder: (ctx, snap) {
                                            final data =
                                                snap.data?.data()
                                                    as Map<String, dynamic>?;
                                            final seconds =
                                                (data?['hoursWorkedSeconds'] ??
                                                        0)
                                                    as int;
                                            return Text(
                                              _formatDuration(
                                                Duration(seconds: seconds),
                                              ),
                                              style: const TextStyle(
                                                color: Color(0xFFFFA10D),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Center(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const WalletFlowScreen(),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: screenWidth * 0.4,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFA10D),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.wallet,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'View Wallet',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavBar(currentIndex: 0),
        ),
        SideBar(key: _sidebarKey),
      ],
    );
  }
}
