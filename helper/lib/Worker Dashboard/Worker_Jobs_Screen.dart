import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerJobsScreen extends StatelessWidget {
  const WorkerJobsScreen({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchWorkerJobs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final query = await FirebaseFirestore.instance
        .collection('bookings')
        .where('workerId', isEqualTo: user.uid)
        .where('status', whereIn: ['completed', 'completed_pending'])
        .orderBy('updatedAt', descending: true)
        .get();
    return query.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Completed Jobs')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchWorkerJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No completed jobs found.'));
          }
          final jobs = snapshot.data!;
          return ListView.separated(
            itemCount: jobs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final job = jobs[index];
              final title = job['jobTitle'] ?? 'Job';
              final employerName = job['employerName'] ?? 'Employer';
              final completedAt = (job['updatedAt'] as Timestamp?)?.toDate();
              return ListTile(
                leading: const Icon(Icons.work, color: Colors.orange),
                title: Text(title),
                subtitle: Text(
                  'Employer: $employerName\nCompleted: '
                  '${completedAt != null ? completedAt.toString().split(".")[0] : 'N/A'}',
                ),
                trailing: job['status'] == 'completed_pending'
                    ? const Chip(
                        label: Text('Pending Code'),
                        backgroundColor: Colors.amber,
                      )
                    : const Chip(
                        label: Text('Completed'),
                        backgroundColor: Colors.green,
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
