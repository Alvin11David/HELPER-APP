import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:helper/Worker%20Dashboard/Active_Job_detail.dart';

class WorkerSearchBar extends StatefulWidget {
  const WorkerSearchBar({super.key});

  @override
  State<WorkerSearchBar> createState() => _WorkerSearchBarState();
}

class _WorkerSearchBarState extends State<WorkerSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  // Each result: { 'bookingId': String, 'data': Map<String, dynamic> }
  List<Map<String, dynamic>> _results = [];
  bool _showResults = false;
  bool _loading = false;

  static const _statuses = ['pending', 'confirmed', 'started', 'in_progress'];

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        if (mounted) setState(() => _showResults = false);
      } else {
        // When tapped/focused, show bookings immediately
        _runSearch(_controller.text);
      }
    });
  }

  String _formatStart(dynamic startDt) {
    DateTime? dt;
    if (startDt is Timestamp) dt = startDt.toDate();
    if (startDt is DateTime) dt = startDt;
    if (dt == null) return 'No date';

    return DateFormat('MMM d • h:mm a').format(dt);
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'pending') return Colors.orange;
    if (s == 'confirmed') return Colors.blue;
    if (s == 'started' || s == 'in_progress') return Colors.green;
    return Colors.black54;
  }

  Future<List<Map<String, dynamic>>> _fetchWorkerBookings() async {
    final workerUid = FirebaseAuth.instance.currentUser?.uid;
    if (workerUid == null) return [];

    // Pull only relevant statuses and limit results
    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('workerUid', isEqualTo: workerUid)
        .where('status', whereIn: _statuses)
        .orderBy('updatedAt', descending: true)
        .limit(40)
        .get();

    return snap.docs
        .map((doc) => {'bookingId': doc.id, 'data': doc.data()})
        .toList();
  }

  bool _matchesQuery(Map<String, dynamic> booking, String q) {
    if (q.isEmpty) return true;

    final category = (booking['jobCategoryName'] ?? '').toString().toLowerCase();
    final employer = (booking['employerName'] ?? '').toString().toLowerCase();
    final location =
        (booking['jobLocationText'] ?? '').toString().toLowerCase();

    return category.contains(q) || employer.contains(q) || location.contains(q);
  }

  Future<void> _runSearch(String input) async {
    final q = input.trim().toLowerCase();

    // If user not logged in, hide results
    if (FirebaseAuth.instance.currentUser?.uid == null) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _showResults = true;
    });

    try {
      final all = await _fetchWorkerBookings();
      final filtered = all.where((item) {
        final data = item['data'] as Map<String, dynamic>;
        return _matchesQuery(data, q);
      }).toList();

      if (!mounted) return;
      setState(() {
        _results = filtered;
        _showResults = _focusNode.hasFocus;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _showResults = _focusNode.hasFocus;
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _runSearch(v);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 15, left: w * 0.05, right: w * 0.04),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(Icons.search, color: Colors.black),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onChanged,
                    onTap: () => _runSearch(_controller.text),
                    decoration: const InputDecoration(
                      hintText: 'Search bookings (e.g. Accounting, Employer, Location)...',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      _controller.clear();
                      _runSearch('');
                    },
                  ),
              ],
            ),
          ),
        ),

        if (_showResults)
          Container(
            margin: EdgeInsets.only(left: w * 0.05, right: w * 0.04, top: 8),
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : (_results.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: Center(
                          child: Text(
                            'No matching bookings found',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _results.length.clamp(0, 10),
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final bookingId = item['bookingId'] as String;
                          final data = item['data'] as Map<String, dynamic>;

                          final category =
                              (data['jobCategoryName'] ?? 'Job').toString();
                          final employer =
                              (data['employerName'] ?? 'Employer').toString();
                          final location = (data['jobLocationText'] ?? 'Unknown')
                              .toString();
                          final status = (data['status'] ?? '').toString();
                          final dateStr = _formatStart(data['startDateTime']);

                          return ListTile(
                            title: Text(
                              '$category • $employer',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '$location • $dateStr',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              status,
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() => _showResults = false);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ActiveJobScreen(
                                    bookingId: bookingId,
                                    bookingData: data,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )),
          ),
      ],
    );
  }
}
