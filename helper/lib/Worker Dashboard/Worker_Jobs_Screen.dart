import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerJobsScreen extends StatefulWidget {
  const WorkerJobsScreen({Key? key}) : super(key: key);

  @override
  State<WorkerJobsScreen> createState() => _WorkerJobsScreenState();
}

class _WorkerJobsScreenState extends State<WorkerJobsScreen> {
  int _selectedIndex =
      0; // 0: Pending, 1: Confirmed, 2: Completed, 3: Cancelled

  static const List<String> _statuses = [
    'pending',
    'confirmed',
    'completed',
    'cancelled',
  ];

  static const List<String> _buttonLabels = [
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];

  Query<Map<String, dynamic>> _buildQuery(String uid, String status) {
    if (status == 'completed') {
      return FirebaseFirestore.instance
          .collection('bookings')
          .where('workerUid', isEqualTo: uid)
          .where('status', whereIn: ['completed', 'completed_pending'])
          .orderBy('updatedAt', descending: true);
    } else {
      return FirebaseFirestore.instance
          .collection('bookings')
          .where('workerUid', isEqualTo: uid)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('My Jobs')),
      body: user == null
          ? const Center(child: Text('Not logged in.'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_buttonLabels.length, (i) {
                        final isSelected = _selectedIndex == i;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? Colors.orange
                                  : Colors.grey[300],
                              foregroundColor: isSelected
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onPressed: () {
                              setState(() => _selectedIndex = i);
                            },
                            child: Text(_buttonLabels[i]),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _buildQuery(
                      user.uid,
                      _statuses[_selectedIndex],
                    ).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No ${_buttonLabels[_selectedIndex].toLowerCase()} jobs.',
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final employerName =
                              data['employerName'] ?? 'Employer';
                          final jobDescription =
                              data['jobDescription'] ?? 'No description';
                          final amount = data['amount'] ?? 0;
                          final startDateTime =
                              (data['startDateTime'] as Timestamp?)?.toDate();
                          final updatedAt = (data['updatedAt'] as Timestamp?)
                              ?.toDate();
                          final status = data['status'] ?? '';
                          final jobTitle = data['jobTitle'] ?? 'Job';
                          Widget trailing;
                          if (status == 'completed_pending') {
                            trailing = const Chip(
                              label: Text('Pending Code'),
                              backgroundColor: Colors.amber,
                            );
                          } else if (status == 'completed') {
                            trailing = const Chip(
                              label: Text('Completed'),
                              backgroundColor: Colors.green,
                            );
                          } else if (status == 'pending') {
                            trailing = const Chip(
                              label: Text('Pending'),
                              backgroundColor: Colors.orange,
                            );
                          } else if (status == 'confirmed') {
                            trailing = const Chip(
                              label: Text('Confirmed'),
                              backgroundColor: Colors.blue,
                            );
                          } else if (status == 'cancelled') {
                            trailing = const Chip(
                              label: Text('Cancelled'),
                              backgroundColor: Colors.red,
                            );
                          } else {
                            trailing = const SizedBox.shrink();
                          }
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Icon(
                                        Icons.work,
                                        color: Colors.orange,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              jobTitle,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Employer: $employerName',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(child: trailing),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    jobDescription,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.attach_money,
                                        size: 18,
                                        color: Colors.green,
                                      ),
                                      Text(
                                        'Amount: $amount',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.blueGrey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        startDateTime != null
                                            ? 'Start: ${startDateTime.toString().split(".")[0]}'
                                            : 'Start: N/A',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.update,
                                        size: 16,
                                        color: Colors.blueGrey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        updatedAt != null
                                            ? 'Updated: ${updatedAt.toString().split(".")[0]}'
                                            : 'Updated: N/A',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
