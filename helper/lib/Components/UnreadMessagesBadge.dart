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
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Keep previous count on error
          return _buildBadge();
        }
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          // Count unique senders
          final senders = docs.map((doc) => doc['senderId'] as String).toSet();
          _unreadCount = senders.length;
        }
        // Always return the badge with current count
        return _buildBadge();
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
