import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class CallNowButton extends StatelessWidget {
  final String providerId;
  final String businessName;

  const CallNowButton({
    Key? key,
    required this.providerId,
    required this.businessName,
  }) : super(key: key);

  Future<void> _handleCall(BuildContext context) async {
    // Check if worker is online
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(providerId)
        .get();
    final isOnline = doc.data()?['isOnline'] ?? false;

    if (!isOnline) {
      // Play offline message
      final player = AudioPlayer();
      await player.play(
        AssetSource('audio/offline_message.mp3'),
      ); // Assume you have this file
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provider is not available. Please try again later.'),
        ),
      );
      return;
    }

    // Worker is online, send call request
    final callerId = FirebaseAuth.instance.currentUser!.uid;
    final callId = DateTime.now().millisecondsSinceEpoch.toString();

    // Send notification to worker
    await FirebaseFirestore.instance.collection('calls').doc(callId).set({
      'callerId': callerId,
      'receiverId': providerId,
      'status': 'ringing',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Send FCM notification
    final fcmToken = doc.data()?['fcmToken'];
    if (fcmToken != null) {
      await FirebaseMessaging.instance.sendMessage(
        to: fcmToken,
        data: {'type': 'call', 'callId': callId, 'callerName': businessName},
      );
    }

    // Show ringing UI or navigate to call screen
    // For now, just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calling...'),
        content: Text('Calling $businessName'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
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
