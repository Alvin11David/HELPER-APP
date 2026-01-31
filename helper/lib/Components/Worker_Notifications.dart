import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerNotificationsBadge extends StatefulWidget {
  const WorkerNotificationsBadge({super.key});

  @override
  _WorkerNotificationsBadgeState createState() =>
      _WorkerNotificationsBadgeState();
}

class _WorkerNotificationsBadgeState extends State<WorkerNotificationsBadge> {
  int _unreadCount = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workerNotifications')
          .where('workerId', isEqualTo: currentUser.uid)
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildBadge();
        }
        if (snapshot.hasData) {
          _unreadCount = snapshot.data!.docs.length;
        }
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
