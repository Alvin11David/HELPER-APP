import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PenaltyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> penalty;

  const PenaltyDetailScreen({super.key, required this.penalty});

  String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toString();
    }
    return _stringValue(value);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: h * 0.02),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: w * 0.13,
                        height: w * 0.13,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.chevron_left,
                            color: Colors.black,
                            size: w * 0.10,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.05),
                    Text(
                      'Penalty Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: w * 0.06,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: h * 0.03),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.05,
                        vertical: h * 0.02,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailRow(
                            label: 'Amount',
                            value: _stringValue(penalty['amount']),
                          ),
                          _DetailRow(
                            label: 'Booking ID',
                            value: _stringValue(penalty['bookingId']),
                          ),
                          _DetailRow(
                            label: 'Cancellation By',
                            value: _stringValue(
                              penalty['cancellationRequestedBy'],
                            ),
                          ),
                          _DetailRow(
                            label: 'Created At',
                            value: _formatTimestamp(penalty['createdAt']),
                          ),
                          _DetailRow(
                            label: 'Employer ID',
                            value: _stringValue(penalty['employerId']),
                          ),
                          _DetailRow(
                            label: 'Escrow ID',
                            value: _stringValue(penalty['escrowId']),
                          ),
                          _DetailRow(
                            label: 'Reason',
                            value: _stringValue(penalty['reason']),
                          ),
                          _DetailRow(
                            label: 'Worker UID',
                            value: _stringValue(penalty['workerUid']),
                          ),
                          _DetailRow(
                            label: 'Withdrawn',
                            value: _stringValue(penalty['withdraw']),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: h * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
