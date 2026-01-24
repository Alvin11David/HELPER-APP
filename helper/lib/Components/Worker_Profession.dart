import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerProfession extends StatelessWidget {
  const WorkerProfession({super.key});

  Future<String?> _fetchProfession() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .doc('Professional Workers')
          .get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('Academic Certificate')) {
          Map<String, dynamic> academicCert = data['Academic Certificate'] as Map<String, dynamic>;
          return academicCert['profession'] as String?;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _fetchProfession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            'Loading...',
            style: TextStyle(color: Colors.black),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Text(
            'Profession not available',
            style: TextStyle(color: Colors.black),
          );
        }
        return Text(
          snapshot.data!,
          style: TextStyle(color: Colors.black),
        );
      },
    );
  }
}