import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:helper/Components/User_Name.dart';
import 'package:helper/Components/user_avatar_circle.dart';
import 'package:helper/Worker%20Dashboard/Worker_Details_Screen.dart';
import '../Components/Bottom_Nav_Bar.dart';

class EmployerDashboardScreen extends StatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  State<EmployerDashboardScreen> createState() =>
      _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> {
  int _selectedIndex = 0;

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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _suggestionDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _searchResults = [];

  Position? _currentPos;
  bool _locLoading = false;
  String? _locError;

  bool get _hasQuery => _controller.text.trim().length >= 2;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController();
    _focusNode.addListener(() => setState(() {}));

    _initLocation(); // ✅ start GPS
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
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
            "Location permission denied forever. Enable it in settings.");
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

  Future<void> _runSearch(String input, {bool fetchResults = false}) async {
    final q = input.trim().toLowerCase();
    if (q.length < 2) {
      setState(() {
        _suggestionDocs = [];
        if (fetchResults) _searchResults = [];
      });
      return;
    }

    setState(() => _searching = true);

    try {
      final query = FirebaseFirestore.instance
          .collection('serviceProviders')
          .where('isActive', isEqualTo: true)
          .where('onboardingStep', isEqualTo: 'skills_job_details_done')
          .orderBy('searchableText')
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(fetchResults ? 30 : 10);

      final snap = await query.get();

      setState(() {
        if (fetchResults) {
          _searchResults = snap.docs;
        } else {
          _suggestionDocs = snap.docs;
        }
      });
    } catch (e) {
      // ✅ TEMP fallback: fetch recent providers then filter locally
      try {
        final snap = await FirebaseFirestore.instance
            .collection('serviceProviders')
            .where('isActive', isEqualTo: true)
            .where('onboardingStep', isEqualTo: 'skills_job_details_done')
            .orderBy('updatedAt', descending: true)
            .limit(60)
            .get();

        final filtered = snap.docs.where((d) {
          final searchText =
              (d.data()['searchableText'] ?? '').toString().toLowerCase();
          return searchText.contains(q);
        }).toList();

        setState(() {
          if (fetchResults) {
            _searchResults = filtered.take(30).toList();
          } else {
            _suggestionDocs = filtered.take(10).toList();
          }
        });
      } catch (e2) {
        // ignore: avoid_print
        print("Search error fallback: $e2");
      }

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

    final amountText = (amount is num) ? amount.toInt().toString() : amount.toString();
    
    final dist = d['_distanceKm'];
    final distText = (dist is num) ? "${dist.toStringAsFixed(1)} km" : "";
    final docId = (d['_docId'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkerDetailsScreen(providerId: docId),
            settings: RouteSettings(
              arguments: {
                'docId': docId,
                'data': d,
              },
            ),
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
                  top: w * 0.025, left: w * 0.02, right: w * 0.02),
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
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    job.isEmpty ? 'Service Provider' : job,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black, fontSize: 13),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$amountText ${pricingType.isNotEmpty ? "/ $pricingType" : ""}',
                        style: const TextStyle(color: Colors.black, fontSize: 13),
                      ),
                      if (distText.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.black),
                            const SizedBox(width: 3),
                            Text(distText, style: const TextStyle(color: Colors.black, fontSize: 13)),
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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
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
                      const UserAvatarCircle(
                        size: 40,
                        backgroundColor: Colors.white,
                        iconColor: Colors.black,
                        borderWidth: 0,
                      ),
                      const SizedBox(width: 10),
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
                                  _debounce?.cancel();
                                  _debounce =
                                      Timer(const Duration(milliseconds: 300), () {
                                    _runSearch(v, fetchResults: true);
                                  });
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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tune, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 125,
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
                Positioned(
                  top: 160,
                  left: w * 0.04,
                  right: w * 0.04,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.home, color: Colors.black),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'House',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      Column(
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
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      Column(
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
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      Column(
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
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      Column(
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
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 240,
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
                Positioned(
                  top: 280,
                  left: w * 0.04,
                  right: 0,
                  child: SizedBox(
                    height: w * 0.8,
                    child: Builder(
                      builder: (_) {
                        if (_locLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (_locError != null) {
                          return Center(
                              child: Text(_locError!,
                                  style:
                                      const TextStyle(color: Colors.white)));
                        }
                        if (_currentPos == null) {
                          return const Center(
                              child: Text("Getting your location...",
                                  style: TextStyle(color: Colors.white)));
                        }

                        return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('serviceProviders')
                              .where('isActive', isEqualTo: true)
                              .where('onboardingStep',
                                  isEqualTo: 'skills_job_details_done')
                              .orderBy('updatedAt', descending: true)
                              .limit(
                                  250) // fetch enough then sort locally by distance
                              .snapshots(),
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
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

                              final km = _kmFromCurrent(gp);

                              if (km > radiusKm) continue;

                              scored.add({
                                ...d,
                                '_distanceKm': km,
                                '_docId': doc.id,
                              });
                            }

                            // sort shortest distance first
                            scored.sort((a, b) {
                              final ak = (a['_distanceKm'] as num).toDouble();
                              final bk = (b['_distanceKm'] as num).toDouble();
                              return ak.compareTo(bk);
                            });

                            if (scored.isEmpty) {
                              return const Center(
                                child: Text("No nearby providers found",
                                    style: TextStyle(color: Colors.white)),
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
                Positioned(
                  top: 280 + w * 0.8 + 20,
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
                Positioned(
                  top: 280 + w * 0.8 + 60,
                  left: w * 0.04,
                  right: 0,
                  child: SizedBox(
                    height: w * 0.8,
                    child: _hasQuery
                        ? (_searching
                            ? const Center(child: CircularProgressIndicator())
                            : (_searchResults.isEmpty
                                ? const Center(child: Text("No matches"))
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: EdgeInsets.only(right: w * 0.04),
                                    itemCount: _searchResults.length,
                                    separatorBuilder: (_, __) =>
                                        SizedBox(width: w * 0.05),
                                    itemBuilder: (_, i) => _providerCard(
                                        w,
                                        {
                                          ..._searchResults[i].data(),
                                          '_docId': _searchResults[i].id,
                                        }),
                                  )))
                        : StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('serviceProviders')
                                .where('isActive', isEqualTo: true)
                                .where('onboardingStep',
                                    isEqualTo: 'skills_job_details_done')
                                .orderBy('updatedAt', descending: true)
                                .limit(10)
                                .snapshots(),
                            builder: (context, snap) {
                              if (snap.hasError) {
                                return Center(
                                  child: Text(
                                    "Firestore error: ${snap.error}",
                                    style:
                                        const TextStyle(color: Colors.white),
                                  ),
                                );
                              }
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (!snap.hasData || snap.data!.docs.isEmpty) {
                                return const Center(
                                    child: Text("No providers yet"));
                              }

                              final docs = snap.data!.docs;
                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.only(right: w * 0.04),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(width: w * 0.05),
                                itemBuilder: (_, i) => _providerCard(
                                  w,
                                  {
                                    ...docs[i].data(),
                                    '_docId': docs[i].id,
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ),
                if (_focusNode.hasFocus && (_suggestionDocs.isNotEmpty || _searching))
                  Positioned(
                    top: 115,
                    left: w * 0.04,
                    right: w * 0.04,
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  width: 80,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFF79F1A),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Location',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 80,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFF79F1A),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Search Jobs',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 80,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFF79F1A),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _searching
                                ? const Center(child: CircularProgressIndicator())
                                : ListView.builder(
                                    itemCount: _suggestionDocs.length,
                                    itemBuilder: (context, index) {
                                      final d = _suggestionDocs[index].data();

                                      final businessName =
                                          (d['businessName'] ?? '').toString();
                                      final jobCategoryName =
                                          (d['jobCategoryName'] ?? '').toString();
                                      final location =
                                          (d['workplaceLocationText'] ?? '')
                                              .toString();
                                      final searchable =
                                          (d['searchableText'] ?? '')
                                              .toString();

                                      final displayLabel =
                                          businessName.isNotEmpty
                                              ? businessName
                                              : jobCategoryName.isNotEmpty
                                                  ? jobCategoryName
                                                  : location;

                                      return ListTile(
                                        title: Text(displayLabel),
                                        subtitle: Text(
                                          '${jobCategoryName.isNotEmpty ? jobCategoryName : ''}${location.isNotEmpty ? " • $location" : ""}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () async {
                                          _controller.text = searchable;
                                          _focusNode.unfocus();

                                          await _runSearch(searchable,
                                              fetchResults: true);

                                          setState(() {
                                            _suggestionDocs = [];
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 20,
                  left: w * 0.04,
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
                        child: const Icon(Icons.menu, color: Colors.black),
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
                          UserName()
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,),
    );
  }
}
