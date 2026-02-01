import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:helper/Components/IncomingCallDialog.dart';
import '../Chats/Voice_Call_Screen.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';

class CallNowButton extends StatelessWidget {
  final String providerId;
  final String businessName;

  const CallNowButton({
    super.key,
    required this.providerId,
    required this.businessName,
  });

  Future<void> _handleCall(BuildContext context) async {
    // Show initial debug info
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('🔍 Call Now Button Tapped')));

    // Show worker's user ID being called
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('👷 Calling Worker ID: $providerId'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ),
    );

    print('=== CALL NOW BUTTON TAPPED ===');
    print('Provider ID: $providerId');
    print('Business Name: $businessName');

    // Check if worker is online
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(providerId)
        .get();

    final isOnline = doc.data()?['isOnline'] ?? false;
    print('Provider online status: $isOnline');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('📱 Provider online: $isOnline')));

    if (!isOnline) {
      print('Provider is offline, but bypassing check for testing');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Provider offline - bypassing for testing'),
        ),
      );
    }

    // Fetch portfolio image from serviceProviders collection
    String? portfolioImageUrl;
    try {
      print('Fetching portfolio image for provider: $providerId');
      final serviceProviderDoc = await FirebaseFirestore.instance
          .collection('serviceProviders')
          .doc(providerId)
          .get();

      if (serviceProviderDoc.exists && serviceProviderDoc.data() != null) {
        final data = serviceProviderDoc.data()!;
        final portfolioFiles = data['portfolioFiles'] as List<dynamic>?;
        if (portfolioFiles != null && portfolioFiles.isNotEmpty) {
          portfolioImageUrl = portfolioFiles[0] as String?;
          print('Portfolio image found: $portfolioImageUrl');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🖼️ Portfolio image found')),
          );
        } else {
          print('No portfolio files found in serviceProviders document');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ No portfolio files found')),
          );
        }
      } else {
        print(
          'serviceProviders document does not exist for provider: $providerId',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ serviceProviders document not found'),
          ),
        );
      }
    } catch (e) {
      print('Error fetching portfolio image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error fetching portfolio: $e')));
    }

    // Worker is online, send call request
    final callerId = FirebaseAuth.instance.currentUser!.uid;
    final callId = '${callerId}_$providerId';

    // Fetch caller's full name
    final callerDoc = await FirebaseFirestore.instance
        .collection('Sign Up')
        .doc(callerId)
        .get();
    final callerFullName = callerDoc.data()?['fullName'] ?? businessName;

    print('=== CREATING CALL DOCUMENT ===');
    print('Call ID: $callId');
    print('Caller ID: $callerId');
    print('Receiver ID: $providerId');
    print('Caller Name: $callerFullName');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📞 Creating call document: $callId')),
    );

    try {
      // Send notification to worker
      await FirebaseFirestore.instance.collection('calls').doc(callId).set({
        'callerId': callerId,
        'receiverId': providerId,
        'callerName': callerFullName, // Use full name instead of business name
        'status': 'ringing',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Call document created successfully in Firestore');
      print('Cloud Function should now trigger and send FCM notification');

      // Verify the document was created
      final createdDoc = await FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .get();
      if (createdDoc.exists) {
        print('✅ Document verified in Firestore: ${createdDoc.data()}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Document verified in Firestore'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('❌ Document not found in Firestore after creation!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Document creation failed'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Call document created - waiting for Cloud Function'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );

      // Wait a moment for Cloud Function to trigger
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⏳ Cloud Function should have triggered - check worker phone',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print('ERROR creating call document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error creating call document: $e')),
      );
      return;
    }

    // Check if FCM token exists
    final fcmToken = doc.data()?['fcmToken'];
    print('FCM token exists for receiver: ${fcmToken != null ? "YES" : "NO"}');
    if (fcmToken != null) {
      print('FCM token preview: ${fcmToken.substring(0, 50)}...');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ FCM token found for worker'),
          backgroundColor: Colors.green,
        ),
      );

      // Test: Send FCM message directly to test if FCM works
      _testSendFCM(context, fcmToken, callId, callerFullName);
    } else {
      print('ERROR: No FCM token found for worker!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ No FCM token found for worker - notifications won\'t work',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );

      // Test: Show the incoming call dialog on the caller's side to test if it works
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧪 Testing: Showing call dialog on caller side'),
          backgroundColor: Colors.orange,
        ),
      );

      // Show test dialog on caller's side
      showDialog(
        context: context,
        builder: (context) =>
            IncomingCallDialog(callId: callId, callerName: 'TEST CALLER'),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔑 FCM token exists: ${fcmToken != null ? "YES" : "NO"}',
        ),
      ),
    );

    // Wait for receiver to accept the call instead of navigating immediately
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏳ Waiting for worker to accept call...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );

    // Listen for call status changes
    final callDocRef = FirebaseFirestore.instance
        .collection('calls')
        .doc(callId);
    late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
    subscription;
    subscription = callDocRef.snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data();
        final status = data?['status'];

        if (status == 'accepted') {
          // Receiver accepted - now navigate to call screen
          subscription.cancel(); // Stop listening

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Worker accepted - connecting call...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          try {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VoiceCallScreen(
                  businessName: businessName,
                  providerId: providerId,
                  callerId: callerId,
                  portfolioImageUrl: portfolioImageUrl,
                ),
              ),
            );
            print('Navigation to VoiceCallScreen successful');
          } catch (e) {
            print('Navigation failed: $e');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('❌ Navigation failed: $e')));
          }
        } else if (status == 'declined') {
          // Receiver declined - show message and stop listening
          subscription.cancel();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Worker declined the call'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });

    // Timeout after 30 seconds if no response
    Future.delayed(const Duration(seconds: 30), () {
      if (!subscription.isPaused) {
        subscription.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏰ Call timeout - no response from worker'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _testSendFCM(
    BuildContext context,
    String fcmToken,
    String callId,
    String callerName,
  ) async {
    try {
      // For testing, we'll call the test Cloud Function
      print('=== TESTING FCM VIA CLOUD FUNCTION ===');
      print('FCM Token: ${fcmToken.substring(0, 50)}...');
      print('Call ID: $callId');
      print('Caller Name: $callerName');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Testing FCM via Cloud Function...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Try to call the test function
      try {
        final result = await FirebaseFunctions.instance
            .httpsCallable('testCallNotification')
            .call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Cloud Function responded: ${result.data['message'] ?? 'OK'}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Cloud Function call failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Cloud Function error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error testing FCM: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ FCM test error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleCall(context),
      child: Container(
        width: 148,
        height: 30,
        decoration: const BoxDecoration(
          color: Color(0xFFFFA10D),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            const Text(
              'Call Now',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
