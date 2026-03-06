import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helper/Wallet/Penalties_Wallet_Screen.dart';
import 'package:helper/Document Upload/Penalty_Detail_Screen.dart';

class BookingPenaltiesScreen extends StatefulWidget {
  const BookingPenaltiesScreen({super.key});

  @override
  State<BookingPenaltiesScreen> createState() => _BookingPenaltiesScreenState();
}

class _BookingPenaltiesScreenState extends State<BookingPenaltiesScreen> {
  double _contentHeight(double screenHeight) {
    const double listItemHeight = 120.0;
    const double listFallbackHeight = 80.0;
    final double listHeight;

    if (_penaltiesSelected) {
      if (_loadingPenalties) {
        listHeight = listFallbackHeight;
      } else if (_penaltiesDocs.isEmpty) {
        listHeight = listFallbackHeight;
      } else {
        listHeight = _penaltiesDocs.length * listItemHeight;
      }
    } else if (_registrationFeeSelected) {
      if (_loadingRegistrationFee) {
        listHeight = listFallbackHeight;
      } else if (_registrationFeeDocs.isEmpty) {
        listHeight = listFallbackHeight;
      } else {
        listHeight = _registrationFeeDocs.length * listItemHeight;
      }
    } else {
      listHeight = 0;
    }

    final double baseTop =
        screenHeight * 0.13 + 80 + 180 + 16 + 60; // buttons + spacing
    final double contentHeight = baseTop + listHeight;

    return math.max(screenHeight, contentHeight);
  }

