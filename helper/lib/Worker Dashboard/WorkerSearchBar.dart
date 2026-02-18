import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:helper/Worker%20Dashboard/Active_Job_detail.dart';

class WorkerSearchBar extends StatefulWidget {
  const WorkerSearchBar({Key? key}) : super(key: key);

  @override
  State<WorkerSearchBar> createState() => _WorkerSearchBarState();
}

class _WorkerSearchBarState extends State<WorkerSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  // Each suggestion: { 'jobName': String, 'bookingId': String }
  List<Map<String, dynamic>> _jobSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  Future<void> _fetchJobSuggestions(String input) async {
    final workerUid = FirebaseAuth.instance.currentUser?.uid;
    if (workerUid == null || input.trim().isEmpty) {
      setState(() {
        _jobSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('workerUid', isEqualTo: workerUid)
        .get();
    final jobs = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final jobName = (data['jobCategoryName'] ?? '').toString();
      if (jobName.toLowerCase().contains(input.trim().toLowerCase()) &&
          jobName.isNotEmpty) {
        jobs.add({'jobName': jobName, 'bookingId': doc.id});
      }
    }
    setState(() {
      _jobSuggestions = jobs;
      _showSuggestions = _jobSuggestions.isNotEmpty && _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 15, left: w * 0.05, right: w * 0.04),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 10),
                      Icon(Icons.search, color: Colors.black),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onChanged: (v) {
                            _debounce?.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 300),
                              () {
                                _fetchJobSuggestions(v);
                              },
                            );
                          },
                          decoration: InputDecoration(
                            hintText: 'Search for jobs here...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.black),
                          ),
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showSuggestions)
          Container(
            margin: EdgeInsets.only(left: w * 0.05, right: w * 0.04),
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _jobSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _jobSuggestions[index];
                return ListTile(
                  title: Text(
                    suggestion['jobName'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    _controller.text = suggestion['jobName'];
                    setState(() => _showSuggestions = false);
                    FocusScope.of(context).unfocus();
                    // Fetch booking data and navigate
                    final bookingDoc = await FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(suggestion['bookingId'])
                        .get();
                    final bookingData = bookingDoc.data();
                    if (bookingData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActiveJobScreen(
                            bookingId: suggestion['bookingId'],
                            bookingData: bookingData,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
