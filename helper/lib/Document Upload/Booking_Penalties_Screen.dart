import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingPenaltiesScreen extends StatefulWidget {
  const BookingPenaltiesScreen({Key? key}) : super(key: key);

  @override
  State<BookingPenaltiesScreen> createState() => _BookingPenaltiesScreenState();
}

class _BookingPenaltiesScreenState extends State<BookingPenaltiesScreen> {
  Future<double> _fetchTotalAmount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Penalties')
        .get();
    double total = 0;
    for (var doc in snapshot.docs) {
      final amount = doc.data()['amount'];
      if (amount is int) {
        total += amount.toDouble();
      } else if (amount is double) {
        total += amount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),

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
                          'No penalties to display.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
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
                top: screenHeight * 0.13 + 80, // further below the info box
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
                        'Total Amount:',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 6),
                      FutureBuilder<double>(
                        future: _fetchTotalAmount(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                      Container(
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Penalties'),
                                      content: FutureBuilder<QuerySnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('Penalties')
                                            .get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const SizedBox(
                                              height: 60,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          }
                                          if (snapshot.hasError) {
                                            return const Text(
                                              'Error loading penalties',
                                            );
                                          }
                                          final docs =
                                              snapshot.data?.docs ?? [];
                                          if (docs.isEmpty) {
                                            return const Text(
                                              'No penalties found.',
                                            );
                                          }
                                          return SizedBox(
                                            width: 300,
                                            child: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: docs.map((doc) {
                                                  final data =
                                                      doc.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  return Card(
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 6,
                                                        ),
                                                    child: ListTile(
                                                      title: Text(
                                                        data['title']
                                                                ?.toString() ??
                                                            'No Title',
                                                      ),
                                                      subtitle: Text(
                                                        data['description']
                                                                ?.toString() ??
                                                            '',
                                                      ),
                                                      trailing:
                                                          data['amount'] != null
                                                          ? Text(
                                                              'UGX ${data['amount']}',
                                                            )
                                                          : null,
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: const Text('Penalties'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // TODO: Implement Transaction button action
                              },
                              child: const Text('Transaction'),
                            ),
                          ],
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}
