import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:helper/Components/User_Name.dart';
import 'package:helper/Components/UnreadMessagesBadge.dart';
import 'package:helper/Components/IncomingCallDialog.dart';
import '../Components/Side_Bar.dart';
import 'package:helper/Components/user_avatar_circle.dart';
import 'package:helper/Components/Bottom_Nav_Bar.dart';
import 'Worker_Jobs_Hub_Screen.dart';

class WorkersDashboardScreen extends StatefulWidget {
  const WorkersDashboardScreen({super.key});

  @override
  State<WorkersDashboardScreen> createState() => _WorkersDashboardScreenState();
}

class _WorkersDashboardScreenState extends State<WorkersDashboardScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<SideBarState> _sidebarKey = GlobalKey();

  String status = 'Available'; // Can be 'Available', 'On Job', 'Not Available'
  bool _isCallDialogShowing = false;

  @override
  void initState() {
    super.initState();
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
            showDialog(
              context: context,
              builder: (context) => IncomingCallDialog(
                callId: message.data['callId']!,
                callerName: message.data['callerName']!,
              ),
            ).then((_) => _isCallDialogShowing = false);
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

  Color getStatusColor() {
    if (status == 'Available') return const Color(0xFF00E539);
    if (status == 'On Job') return Colors.orange;
    return Colors.red; // Not Available
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
                                onTap: _showNotifications,
                                child: Container(
                                  width: 50, // Increased to accommodate badge
                                  height: 50, // Increased to accommodate badge
                                  child: Stack(
                                    alignment: Alignment.center,
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
                                        child: UnreadMessagesBadge(),
                                      ),
                                    ],
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
                          // Search bar
                          Padding(
                            padding: EdgeInsets.only(
                              top: 15,
                              left: w * 0.05,
                              right: w * 0.04,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 10),
                                        Icon(Icons.search, color: Colors.black),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: _controller,
                                            focusNode: _focusNode,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Search for jobs here...',
                                              border: InputBorder.none,
                                              hintStyle: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.tune,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: getStatusColor(),
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    height: 1.25,
                                  ),
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
                                    final uid =
                                        FirebaseAuth.instance.currentUser?.uid;
                                    if (uid == null) {
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
                                          providerId: uid,
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
                              child: Stack(
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
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Employer Name',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              'Job Type',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
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
                                          Container(
                                            width: screenWidth * 0.35,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Decline',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            width: screenWidth * 0.35,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Accept',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
                                Container(
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
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                            child: Container(
                              height: 190,
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
                                          'Employer Name:',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'Name',
                                          style: TextStyle(
                                            color: Color(0xFFFFA10D),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w300,
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
                                        Text(
                                          'Type',
                                          style: TextStyle(
                                            color: Color(0xFFFFA10D),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w300,
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
                                        Text(
                                          'Location',
                                          style: TextStyle(
                                            color: Color(0xFFFFA10D),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w300,
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
                                          '00:00:00',
                                          style: TextStyle(
                                            color: Color(0xFFFFA10D),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Center(
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
                                              Icons.phone,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Call Now',
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
                                  ],
                                ),
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
                                  'Today’s Earnings Summary',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: w * 0.045,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
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
                                        Text(
                                          'Amount',
                                          style: TextStyle(
                                            color: Color(0xFFFFA10D),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w300,
                                          ),
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
                                        Text(
                                          'Number',
                                          style: TextStyle(
                                            color: Color(0xFFFFA10D),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w300,
                                          ),
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
                                        Text(
                                          '00:00:00',
                                          style: TextStyle(
                                            color: Color(0xFFFFA10D),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Center(
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
