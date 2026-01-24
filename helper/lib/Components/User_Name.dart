import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserName extends StatelessWidget {
  const UserName({super.key});

  Future<String?> _fetchFullName() async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null; // User not authenticated
      }

      // Fetch the document from "Sign Up" collection
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['fullName'] as String?; // Assuming 'fullName' is a string field
      } else {
        return null; // Document or field doesn't exist
      }
    } catch (e) {
      print('Error fetching fullName: $e');
      return null; // Handle errors gracefully
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _fetchFullName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator
          return const Text(
            'Loading...',
            style: TextStyle(color: Colors.black, fontSize: 16),
          );
        } else if (snapshot.hasError || snapshot.data == null) {
          // Show error or default text
          return const Text(
            'User',
            style: TextStyle(color: Colors.orange, fontSize: 16),
          );
        } else {
          // Display the fullName
          return Text(
            snapshot.data!,
            style: const TextStyle(color: Colors.orange, fontSize: 16),
          );
        }
      },
    );
  }
}