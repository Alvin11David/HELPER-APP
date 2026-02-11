import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployerNotificationsBadge extends StatefulWidget {
  const EmployerNotificationsBadge({super.key});

  @override
  _EmployerNotificationsBadgeState createState() =>
      _EmployerNotificationsBadgeState();
}

class _EmployerNotificationsBadgeState
    extends State<EmployerNotificationsBadge> {
  int _unreadCount = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Support Issues')
          .where('userId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, supportSnapshot) {
        int supportCount = 0;
        if (supportSnapshot.hasData) {
          for (var doc in supportSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final messages = List<Map<String, dynamic>>.from(
              data['messages'] ?? [],
            );
            for (var msg in messages) {
              if (msg['sender'] == 'admin' &&
                  !(msg['read'] == true)) {
                supportCount++;
              }
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('messages')
              .where('receiverId', isEqualTo: currentUser.uid)
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, messagesSnapshot) {
            int messagesCount = 0;
            if (messagesSnapshot.hasData) {
              messagesCount = messagesSnapshot.data!.docs.length;
            }

            _unreadCount = supportCount + messagesCount;
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
