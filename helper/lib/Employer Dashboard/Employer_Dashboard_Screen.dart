import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:helper/Components/User_Name.dart';
import 'package:helper/Components/Side_Bar.dart';
import 'package:helper/Components/UnreadMessagesBadge.dart';
import 'package:helper/Employer%20Dashboard/Category_Providers_Screen.dart';
import 'package:helper/Worker%20Dashboard/Worker_Details_Screen.dart';
import '../Components/Bottom_Nav_Bar.dart';
import 'All_Categories_Screen.dart';
import 'NearYouProvidersScreen.dart';
import 'ForYouProvidersScreen.dart';

class EmployerDashboardScreen extends StatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  State<EmployerDashboardScreen> createState() =>
      _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<SideBarState> _sidebarKey = GlobalKey();

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });
    // Add navigation or logic here if needed
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  late FocusNode _focusNode;
  late TextEditingController _controller;
  Timer? _debounce;
  bool _searching = false;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _searchResults = [];

  Position? _currentPos;
  bool _locLoading = false;
  String? _locError;

  Future<QuerySnapshot<Map<String, dynamic>>>? _forYouFuture;
  Future<QuerySnapshot<Map<String, dynamic>>>? _nearYouFuture;

  bool _showFilters = false;
  String? selectedFilter;
  Position? userPosition;
  List<String> topRatedCategories = [];
  Map<String, double> categoryRatings = {};
  Map<String, double> providerRatings = {};
  bool _ratingsLoaded = false;

  bool get _hasQuery => _controller.text.trim().length >= 2;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _searchResults = []);
      }
    });

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

    _initLocation(); // ✅ start GPS
    _getUserPosition();
    _getTopRatedCategories();
    _getCategoryRatings().then((map) {
      setState(() {
        categoryRatings = map;
        _ratingsLoaded = true;
      });
    });

    // On entry, process any pending reschedule requests and block dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processPendingRescheduleNotifications();
      _listenForRescheduleNotifications();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _listenForRescheduleNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snap) {
          for (final doc in snap.docs) {
            final d = doc.data();
            if (d['type'] == 'reschedule_request') {
              _showReschedulePopup(
                context,
                notifId: doc.id,
                bookingId: d['bookingId'],
              );
              break; // show one at a time
            }
          }
        });
  }

  Future<void> _showReschedulePopup(
    BuildContext context, {
    required String notifId,
    required String bookingId,
  }) async {
    final bookingSnap = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .get();
    final b = bookingSnap.data() ?? {};

    final res = (b['reschedule'] ?? {}) as Map<String, dynamic>;
    final proposedStart = (res['proposedStart'] as Timestamp).toDate();
    final proposedEnd = (res['proposedEnd'] as Timestamp).toDate();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reschedule Request"),
        content: Text("Worker proposes:\n$proposedStart\nto\n$proposedEnd"),
        actions: [
          TextButton(
            onPressed: () async {
              // decline -> mark as cancelled and record decision
              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .update({
                    'reschedule.employerDecision': 'declined',
                    'reschedule.decidedAt': FieldValue.serverTimestamp(),
                    'status': 'cancelled',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(notifId)
                  .update({'read': true});
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Decline"),
          ),
          ElevatedButton(
            onPressed: () async {
              // accept -> replace booking times with proposed
              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .update({
                    'startDateTime': Timestamp.fromDate(proposedStart),
                    'endDateTime': Timestamp.fromDate(proposedEnd),
                    'reschedule.employerDecision': 'accepted',
                    'reschedule.decidedAt': FieldValue.serverTimestamp(),
                    'status': 'confirmed',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(notifId)
                  .update({'read': true});
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }

  Future<void> _processPendingRescheduleNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .where('type', isEqualTo: 'reschedule_request')
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final bookingId = (data['bookingId'] ?? '').toString();
      if (bookingId.isEmpty) continue;
      await _showReschedulePopup(context, notifId: doc.id, bookingId: bookingId);
    }
  }

  Future<void> _initLocation() async {
    setState(() {
      _locLoading = true;
      _locError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are OFF. Turn on GPS.");
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception(
          "Location permission denied forever. Enable it in settings.",
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() => _currentPos = pos);

      // OPTIONAL: keep updating live while employer moves
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20, // update when moved 20 meters
        ),
      ).listen((p) {
        if (!mounted) return;
        setState(() => _currentPos = p);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locError = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _locLoading = false);
    }
  }

  double _kmFromCurrent(GeoPoint workerPoint) {
    final p = _currentPos!;
    final meters = Geolocator.distanceBetween(
      p.latitude,
      p.longitude,
      workerPoint.latitude,
      workerPoint.longitude,
    );
    return meters / 1000.0;
  }

  Future<void> _runSearch(String input) async {
    final q = input.trim().toLowerCase();
    if (q.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _searching = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('serviceProviders')
          .where('isActive', isEqualTo: true)
          .where('onboardingStep', isEqualTo: 'skills_job_details_done')
          .limit(200)
          .get();

      final filtered = snap.docs.where((d) {
        final data = d.data();
        final businessName = (data['businessName'] ?? '')
            .toString()
            .toLowerCase();
        final jobCategoryId = (data['jobCategoryId'] ?? '')
            .toString()
            .toLowerCase();
        final jobCategoryName = (data['jobCategoryName'] ?? '')
            .toString()
            .toLowerCase();
        final workplaceLocationText = (data['workplaceLocationText'] ?? '')
            .toString()
            .toLowerCase();
        return businessName.contains(q) ||
            jobCategoryId.contains(q) ||
            jobCategoryName.contains(q) ||
            workplaceLocationText.contains(q);
      }).toList();

      setState(() => _searchResults = filtered.take(10).toList());
    } catch (e) {
      // ignore: avoid_print
      print("Search error: $e");
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Widget _providerCard(double w, Map<String, dynamic> d) {
    final businessName = (d['businessName'] ?? 'Unknown').toString();
    final job = (d['jobCategoryName'] ?? '').toString();
    final pricingType = (d['pricingType'] ?? '').toString();
    final amount = d['amount'];

    final files = d['portfolioFiles'];
    String img = '';
    if (files is List && files.isNotEmpty && files.last is String) {
      img = files.last;
    }

    final amountText = (amount is num)
        ? NumberFormat('#,###').format(amount.toInt())
        : amount.toString();

    final dist = d['_distanceKm'];
    final distText = (dist is num) ? "${dist.toStringAsFixed(1)} km" : "";
    final docId = (d['_docId'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
              WorkerDetailsScreen(providerId: docId, data: d, workerId: ''),
          ),
        );
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: img.isNotEmpty
                ? Image.network(
                    img,
                    width: w * 0.6,
                    height: w * 0.8,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: w * 0.6,
                    height: w * 0.8,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image),
                  ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: w * 0.26,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: w * 0.025,
                  left: w * 0.02,
                  right: w * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      job.isEmpty ? 'Service Provider' : job,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black, fontSize: 13),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$amountText ${pricingType.isNotEmpty ? "/ $pricingType" : ""}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (distText.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                distText,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotifications() async {
    print('Notifications tapped');
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view notifications')),
      );
      return;
    }

    // For employer dashboard, receiver is employer
    bool isEmployer = true;

    List<String> notifications = [];
    try {
      // Fetch unread messages
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final read = data['read'] as bool? ?? false;
        if (read) continue; // skip read messages

        final senderId = data['senderId'] as String?;
        if (senderId == null) continue;

        String name = '';
        if (isEmployer) {
          // Sender is worker, from Sign Up
          final senderDoc = await FirebaseFirestore.instance
              .collection('Sign Up')
              .doc(senderId)
              .get();
          if (senderDoc.exists) {
            final senderData = senderDoc.data();
            name = senderData?['fullName'] ?? '';
          }
        }
        if (name.isNotEmpty) {
          notifications.add('You have a message from $name');
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: notifications.isEmpty
                    ? const Center(child: Text('No new notifications'))
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          return ListTile(title: Text(notifications[index]));
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getUserPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Handle if location services are disabled
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle denied permission
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Handle permanently denied
      return;
    }

    userPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _getTopRatedCategories() async {
    try {
      // Get all reviews from subcollections
      QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('Reviews')
          .get();

      // Group ratings by providerId
      Map<String, List<double>> ratingsByProvider = {};
      for (var doc in reviewsSnapshot.docs) {
        String providerId = doc['providerId'] ?? '';
        double rating = (doc['rating'] ?? 0).toDouble();
        if (providerId.isNotEmpty) {
          ratingsByProvider.putIfAbsent(providerId, () => []).add(rating);
        }
      }

      // Calculate average ratings
      Map<String, double> avgRatings = {};
      ratingsByProvider.forEach((providerId, ratings) {
        double avg = ratings.reduce((a, b) => a + b) / ratings.length;
        avgRatings[providerId] = avg;
      });

      // Get providers with avg rating >= 4.0
      Set<String> topRatedProviderIds = avgRatings.entries
          .where((entry) => entry.value >= 4.0)
          .map((entry) => entry.key)
          .toSet();

      // Get their categories
      Set<String> categories = {};
      for (var providerId in topRatedProviderIds) {
        DocumentSnapshot providerDoc = await FirebaseFirestore.instance
            .collection('serviceProviders')
            .doc(providerId)
            .get();
        String category = providerDoc['jobCategoryName'] ?? '';
        if (category.isNotEmpty) {
          categories.add(category);
        }
      }

      setState(() {
        topRatedCategories = categories.toList();
      });
    } catch (e) {
      print('Error getting top rated categories: $e');
    }
  }

  Future<Map<String, double>> _getCategoryRatings() async {
    try {
      // Get all reviews from subcollections
      QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('Reviews')
          .get();

      // Group ratings by providerId
      Map<String, List<double>> ratingsByProvider = {};
      for (var doc in reviewsSnapshot.docs) {
        String providerId = doc['providerId'] ?? '';
        double rating = (doc['rating'] ?? 0).toDouble();
        if (providerId.isNotEmpty) {
          ratingsByProvider.putIfAbsent(providerId, () => []).add(rating);
        }
      }

      // Calculate average ratings per provider
      Map<String, double> providerAvgs = {};
      ratingsByProvider.forEach((providerId, ratings) {
        double avg = ratings.reduce((a, b) => a + b) / ratings.length;
        providerAvgs[providerId] = avg;
      });

      // Group by category
      Map<String, List<double>> categoryRatingsMap = {};
      for (var providerId in providerAvgs.keys) {
        DocumentSnapshot providerDoc = await FirebaseFirestore.instance
            .collection('serviceProviders')
            .doc(providerId)
            .get();
        String category = providerDoc['jobCategoryName'] ?? '';
        if (category.isNotEmpty) {
          categoryRatingsMap
              .putIfAbsent(category, () => [])
              .add(providerAvgs[providerId]!);
        }
      }

      // Calculate average per category
      Map<String, double> result = {};
      categoryRatingsMap.forEach((category, ratings) {
        double avg = ratings.reduce((a, b) => a + b) / ratings.length;
        result[category] = avg;
      });

      // Store provider ratings for filtering
      setState(() {
        providerRatings = Map.from(providerAvgs);
      });

      print('Provider ratings populated: $providerRatings');

      return result;
    } catch (e) {
      print('Error getting category ratings: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            child: SizedBox(
              height: 1500,
              child: Stack(
                children: [
                  Positioned(
                    top: 20,
                    right: w * 0.04,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.black),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _showNotifications,
                          child: Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications,
                                  color: Colors.black,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: UnreadMessagesBadge(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 75,
                    right: w * 0.04,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 40,
                          width: w * 0.76,
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
                                    final trimmed = v.trim();
                                    _debounce?.cancel();
                                    _debounce = Timer(
                                      const Duration(milliseconds: 300),
                                      () {
                                        if (trimmed.length >= 2) {
                                          _runSearch(trimmed);
                                        } else {
                                          setState(() => _searchResults = []);
                                        }
                                      },
                                    );
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Search for services here...',
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showFilters = !_showFilters),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.tune, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    top: _showFilters ? 130 : 175,
                    left: _showFilters ? w * 0.04 : -500,
                    child: SizedBox(
                      width: w - 2 * w * 0.04,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            4,
                            (index) => GestureDetector(
                              onTap: () async {
                                setState(() {
                                  selectedFilter = index == 0
                                      ? 'Nearest'
                                      : index == 1
                                      ? 'Top Rated'
                                      : index == 2
                                      ? 'Available'
                                      : null;
                                });
                                _nearYouFuture = null;
                                _forYouFuture = null;
                                if (index == 0 && userPosition == null) {
                                  await _getUserPosition();
                                  setState(() {});
                                }
                              },
                              child: Container(
                                width: 100,
                                height: 40,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color:
                                      (index == 0 &&
                                              selectedFilter == 'Nearest') ||
                                          (index == 1 &&
                                              selectedFilter == 'Top Rated') ||
                                          (index == 2 &&
                                              selectedFilter == 'Available')
                                      ? Colors.blue[100]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: index == 0
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.black,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Nearest',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : index == 1
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.orange,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Top Rated',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : index == 2
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              color: Colors.black,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Available',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    top: _showFilters ? 175 : 125,
                    left: w * 0.04,
                    right: w * 0.04,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: Color(0xFFF79F1A),
                              fontSize: w * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    top: _showFilters ? 210 : 160,
                    left: w * 0.04,
                    right: w * 0.04,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryProvidersScreen(
                                  categoryName: 'House',
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.home,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'House',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryProvidersScreen(
                                  categoryName: 'Electricity',
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lightbulb,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Electricity',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryProvidersScreen(
                                  categoryName: 'Driver',
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Driver',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryProvidersScreen(
                                  categoryName: 'Plumber',
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.plumbing,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Plumber',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllCategoriesScreen(),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'More',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    top: _showFilters ? 290 : 240,
                    left: w * 0.04,
                    right: w * 0.04,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Near You',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NearYouProvidersScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Text(
                              'View All',
                              style: TextStyle(
                                color: Color(0xFFF79F1A),
                                fontSize: w * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    top: _showFilters ? 330 : 280,
                    left: w * 0.04,
                    right: 0,
                    child: SizedBox(
                      height: w * 0.8,
                      child: Builder(
                        builder: (_) {
                          if (_locLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (_locError != null) {
                            return Center(
                              child: Text(
                                _locError!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }
                          if (_currentPos == null) {
                            return const Center(
                              child: Text(
                                "Getting your location...",
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }

                          _nearYouFuture ??= FirebaseFirestore.instance
                              .collection('serviceProviders')
                              .where('isActive', isEqualTo: true)
                              .where(
                                'onboardingStep',
                                isEqualTo: 'skills_job_details_done',
                              )
                              .orderBy('updatedAt', descending: true)
                              .limit(
                                250,
                              ) // fetch enough then sort locally by distance
                              .get();
                          return FutureBuilder<
                            QuerySnapshot<Map<String, dynamic>>
                          >(
                            future: _nearYouFuture,
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snap.hasError) {
                                return Center(
                                  child: Text(
                                    "Error: ${snap.error}",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }
                              if (!snap.hasData ||
                                  snap.data == null ||
                                  snap.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    "No nearby providers found",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              final docs = snap.data!.docs;

                              // OPTIONAL geofence radius (km). Set to null to show all.
                              const double radiusKm =
                                  15; // change to 5, 10, 20 etc

                              // build list with distances
                              final scored = <Map<String, dynamic>>[];

                              for (final doc in docs) {
                                final d = doc.data();
                                final gp = d['workplaceLatLng'];
                                if (gp is! GeoPoint) continue;

                                if (_currentPos == null) continue;

                                final km = _kmFromCurrent(gp);

                                if (km > radiusKm) continue;

                                scored.add({
                                  ...d,
                                  '_distanceKm': km,
                                  '_docId': doc.id,
                                });
                              }

                              if (_ratingsLoaded &&
                                  selectedFilter == 'Top Rated') {
                                print(
                                  'Applying Top Rated filter. Provider ratings: $providerRatings',
                                );
                                scored.retainWhere(
                                  (s) =>
                                      (providerRatings[s['_docId']] ?? 0) >=
                                      4.0,
                                );
                                print(
                                  'After filtering, scored length: ${scored.length}',
                                );
                              }

                              // sort shortest distance first
                              scored.sort((a, b) {
                                final ak = (a['_distanceKm'] as num).toDouble();
                                final bk = (b['_distanceKm'] as num).toDouble();
                                return ak.compareTo(bk);
                              });

                              if (scored.isEmpty) {
                                return const Center(
                                  child: Text(
                                    "No nearby providers found",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              final show = scored.take(10).toList();

                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.only(right: w * 0.04),
                                itemCount: show.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(width: w * 0.05),
                                itemBuilder: (_, i) =>
                                    _providerCard(w, show[i]),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    top: _showFilters ? 330 + w * 0.8 + 20 : 280 + w * 0.8 + 20,
                    left: w * 0.04,
                    right: w * 0.04,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'For You',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForYouProvidersScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Text(
                              'View All',
                              style: TextStyle(
                                color: Color(0xFFF79F1A),
                                fontSize: w * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    top: _showFilters ? 330 + w * 0.8 + 60 : 280 + w * 0.8 + 60,
                    left: w * 0.04,
                    right: 0,
                    child: SizedBox(
                      height: w * 0.8,
                      child: Builder(
                        builder: (context) {
                          _forYouFuture ??= FirebaseFirestore.instance
                              .collection('serviceProviders')
                              .where('isActive', isEqualTo: true)
                              .where(
                                'onboardingStep',
                                isEqualTo: 'skills_job_details_done',
                              )
                              .orderBy('updatedAt', descending: true)
                              .limit(
                                250,
                              ) // fetch enough then sort locally by distance if needed
                              .get();
                          return FutureBuilder<
                            QuerySnapshot<Map<String, dynamic>>
                          >(
                            future: _forYouFuture,
                            builder: (context, snap) {
                              if (snap.hasError) {
                                return Center(
                                  child: Text(
                                    "Firestore error: ${snap.error}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snap.hasData ||
                                  snap.data == null ||
                                  snap.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text("No providers yet"),
                                );
                              }

                              final docs = snap.data!.docs;

                              List<Map<String, dynamic>> show;
                              if (selectedFilter == 'Nearest' &&
                                  _currentPos != null) {
                                // Filter by distance
                                final scored = <Map<String, dynamic>>[];
                                for (final doc in docs) {
                                  final d = doc.data();
                                  final gp = d['workplaceLatLng'];
                                  if (gp is! GeoPoint) continue;
                                  final km = _kmFromCurrent(gp);
                                  if (km <= 5) {
                                    scored.add({
                                      ...d,
                                      '_distanceKm': km,
                                      '_docId': doc.id,
                                    });
                                  }
                                }
                                if (_ratingsLoaded &&
                                    selectedFilter == 'Top Rated') {
                                  print(
                                    'For You: Applying Top Rated filter. Provider ratings: $providerRatings',
                                  );
                                  scored.retainWhere(
                                    (s) =>
                                        (providerRatings[s['_docId']] ?? 0) >=
                                        4.0,
                                  );
                                  print(
                                    'For You: After filtering, scored length: ${scored.length}',
                                  );
                                }
                                scored.sort((a, b) {
                                  final ak = (a['_distanceKm'] as num)
                                      .toDouble();
                                  final bk = (b['_distanceKm'] as num)
                                      .toDouble();
                                  return ak.compareTo(bk);
                                });
                                show = scored.take(10).toList();
                              } else {
                                var filteredDocs = docs;
                                if (_ratingsLoaded &&
                                    selectedFilter == 'Top Rated') {
                                  filteredDocs = docs
                                      .where(
                                        (doc) =>
                                            (providerRatings[doc.id] ?? 0) >=
                                            4.0,
                                      )
                                      .toList();
                                }
                                show = filteredDocs
                                    .take(10)
                                    .map(
                                      (doc) => {
                                        ...doc.data(),
                                        '_docId': doc.id,
                                      },
                                    )
                                    .toList();
                              }

                              if (show.isEmpty) {
                                return const Center(
                                  child: Text("No providers found"),
                                );
                              }

                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.only(right: w * 0.04),
                                itemCount: show.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(width: w * 0.05),
                                itemBuilder: (_, i) =>
                                    _providerCard(w, show[i]),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: w * 0.04,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _sidebarKey.currentState?.toggleDrawer(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.menu, color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            UserName(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SideBar(key: _sidebarKey),
                  if (_searchResults.isNotEmpty)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      top: _showFilters ? 170 : 120,
                      left: w * 0.04,
                      right: w * 0.04,
                      height: 200,
                      child: GestureDetector(
                        onTap: () => setState(() => _searchResults = []),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final data = _searchResults[index].data();
                              final businessName =
                                  data['businessName'] ?? 'Unknown';
                              final jobCategoryName =
                                  data['jobCategoryName'] ?? '';
                              final workplaceLocationText =
                                  data['workplaceLocationText'] ?? '';
                              return ListTile(
                                leading: Icon(
                                  Icons.search,
                                  color: Colors.black,
                                ),
                                title: Text(
                                  businessName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '$jobCategoryName${workplaceLocationText.isNotEmpty ? ' - $workplaceLocationText' : ''}',
                                ),
                                onTap: () {
                                  final safeData = Map<String, dynamic>.from(
                                    data,
                                  );
                                  if (safeData['portfolioFiles'] == null ||
                                      safeData['portfolioFiles'] is! List ||
                                      (safeData['portfolioFiles'] as List)
                                          .isEmpty) {
                                    safeData['portfolioFiles'] = [''];
                                  }
                                  final navData = {
                                    ...safeData,
                                    '_docId': _searchResults[index].id,
                                  };
                                  if (_currentPos != null) {
                                    final gp = data['workplaceLatLng'];
                                    if (gp is GeoPoint) {
                                      navData['_distanceKm'] = _kmFromCurrent(
                                        gp,
                                      );
                                    }
                                  }
                                  try {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            WorkerDetailsScreen(
                                              providerId: '',
                                              data: navData,
                                              workerId: '',
                                            ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                  setState(() => _searchResults = []);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }
}
