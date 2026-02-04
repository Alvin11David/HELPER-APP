import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EmployerNotifications extends StatefulWidget {
  const EmployerNotifications({super.key});

  @override
  _EmployerNotificationsState createState() => _EmployerNotificationsState();
}

class _EmployerNotificationsState extends State<EmployerNotifications> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('User not authenticated'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Messages'),
        backgroundColor: const Color(0xFFFFA10D),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Support Issues')
            .where('userId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          List<Map<String, dynamic>> allMessages = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>?;
            final messages =
                (data != null ? data['messages'] : null) as List<dynamic>? ??
                [];
            for (var msg in messages) {
              if (msg is Map<String, dynamic> && msg['sender'] == 'admin') {
                allMessages.add(msg);
              }
            }
          }

          allMessages.sort((a, b) {
            final aTime = a['timestamp'] as Timestamp?;
            final bTime = b['timestamp'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime); // descending
          });

          if (allMessages.isEmpty) {
            return const Center(child: Text('No messages from admin'));
          }

          return ListView.builder(
            itemCount: allMessages.length,
            itemBuilder: (context, index) {
              final messageData = allMessages[index];
              final message = messageData['message'] ?? '';
              final sender = messageData['sender'] ?? '';
              final senderId = messageData['senderId'] ?? '';
              final senderName = messageData['senderName'] ?? '';
              final timestamp = messageData['timestamp'];
              final status = messageData['status'] ?? '';

              String formattedTime = '';
              if (timestamp != null && timestamp is Timestamp) {
                final dateTime = timestamp.toDate();
                formattedTime = DateFormat(
                  'MMMM d, yyyy \'at\' h:mm:ss a \'UTC\'z',
                ).format(dateTime);
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFFFFA10D),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            senderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'resolved'
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(message, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        formattedTime,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
