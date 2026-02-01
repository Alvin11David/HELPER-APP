import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:helper/Components/Bottom_Nav_Bar.dart'; // Add this import for ImageFilter

class WorkerRatingsReviewsScreen extends StatefulWidget {
  const WorkerRatingsReviewsScreen({super.key});

  @override
  State<WorkerRatingsReviewsScreen> createState() =>
      _WorkerRatingsReviewsScreenState();
}

class _WorkerRatingsReviewsScreenState
    extends State<WorkerRatingsReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  Map<String, double> _ratingProgress = {
    '5 stars': 0.0,
    '4 stars': 0.0,
    '3 stars': 0.0,
    '2 stars': 0.0,
    '1 star': 0.0,
  };
  double _overallRating = 0.0;

  @override
  void initState() {
    super.initState();

    // Show current user info on screen
    final uid = FirebaseAuth.instance.currentUser?.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('👤 Current User UID: $uid'),
          duration: const Duration(seconds: 3),
        ),
      );
      // Show user email if available
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📧 User Email: ${user.email ?? "No email"}'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    });

    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      // Show error snackbar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ No user logged in'),
            duration: Duration(seconds: 3),
          ),
        );
      });
      return;
    }

    print('Current user UID: ${user.uid}'); // Debug print

    try {
      // TEMPORARY: Remove orderBy to avoid index requirement
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Reviews')
          .where('providerId', isEqualTo: user.uid)
          // .orderBy('timestamp', descending: true)  // Temporarily removed
          .get();

      // Sort in memory instead
      final docs = querySnapshot.docs;
      docs.sort((a, b) {
        final aTime = a.data()['timestamp'] as Timestamp?;
        final bTime = b.data()['timestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Descending order
      });

      print(
        'Found ${docs.length} reviews for user ${user.uid} (sorted in memory)',
      ); // Debug print

      // Show results in snackbar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔍 Found ${docs.length} reviews (memory sorted)'),
            duration: const Duration(seconds: 3),
          ),
        );
      });

      final reviews = docs.map((doc) {
        final data = doc.data();
        print('Review data: $data'); // Debug print
        return {
          'name': data['reviewerName'] ?? 'Anonymous',
          'rating': data['rating'] ?? 0,
          'review': data['reviewText'] ?? '',
          'date': _formatDate(data['timestamp'] as Timestamp?),
          'providerId':
              data['providerId'] ?? 'Unknown', // Add providerId for debugging
        };
      }).toList();

      // Calculate rating distribution
      final ratingCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      double totalRating = 0;

      for (final review in reviews) {
        final rating = review['rating'] as int;
        ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
        totalRating += rating;
      }

      final totalReviews = reviews.length;
      if (totalReviews > 0) {
        _overallRating = totalRating / totalReviews;
        _ratingProgress = {
          '5 stars': ratingCounts[5]! / totalReviews,
          '4 stars': ratingCounts[4]! / totalReviews,
          '3 stars': ratingCounts[3]! / totalReviews,
          '2 stars': ratingCounts[2]! / totalReviews,
          '1 star': ratingCounts[1]! / totalReviews,
        };
      }

      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching reviews: $e');
      setState(() => _isLoading = false);

      // Show error in snackbar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error fetching reviews: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/normalscreenbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
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
                    'Reviews & Ratings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: screenHeight * 0.12, // Adjust position below the header
              left: 0,
              right: 0,
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06,
                            vertical: screenHeight * 0.006,
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
                          child: Text(
                            'Ratings affect your visibility and job\nopportunities.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: screenHeight * 0.25, // Position for the reviews list
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              height: screenHeight * 0.23, // Reduced height for the scroll area
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: screenWidth * 0.04),
                      child: Text(
                        'Review List',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : _reviews.isEmpty
                        ? Center(
                            child: Text(
                              'No reviews yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return Container(
                                width:
                                    screenWidth *
                                    0.8, // Fixed width for each card
                                height:
                                    screenHeight *
                                    0.15, // Adjusted height for each card
                                margin: EdgeInsets.only(
                                  right: screenWidth * 0.04,
                                ),
                                padding: EdgeInsets.all(screenWidth * 0.04),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: screenWidth * 0.06,
                                          backgroundColor: Colors.white
                                              .withOpacity(0.3),
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: screenWidth * 0.06,
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.03),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                review['name'],
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.045,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (starIndex) => Icon(
                                                    starIndex < review['rating']
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: Colors.yellow,
                                                    size: screenWidth * 0.04,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          review['date'],
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            fontSize: screenWidth * 0.035,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Expanded(
                                      child: Text(
                                        review['review'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.04,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: screenHeight * 0.5, // Fixed top position
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              height:
                  screenHeight * 0.25, // Increased height to prevent overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Rating',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Row(
                        children: [
                          // Left column: Rating details
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                Text(
                                  _overallRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    5,
                                    (index) => Icon(
                                      Icons.star,
                                      color: Colors.orange,
                                      size: screenWidth * 0.06,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_reviews.length} reviews',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.04,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          // Right column: Rating progress bars
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _ratingProgress.entries.map((entry) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        screenHeight * 0.005, // Reduced padding
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        entry.key,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize:
                                              screenWidth *
                                              0.035, // Smaller font
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Expanded(
                                        child: SizedBox(
                                          height:
                                              screenHeight *
                                              0.01, // Fixed height for bars
                                          child: LinearProgressIndicator(
                                            value: entry.value,
                                            backgroundColor: Colors.grey
                                                .withOpacity(0.3),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.orange,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 4),
    );
  }
}
