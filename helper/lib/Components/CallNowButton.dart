import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../Chats/Voice_Call_Screen.dart';

class CallNowButton extends StatelessWidget {
  final String providerId;
  final String businessName;

  const CallNowButton({
    Key? key,
    required this.providerId,
    required this.businessName,
  }) : super(key: key);

  Future<void> _handleCall(BuildContext context) async {
    print(
      'CallNowButton tapped for provider: $providerId, business: $businessName',
    );

    // Check if worker is online
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(providerId)
        .get();

    final isOnline = doc.data()?['isOnline'] ?? false;
    print('Provider online status: $isOnline');

    if (!isOnline) {
      // TEMPORARILY BYPASS OFFLINE CHECK FOR TESTING
      print('Provider is offline, but bypassing check for testing');
      // Play offline message
      // final player = AudioPlayer();
      // await player.play(
      //   AssetSource('audio/offline_message.mp3'),
      // ); // Assume you have this file
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Provider is not available. Please try again later.'),
      //   ),
      // );
      // return;
    }

    // Worker is online, send call request
    final callerId = FirebaseAuth.instance.currentUser!.uid;
    final callId = DateTime.now().millisecondsSinceEpoch.toString();

    print('Initiating call: $callId from $callerId to $providerId');

    // Send notification to worker
    await FirebaseFirestore.instance.collection('calls').doc(callId).set({
      'callerId': callerId,
      'receiverId': providerId,
      'callerName': businessName, // Add caller name for the Cloud Function
      'status': 'ringing',
      'timestamp': FieldValue.serverTimestamp(),
    });

    print(
      'Call document created in Firestore, Cloud Function should send FCM notification',
    );

    // Check if FCM token exists
    final fcmToken = doc.data()?['fcmToken'];
    print('FCM token for receiver: ${fcmToken != null ? "exists" : "null"}');

    print('Navigating to VoiceCallScreen');

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
          ),
        ),
      );
      print('Navigation successful');
    } catch (e) {
      print('Navigation failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Navigation failed: $e')));
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
