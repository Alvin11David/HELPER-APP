import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserEmailOrPhoneNumber extends StatelessWidget {
  const UserEmailOrPhoneNumber({super.key});

  Future<String?> _fetchEmailOrPhone() async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null; // User not authenticated
      }

      // First, get the activeRole from "Sign Up"
      DocumentSnapshot signUpDoc = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .get();
      String? activeRole;
      if (signUpDoc.exists && signUpDoc.data() != null) {
        activeRole =
            (signUpDoc.data() as Map<String, dynamic>)['activeRole'] as String?;
        activeRole ??= (signUpDoc.data() as Map<String, dynamic>)['role'] as String?;
      }

      // Try to fetch from "User Roles" first
      if (activeRole != null) {
        DocumentSnapshot roleDoc = await FirebaseFirestore.instance
            .collection('User Roles')
            .doc('${user.uid}_$activeRole')
            .get();
        if (roleDoc.exists && roleDoc.data() != null) {
          Map<String, dynamic> data = roleDoc.data() as Map<String, dynamic>;
          String? email = data['email'] as String?;
          String? phoneNumber = data['phoneNumber'] as String?;
          if (email != null || phoneNumber != null) {
            return email ?? phoneNumber;
          }
        }
      }

      // Fallback to "Sign Up"
      if (signUpDoc.exists && signUpDoc.data() != null) {
        Map<String, dynamic> data = signUpDoc.data() as Map<String, dynamic>;
        String? email = data['email'] as String?;
        String? phoneNumber = data['phoneNumber'] as String?;
        return email ?? phoneNumber;
      } else {
        return null; // Document or fields don't exist
      }
    } catch (e) {
      print('Error fetching email or phone number: $e');
      return null; // Handle errors gracefully
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _fetchEmailOrPhone(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading indicator
          return const Text(
            'Loading...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          );
        } else if (snapshot.hasError || snapshot.data == null) {
          // Show error or default text
          return const Text(
            'No contact info',
            style: TextStyle(color: Colors.white, fontSize: 16),
          );
        } else {
          // Display the email or phone number
          return Text(
            snapshot.data!,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          );
        }
      },
    );
  }
}
