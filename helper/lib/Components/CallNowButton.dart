import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Chats/Voice_Call_Screen.dart';

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Call document created - waiting for Cloud Function'),
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
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔑 FCM token exists: ${fcmToken != null ? "YES" : "NO"}',
        ),
      ),
    );

    print('=== NAVIGATING TO VOICE CALL SCREEN ===');

    try {
      // Show ringing UI or navigate to call screen
      // Navigate to VoiceCallScreen
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📱 Navigating to Voice Call Screen')),
      );
    } catch (e) {
      print('Navigation failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Navigation failed: $e')));
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
