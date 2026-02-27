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
  int _unreadCount = 0;
  bool _loadingUnread = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    int count = 0;
    // Support Issues
    final query = await FirebaseFirestore.instance
        .collection('Support Issues')
        .where('userId', isEqualTo: currentUser.uid)
        .get();
    for (var doc in query.docs) {
      final data = doc.data();
      final messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
      for (final msg in messages) {
        if ((msg['sender'] == 'admin' || msg['sender'] == 'system') &&
            msg['read'] != true) {
          count++;
        }
      }
    }
    // Notifications
    final notifQuery = await FirebaseFirestore.instance
        .collection('Notifications')
        .where('audience', whereIn: ['all', 'employers'])
        .get();
    for (var doc in notifQuery.docs) {
      final data = doc.data();
      if (data['read'] != true) count++;
    }
    // Employer notifications
    final employerNotifQuery = await FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: currentUser.uid)
        .get();
    for (var doc in employerNotifQuery.docs) {
      final data = doc.data();
      if (data['read'] != true) count++;
    }
    // Role notifications
    final roleNotifQuery = await FirebaseFirestore.instance
        .collection('EmployerNotifications')
        .where('employerId', isEqualTo: currentUser.uid)
        .get();
    for (var doc in roleNotifQuery.docs) {
      final data = doc.data();
      if (data['read'] != true) count++;
    }
    if (mounted) {
      setState(() {
        _unreadCount = count;
        _loadingUnread = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final query = await FirebaseFirestore.instance
        .collection('Support Issues')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in query.docs) {
      final data = doc.data();
      final messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
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
        .collection('Notifications')
        .where('audience', whereIn: ['all', 'employers'])
        .get();

    for (var doc in notifQuery.docs) {
      final data = doc.data();
      if (data['read'] != true) {
        batch.update(doc.reference, {'read': true});
      }
    }

    final employerNotifQuery = await FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: currentUser.uid)
        .get();

    for (var doc in employerNotifQuery.docs) {
      final data = doc.data();
      if (data['read'] != true) {
        batch.update(doc.reference, {'read': true});
      }
    }

    final roleNotifQuery = await FirebaseFirestore.instance
        .collection('EmployerNotifications')
        .where('employerId', isEqualTo: currentUser.uid)
        .get();

    for (var doc in roleNotifQuery.docs) {
      final data = doc.data();
      if (data['read'] != true) {
        batch.update(doc.reference, {'read': true});
      }
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('User not authenticated'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            const SizedBox(width: 8),
            if (_loadingUnread)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
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

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('EmployerNotifications')
                .where('employerId', isEqualTo: currentUser.uid)
                .snapshots(),
            builder: (context, roleNotifSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('toUserId', isEqualTo: currentUser.uid)
                    .snapshots(),
                builder: (context, employerNotifSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Notifications')
                        .where('audience', whereIn: ['all', 'employers'])
                        .snapshots(),
                    builder: (context, notifSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Escrow')
                            .where('employerId', isEqualTo: currentUser.uid)
                            .where('cancellationStatus', isEqualTo: 'pending')
                            .snapshots(),
                        builder: (context, escrowSnapshot) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Escrow')
                                .where('employerId', isEqualTo: currentUser.uid)
                                .where('completionStatus', isEqualTo: 'pending')
                                .snapshots(),
                            builder: (context, completionSnapshot) {
                              List<Map<String, dynamic>> allMessages = [];

                              for (var doc in docs) {
                                final data =
                                    doc.data() as Map<String, dynamic>?;
                                final messages =
                                    (data != null ? data['messages'] : null)
                                        as List<dynamic>? ??
                                    [];
                                for (var msg in messages) {
                                  if (msg is Map<String, dynamic> &&
                                      (msg['sender'] == 'admin' ||
                                          msg['sender'] == 'system')) {
                                    allMessages.add(msg);
                                  }
                                }
                              }

                              if (employerNotifSnapshot.hasData) {
                                for (var doc
                                    in employerNotifSnapshot.data!.docs) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  allMessages.add({
                                    'message': data['title'] != null
                                        ? '${data['title']}: ${data['message'] ?? ''}'
                                        : data['message'] ?? '',
                                    'sender': 'system',
                                    'senderId': data['fromUserId'] ?? 'system',
                                    'senderName': 'Employer Notification',
                                    'timestamp': data['createdAt'],
                                    'read': data['read'] ?? false,
                                    'status': data['type'] ?? 'info',
                                  });
                                }
                              }

                              if (roleNotifSnapshot.hasData) {
                                for (var doc in roleNotifSnapshot.data!.docs) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  allMessages.add({
                                    'message': data['title'] != null
                                        ? '${data['title']}: ${data['message'] ?? ''}'
                                        : data['message'] ?? '',
                                    'sender': 'system',
                                    'senderId': data['workerUid'] ?? 'system',
                                    'senderName': 'Employer Notification',
                                    'timestamp': data['timestamp'],
                                    'read': data['read'] ?? false,
                                    'status': data['type'] ?? 'info',
                                  });
                                }
                              }

                              if (notifSnapshot.hasData) {
                                for (var doc in notifSnapshot.data!.docs) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  allMessages.add({
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
                              }

                              if (escrowSnapshot.hasData) {
                                for (var doc in escrowSnapshot.data!.docs) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final code = (data['cancellationCode'] ?? '')
                                      .toString();
                                  if (code.isEmpty) continue;
                                  allMessages.add({
                                    'message': 'Cancellation code: $code',
                                    'sender': 'system',
                                    'senderId':
                                        data['cancellationRequestedBy'] ??
                                        'system',
                                    'senderName': 'Escrow Cancellation',
                                    'timestamp':
                                        data['cancellationRequestedAt'] ??
                                        data['updatedAt'],
                                    'read': false,
                                    'status': 'info',
                                  });
                                }
                              }

                              if (completionSnapshot.hasData) {
                                for (var doc in completionSnapshot.data!.docs) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final code = (data['completionCode'] ?? '')
                                      .toString();
                                  if (code.isEmpty) continue;
                                  allMessages.add({
                                    'message': 'Completion code: $code',
                                    'sender': 'system',
                                    'senderId': data['workerUid'] ?? 'system',
                                    'senderName': 'Job Completion',
                                    'timestamp':
                                        data['completionRequestedAt'] ??
                                        data['updatedAt'],
                                    'read': false,
                                    'status': 'info',
                                  });
                                }
                              }

                              allMessages.sort((a, b) {
                                final aTime = a['timestamp'] as Timestamp?;
                                final bTime = b['timestamp'] as Timestamp?;
                                if (aTime == null || bTime == null) return 0;
                                return bTime.compareTo(aTime); // descending
                              });

                              if (allMessages.isEmpty) {
                                return const Center(
                                  child: Text('No notifications'),
                                );
                              }

                              return ListView.builder(
                                itemCount: allMessages.length,
                                itemBuilder: (context, index) {
                                  final messageData = allMessages[index];
                                  final message = messageData['message'] ?? '';
                                  final sender = messageData['sender'] ?? '';
                                  final senderId =
                                      messageData['senderId'] ?? '';
                                  final senderName =
                                      messageData['senderName'] ?? '';
                                  final timestamp = messageData['timestamp'];
                                  final status = messageData['status'] ?? '';

                                  String formattedTime = '';
                                  if (timestamp != null &&
                                      timestamp is Timestamp) {
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                sender == 'admin'
                                                    ? Icons.admin_panel_settings
                                                    : Icons.info,
                                                color: const Color(0xFFFFA10D),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  senderName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: status == 'resolved'
                                                      ? Colors.green
                                                      : status == 'info'
                                                      ? Colors.blue
                                                      : Colors.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
                                          Text(
                                            message,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
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
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
