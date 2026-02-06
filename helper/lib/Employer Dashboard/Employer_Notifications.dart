import 'dart:async';

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
  List<Map<String, dynamic>> _allMessages = [];
  StreamSubscription? _supportSubscription;
  StreamSubscription? _notifSubscription;
  StreamSubscription? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  void _loadMessages() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _supportSubscription = FirebaseFirestore.instance
        .collection('Support Issues')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .listen((snapshot) {
          _updateMessages();
        });

    _notifSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('audience', whereIn: ['all', 'employers'])
        .snapshots()
        .listen((snapshot) {
          _updateMessages();
        });

    _messagesSubscription = FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .snapshots()
        .listen((snapshot) {
          _updateMessages();
        });
  }

  Future<void> _updateMessages() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      List<Map<String, dynamic>> messages = [];

      // Add support messages
      final supportSnap = await FirebaseFirestore.instance
          .collection('Support Issues')
          .where('userId', isEqualTo: currentUser.uid)
          .get();
      int supportCount = 0;
      for (var doc in supportSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final msgs = data['messages'] as List<dynamic>? ?? [];
        for (var msg in msgs) {
          if (msg is Map<String, dynamic> &&
              (msg['sender'] == 'admin' || msg['sender'] == 'system')) {
            messages.add(msg as Map<String, dynamic>);
            supportCount++;
          }
        }
      }

      // Add notifications
      final notifSnap = await FirebaseFirestore.instance
          .collection('notifications')
          .where('audience', whereIn: ['all', 'employers'])
          .get();
      int notifCount = notifSnap.docs.length;
      for (var doc in notifSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        messages.add({
          'message': data['title'] != null
              ? '${data['title']}: ${data['message'] ?? ''}'
              : data['message'] ?? '',
          'sender': 'system',
          'senderId': data['sentBy'] ?? 'system',
          'senderName': 'Push Notification',
          'timestamp': data['sentAt'],
          'read': data['read'] ?? false,
          'status': 'info',
        });
      }

      // Add unread messages
      final messagesSnap = await FirebaseFirestore.instance
          .collectionGroup('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .get();
      int messageCount = 0;
      for (var doc in messagesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['read'] == false) {
          final senderId = data['senderId'] as String?;
          String senderName = 'Unknown';
          if (senderId != null) {
            final senderDoc = await FirebaseFirestore.instance
                .collection('Sign Up')
                .doc(senderId)
                .get();
            if (senderDoc.exists) {
              senderName = senderDoc.data()?['fullName'] ?? 'Unknown';
            }
          }
          messages.add({
            'message': data['message'] ?? '',
            'sender': 'user',
            'senderId': senderId,
            'senderName': senderName,
            'timestamp': data['timestamp'],
            'read': data['read'] ?? false,
            'status': 'message',
          });
          messageCount++;
        }
      }

      messages.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Support: $supportCount, Notifications: $notifCount, Messages: $messageCount, Total: ${messages.length}',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      setState(() {
        _allMessages = messages;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('Support Issues')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final messages = List<Map<String, dynamic>>.from(
          data['messages'] ?? [],
        );
        bool updated = false;
        for (int i = 0; i < messages.length; i++) {
          if ((messages[i]['sender'] == 'admin' ||
                  messages[i]['sender'] == 'system') &&
              messages[i]['read'] != true) {
            messages[i]['read'] = true;
            updated = true;
          }
        }
        if (updated) {
          batch.update(doc.reference, {'messages': messages});
        }
      }

      // Mark notifications as read
      final notifQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('audience', whereIn: ['all', 'employers'])
          .get();

      for (var doc in notifQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['read'] != true) {
          batch.update(doc.reference, {'read': true});
        }
      }

      // Mark messages as read
      final messagesQuery = await FirebaseFirestore.instance
          .collectionGroup('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .get();

      for (var doc in messagesQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['read'] == false) {
          batch.update(doc.reference, {'read': true});
        }
      }

      await batch.commit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking messages as read: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('User not authenticated'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _allMessages.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.builder(
              itemCount: _allMessages.length,
              itemBuilder: (context, index) {
                final messageData = _allMessages[index];
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
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              sender == 'admin'
                                  ? Icons.admin_panel_settings
                                  : sender == 'user'
                                  ? Icons.person
                                  : Icons.info,
                              color: const Color(0xFFFFA10D),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              senderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
                                    : status == 'message'
                                    ? Colors.blue
                                    : status == 'info'
                                    ? Colors.blue
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
                        Text(message, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _supportSubscription?.cancel();
    _notifSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
