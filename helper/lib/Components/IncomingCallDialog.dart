import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Chats/Voice_Call_Screen.dart';

class IncomingCallDialog extends StatefulWidget {
  final String callId;
  final String callerName;

  const IncomingCallDialog({
    Key? key,
    required this.callId,
    required this.callerName,
  }) : super(key: key);

  @override
  _IncomingCallDialogState createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Incoming Call'),
      content: Text('${widget.callerName} is calling you.'),
      actions: [
        TextButton(
          onPressed: () => _declineCall(),
          child: const Text('Decline'),
        ),
        ElevatedButton(
          onPressed: () => _acceptCall(),
          child: const Text('Accept'),
        ),
      ],
    );
  }

  void _acceptCall() async {
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'accepted'});
    Navigator.of(context).pop();
    // Parse callId to get callerId and providerId
    final ids = widget.callId.split('_');
    final callerId = ids[0];
    final providerId = ids[1];
    // Navigate to VoiceCallScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VoiceCallScreen(
          businessName: widget.callerName,
          providerId: providerId,
          callerId: callerId,
        ),
      ),
    );
  }

  void _declineCall() async {
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'declined'});
    Navigator.of(context).pop();
  }
}
