import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerProfession extends StatelessWidget {
  const WorkerProfession({super.key});

  Future<String?> _fetchProfession() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // First, get the workerType from the user's document
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String? workerType = userData['workerType'] as String?;

        if (workerType == 'Non-Professional Worker') {
          // Query serviceProviders collection where workerUid == user.uid
          QuerySnapshot query = await FirebaseFirestore.instance
              .collection('serviceProviders')
              .where('workerUid', isEqualTo: user.uid)
              .limit(1)
              .get();
          if (query.docs.isNotEmpty && query.docs.first.data() != null) {
            Map<String, dynamic> providerData =
                query.docs.first.data() as Map<String, dynamic>;
            return providerData['jobCategoryName'] as String?;
          }
        } else {
          // For Professional Workers, use the existing logic
          DocumentSnapshot doc = await FirebaseFirestore.instance
              .collection('Sign Up')
              .doc(user.uid)
              .collection('documents')
              .doc('Professional Workers')
              .get();
          if (doc.exists && doc.data() != null) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('Academic Certificate')) {
              Map<String, dynamic> academicCert =
                  data['Academic Certificate'] as Map<String, dynamic>;
              return academicCert['profession'] as String?;
            }
          }
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
          snapshot.data ?? 'Unknown',
          style: TextStyle(color: Colors.black),
        );
      },
    );
  }
}
