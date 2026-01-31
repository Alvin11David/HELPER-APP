import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UnreadMessagesBadge extends StatefulWidget {
  const UnreadMessagesBadge({super.key});

  @override
  _UnreadMessagesBadgeState createState() => _UnreadMessagesBadgeState();
}

class _UnreadMessagesBadgeState extends State<UnreadMessagesBadge> {
  int _unreadCount = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, messageSnapshot) {
        int messageCount = 0;
        if (messageSnapshot.hasData) {
          final docs = messageSnapshot.data!.docs;
          final senders = docs.map((doc) => doc['senderId'] as String).toSet();
          messageCount = senders.length;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('workerNotifications')
              .where('workerId', isEqualTo: currentUser.uid)
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, workerSnapshot) {
            int workerCount = 0;
            if (workerSnapshot.hasData) {
              workerCount = workerSnapshot.data!.docs.length;
            }

            _unreadCount = messageCount + workerCount;
            return _buildBadge();
          },
        );
      },
    );
  }

  Widget _buildBadge() {
    if (_unreadCount == 0) {
      return const SizedBox();
    }

    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _unreadCount > 99 ? '99+' : _unreadCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
