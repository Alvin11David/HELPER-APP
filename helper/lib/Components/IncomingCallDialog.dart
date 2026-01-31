import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomingCallDialog extends StatefulWidget {
  final String callId;
  final String callerName;

  const IncomingCallDialog({
    super.key,
    required this.callId,
    required this.callerName,
  });

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
    // Navigate to call screen or start VoIP call
  }

  void _declineCall() async {
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .update({'status': 'declined'});
    Navigator.of(context).pop();
  }
}