  Future<double> _fetchTotalAmount() async {
    if (_registrationFeeSelected) {
      // Return registration fee total
      final snapshot = await FirebaseFirestore.instance
          .collection('Payment Data')
          .where('paymentPurpose', isEqualTo: 'REGISTRATION_FEE')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = data['amount'];
        if (amount is int) {
          total += amount.toDouble();
        } else if (amount is double) {
          total += amount;
        }
      }
      return total;
    } else {
      // Return penalties total (existing logic)
      final snapshot = await FirebaseFirestore.instance
          .collection('Penalties')
          .get();
      double total = 0;
      double withdrawn = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = data['amount'];
        final isWithdrawn = data['withdraw'] == true;
        double amt = 0;
        if (amount is int) {
          amt = amount.toDouble();
        } else if (amount is double) {
          amt = amount;
        }
        if (isWithdrawn) {
          withdrawn += amt;
        } else {
          total += amt;
        }
      }
      return total - withdrawn;
    }
  }

  bool _penaltiesSelected = false;
  bool _loadingPenalties = false;
  List<Map<String, dynamic>> _penaltiesDocs = [];

  bool _registrationFeeSelected = false;
  bool _loadingRegistrationFee = false;
  List<Map<String, dynamic>> _registrationFeeDocs = [];
  double _totalRegistrationFee = 0.0;

  Future<void> _fetchPenaltiesDocs() async {
    setState(() {
      _loadingPenalties = true;
    });
    final snapshot = await FirebaseFirestore.instance
        .collection('Penalties')
        .get();
    setState(() {
      _penaltiesDocs = snapshot.docs.map((doc) => doc.data()).toList();
      _loadingPenalties = false;
    });
  }

  Future<void> _fetchRegistrationFeeTotal() async {
    setState(() {
      _loadingRegistrationFee = true;
    });
    final snapshot = await FirebaseFirestore.instance
        .collection('Payment Data')
        .where('paymentPurpose', isEqualTo: 'REGISTRATION_FEE')
        .get();

    double total = 0;
    final docs = snapshot.docs.map((doc) => doc.data()).toList();

    for (var data in docs) {
      final amount = data['amount'];
      if (amount is int) {
        total += amount.toDouble();
      } else if (amount is double) {
        total += amount;
      }
    }

    setState(() {
      _registrationFeeDocs = docs;
      _totalRegistrationFee = total;
      _loadingRegistrationFee = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
            child: SizedBox(
              height: _contentHeight(screenHeight),
              child: Stack(
                children: [
                  // Header with chevron and title
                  Positioned(
                    top: screenHeight * 0.04,
                    left: screenWidth * 0.04,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: screenWidth * 0.13,
                            height: screenWidth * 0.13,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.chevron_left,
                                color: Colors.black,
                                size: screenWidth * 0.10,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.06),
                        Text(
                          'Booking Penalties',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Glassmorphic info box
                  Positioned(
                    top: screenHeight * 0.13,
                    left: screenWidth * 0.10,
                    right: screenWidth * 0.10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.005,
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
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              ' View and manage your booking penalties here.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.03,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // White rectangle with Total Amount and Withdraw button inside
                  Positioned(
                    top: screenHeight * 0.13 + 70, // further below the info box
                    left: screenWidth * 0.08,
                    right: screenWidth * 0.08,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _registrationFeeSelected
                                ? 'Total Registration Fees:'
                                : 'Total Amount:',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 6),
                          FutureBuilder<double>(
                            key: ValueKey(
                              '${_penaltiesSelected}_${_registrationFeeSelected}',
                            ),
                            future: _fetchTotalAmount(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return const Text(
                                  'Error',
                                  style: TextStyle(color: Colors.red),
                                );
                              }
                              return Text(
                                snapshot.data != null
                                    ? snapshot.data!.toStringAsFixed(2)
                                    : '0.00',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.032,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Montserrat',
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PenaltiesWalletScreen(
                                    fundType: _registrationFeeSelected
                                        ? 'registration_fees'
                                        : 'penalties',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.arrow_downward,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Withdraw',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Montserrat',
                            ),
                          ),

                          // ...existing code...
                          // Row of buttons below the white rectangle
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top:
                        screenHeight * 0.13 +
                        80 +
                        180 +
                        16, // below the white rectangle with spacing
                    left: screenWidth * 0.08,
                    right: screenWidth * 0.08,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _penaltiesSelected
                                    ? Colors.orange
                                    : null,
                              ),
                              onPressed: () async {
                                setState(() {
                                  _penaltiesSelected = true;
                                  _registrationFeeSelected = false;
                                });
                                await _fetchPenaltiesDocs();
                              },
                              child: const Text('Penalties'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _registrationFeeSelected
                                    ? Colors.orange
                                    : null,
                              ),
                              onPressed: () async {
                                setState(() {
                                  _penaltiesSelected = false;
                                  _registrationFeeSelected = true;
                                });
                                await _fetchRegistrationFeeTotal();
                              },
                              child: const Text('Registration Fee'),
                            ),
                          ],
                        ),
                        if (_penaltiesSelected)
                          _loadingPenalties
                              ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                )
                              : _penaltiesDocs.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'No penalties found.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : Column(
                                  children: _penaltiesDocs
                                      .map(
                                        (data) => Card(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 1,
                                            horizontal: 0,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PenaltyDetailScreen(
                                                        penalty: data,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 2.0,
                                                    horizontal: 6.0,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Amount: ${data['amount'] ?? ''}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Booking ID: ${data['bookingId'] ?? ''}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Cancellation By: ${data['cancellationRequestedBy'] ?? ''}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Created At: ${data['createdAt'] != null ? data['createdAt'].toDate().toString() : ''}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Employer ID: ${data['employerId'] ?? ''}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Escrow ID: ${data['escrowId'] ?? ''}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Reason: ${data['reason'] ?? ''}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Worker UID: ${data['workerUid'] ?? ''}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                )
                        else if (_registrationFeeSelected)
                          _loadingRegistrationFee
                              ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                )
                              : _registrationFeeDocs.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'No registration fees found.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              : Column(
                                  children: _registrationFeeDocs
                                      .map(
                                        (data) => Card(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 1,
                                            horizontal: 0,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text(
                                                    'Registration Fee Details',
                                                  ),
                                                  content: SingleChildScrollView(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'Amount: ${data['amount'] ?? ''}',
                                                        ),
                                                        Text(
                                                          'Payment Purpose: ${data['paymentPurpose'] ?? ''}',
                                                        ),
                                                        Text(
                                                          'User ID: ${data['userId'] ?? ''}',
                                                        ),
                                                        Text(
                                                          'Payment Method: ${data['paymentMethod'] ?? ''}',
                                                        ),
                                                        Text(
                                                          'Transaction ID: ${data['transactionId'] ?? ''}',
                                                        ),
                                                        Text(
                                                          'Created At: ${data['createdAt'] != null ? data['createdAt'].toDate().toString() : ''}',
                                                        ),
                                                        if (data['description'] !=
                                                            null)
                                                          Text(
                                                            'Description: ${data['description']}',
                                                          ),
                                                        if (data['status'] !=
                                                            null)
                                                          Text(
                                                            'Status: ${data['status']}',
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                      child: const Text(
                                                        'Close',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 2.0,
                                                    horizontal: 6.0,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Amount: ${data['amount'] ?? ''}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Payment Purpose: ${data['paymentPurpose'] ?? ''}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'User ID: ${data['userId'] ?? ''}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Created At: ${data['createdAt'] != null ? data['createdAt'].toDate().toString() : ''}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Payment Method: ${data['paymentMethod'] ?? ''}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Transaction ID: ${data['transactionId'] ?? ''}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
