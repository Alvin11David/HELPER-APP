import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserName extends StatefulWidget {
  const UserName({super.key});

  @override
  State<UserName> createState() => _UserNameState();
}

class _UserNameState extends State<UserName> {
  late Future<String?> _fullNameFuture;

  @override
  void initState() {
    super.initState();
    _fullNameFuture = _fetchFullName(); // runs ONCE
  }

  Future<String?> _fetchFullName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

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
      future: _fullNameFuture, // cached future
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
