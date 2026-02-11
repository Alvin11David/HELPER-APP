import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserName extends StatefulWidget {
  final String? role; // Optional role parameter

  const UserName({super.key, this.role});

  @override
  State<UserName> createState() => _UserNameState();
}

class _UserNameState extends State<UserName> {
  Future<String?>? _fullNameFuture;

  @override
  void initState() {
    super.initState();
    _fullNameFuture = _fetchFullName(); // Fetch based on role
  }

  Future<String?> _fetchFullName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      String docId;
      if (widget.role != null) {
        // Fetch from User Roles collection
        docId = '${user.uid}_${widget.role}';
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('User Roles')
            .doc(docId)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          return data['fullName'] as String?;
        }
      }

      // Fallback to Sign Up collection
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fullName'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching fullName: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _fullNameFuture, // cached future globally
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            'Loading...',
            style: TextStyle(color: Colors.orange, fontSize: 16),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Text(
            'User',
            style: TextStyle(color: Colors.orange, fontSize: 16),
          );
        } else {
          return Text(
            snapshot.data!,
            style: const TextStyle(color: Colors.orange, fontSize: 16),
          );
        }
      },
    );
  }
}
