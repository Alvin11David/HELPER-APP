import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkerNotifications extends StatefulWidget {
  const WorkerNotifications({super.key});

  @override
  _WorkerNotificationsState createState() => _WorkerNotificationsState();
}

class _WorkerNotificationsState extends State<WorkerNotifications> {
  int _badgeDismissedAtCount = 0;
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
        .where('audience', whereIn: ['all', 'workers'])
        .get();

    for (var doc in notifQuery.docs) {
      final data = doc.data();
      if (data['read'] != true) {
        batch.update(doc.reference, {'read': true});
      }
    }

    final workerNotifQuery = await FirebaseFirestore.instance
        .collection('WorkerNotifications')
        .where('workerId', isEqualTo: currentUser.uid)
        .get();

    for (var doc in workerNotifQuery.docs) {
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

    return StreamBuilder<QuerySnapshot>(
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
              .collection('WorkerNotifications')
              .where('workerId', isEqualTo: currentUser.uid)
              .snapshots(),
          builder: (context, workerNotifSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Notifications')
                  .where('audience', whereIn: ['all', 'workers'])
                  .snapshots(),
              builder: (context, notifSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('workerUid', isEqualTo: currentUser.uid)
                      .snapshots(),
                  builder: (context, bookingsSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Escrow')
                          .where('workerUid', isEqualTo: currentUser.uid)
                          .where('cancellationStatus', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, escrowSnapshot) {
                        List<Map<String, dynamic>> allMessages = [];

                        // Support Issues
                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>?;
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

                        // Worker Notifications
                        if (workerNotifSnapshot.hasData) {
                          for (var doc in workerNotifSnapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            allMessages.add({
                              'message': data['title'] != null
                                  ? '${data['title']}: ${data['message'] ?? ''}'
                                  : data['message'] ?? '',
                              'sender': 'system',
                              'senderId': data['serviceProviderId'] ?? 'system',
                              'senderName': 'Booking Notification',
                              'timestamp': data['timestamp'],
                              'read': data['read'] ?? false,
                              'status': data['type'] ?? 'info',
                            });
                          }
                        }

                        // Push Notifications
                        if (notifSnapshot.hasData) {
                          for (var doc in notifSnapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
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

                        // Bookings from current worker
                        if (bookingsSnapshot.hasData) {
                          for (var doc in bookingsSnapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final jobCategory =
                                data['jobCategoryName'] ?? 'a job';
                            final location =
                                data['jobLocationText'] ?? 'your location';
                            final employerName =
                                data['employerName'] ?? 'Employer';
                            allMessages.add({
                              'message':
                                  'Booking: $employerName requested $jobCategory at $location',
                              'sender': 'system',
                              'senderId': data['employerId'] ?? 'system',
                              'senderName': 'Booking Request',
                              'timestamp': data['createdAt'],
                              'read': false,
                              'status': 'booking',
                            });
                          }
                        }

                        // Escrow Cancellations
                        if (escrowSnapshot.hasData) {
                          for (var doc in escrowSnapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final code = (data['cancellationCode'] ?? '')
                                .toString();
                            if (code.isEmpty) continue;
                            allMessages.add({
                              'message': 'Cancellation code: $code',
                              'sender': 'system',
                              'senderId':
                                  data['cancellationRequestedBy'] ?? 'system',
                              'senderName': 'Escrow Cancellation',
                              'timestamp':
                                  data['cancellationRequestedAt'] ??
                                  data['updatedAt'],
                              'read': false,
                              'status': 'info',
                            });
                          }
                        }

                        // Sort by timestamp descending
                        allMessages.sort((a, b) {
                          final aTime = a['timestamp'] as Timestamp?;
                          final bTime = b['timestamp'] as Timestamp?;
                          if (aTime == null || bTime == null) return 0;
                          return bTime.compareTo(aTime);
                        });

                        // Count unread messages
                        final unreadCount = allMessages
                            .where((msg) => msg['read'] == false)
                            .length;

                        final shouldShowBadge =
                            unreadCount > 0 &&
                            unreadCount > _badgeDismissedAtCount;

                        if (allMessages.isEmpty) {
                          return Scaffold(
                            appBar: AppBar(
                              title: const Text('Notifications'),
                              backgroundColor: const Color(0xFFFFA10D),
                            ),
                            body: const Center(child: Text('No notifications')),
                          );
                        }

                        return Scaffold(
                          appBar: AppBar(
                            title: Stack(
                              children: [
                                const Text('Notifications'),
                                if (shouldShowBadge)
                                  Positioned(
                                    right: 0,
                                    top: -5,
                                    child: GestureDetector(
                                      onTap: () {
                                        _markMessagesAsRead();
                                        setState(() {
                                          _badgeDismissedAtCount = unreadCount;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            backgroundColor: const Color(0xFFFFA10D),
                          ),
                          body: ListView.builder(
                            itemCount: allMessages.length,
                            itemBuilder: (context, index) {
                              final messageData = allMessages[index];
                              final message = messageData['message'] ?? '';
                              final sender = messageData['sender'] ?? '';
                              final senderId = messageData['senderId'] ?? '';
                              final senderName =
                                  messageData['senderName'] ?? '';
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
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: status == 'resolved'
                                                  ? Colors.green
                                                  : status == 'booking'
                                                  ? Colors.purple
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
                                        style: const TextStyle(fontSize: 12),
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
  }
}
