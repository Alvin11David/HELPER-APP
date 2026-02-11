import 'package:cloud_firestore/cloud_firestore.dart';

class UserRole {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> fetchUidFromSignUp() async {
    try {
      // Assuming 'Sign Up' is the collection name, and fetching the first document or a specific one.
      // Adjust query as needed, e.g., by user ID or other field.
      QuerySnapshot snapshot = await _firestore.collection('Sign Up').get();
      if (snapshot.docs.isNotEmpty) {
        // Assuming the uid is in the first document; modify to target specific doc.
        return snapshot.docs.first['uid'];
      }
      return null;
    } catch (e) {
      print('Error fetching uid: $e');
      return null;
    }
  }
}