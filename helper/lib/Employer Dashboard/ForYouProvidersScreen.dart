import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:helper/Components/User_Name.dart';
import 'package:helper/Components/Side_Bar.dart';
import '../Components/User_Avatar_Circle.dart';
import 'package:helper/Worker%20Dashboard/Worker_Details_Screen.dart';
import '../Components/Bottom_Nav_Bar.dart';

class ForYouProvidersScreen extends StatefulWidget {
  const ForYouProvidersScreen({super.key});

  @override
  State<ForYouProvidersScreen> createState() => _ForYouProvidersScreenState();
}

class _ForYouProvidersScreenState extends State<ForYouProvidersScreen> {
  final GlobalKey<SideBarState> _sidebarKey = GlobalKey();

  late FocusNode _focusNode;
  late TextEditingController _controller;
  Timer? _debounce;
  bool _searching = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _searchResults = [];
  late Widget _avatarWidget;

  @override
  void initState() {
    super.initState();
    _avatarWidget = UserAvatarCircle();
    _focusNode = FocusNode();
    _controller = TextEditingController();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _searchResults = []);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
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

      filtered.sort((a, b) {
        bool aProm = a.data()['promoted'] ?? false;
        bool bProm = b.data()['promoted'] ?? false;
        if (aProm != bProm) return aProm ? -1 : 1;
        return 0;
      });

      setState(() => _searchResults = filtered.take(10).toList());
    } catch (e) {
      print("Search error: $e");
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
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
          child: Stack(
            children: [
              Column(
                children: [
                  // Top bar
                  SizedBox(
                    height: 110,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10,
                          left: w * 0.04,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _sidebarKey.currentState?.toggleDrawer(),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.menu,
                                    color: Colors.black,
                                  ),
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
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 60,
                          left: w * 0.04,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.chevron_left,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                    child: Text(
                      'All Service Providers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: w * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Search Bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                    child: Container(
                      height: 50,
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
                  ),

                  const SizedBox(height: 20),

                  // Content
                  Expanded(
                    child: _searchResults.isNotEmpty
                        ? Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: w * 0.04,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.search,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Search Results (${_searchResults.length})',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _searchResults = []),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.black,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: GridView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 0,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 16,
                                        crossAxisSpacing: 16,
                                        childAspectRatio: 0.85,
                                      ),
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final doc = _searchResults[index];
                                    final data = doc.data();
                                    final businessName =
                                        data['businessName'] ?? 'Unknown';
                                    final jobCategory =
                                        data['jobCategoryName'] ?? 'Unknown';
                                    final workplaceLocation =
                                        data['workplaceLocationText'] ?? '';
                                    final amount = data['amount'];
                                    final pricingType = data['pricingType'];

                                    // Get portfolio image
                                    final files = data['portfolioFiles'];
                                    String img = '';
                                    if (files is List &&
                                        files.isNotEmpty &&
                                        files.last is String) {
                                      img = files.last;
                                    }

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                WorkerDetailsScreen(
                                                  providerId: doc.id,
                                                  data: data,
                                                  workerId: '',
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.95),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(
                                                      20,
                                                    ),
                                                    topRight: Radius.circular(
                                                      20,
                                                    ),
                                                  ),
                                              child: img.isNotEmpty
                                                  ? Image.network(
                                                      img,
                                                      height: 100,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      height: 70,
                                                      width: double.infinity,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.person,
                                                        size: 40,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    businessName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    workplaceLocation.isNotEmpty
                                                        ? workplaceLocation
                                                        : 'Location not specified',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    (amount != null
                                                            ? NumberFormat(
                                                                '#,###',
                                                              ).format(
                                                                num.tryParse(
                                                                      amount
                                                                          .toString(),
                                                                    ) ??
                                                                    0,
                                                              )
                                                            : '') +
                                                        (pricingType != null &&
                                                                pricingType
                                                                    .toString()
                                                                    .isNotEmpty
                                                            ? ' / $pricingType'
                                                            : ''),
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('serviceProviders')
                                .where('isActive', isEqualTo: true)
                                .where(
                                  'onboardingStep',
                                  isEqualTo: 'skills_job_details_done',
                                )
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error: ${snapshot.error}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final docs = snapshot.data!.docs;

                              docs.sort((a, b) {
                                final aData = a.data() as Map<String, dynamic>?;
                                final bData = b.data() as Map<String, dynamic>?;
                                bool aProm = aData?['promoted'] ?? false;
                                bool bProm = bData?['promoted'] ?? false;
                                if (aProm != bProm) return aProm ? -1 : 1;
                                Timestamp? aTime = aData?['updatedAt'];
                                Timestamp? bTime = bData?['updatedAt'];
                                if (aTime == null && bTime == null) return 0;
                                if (aTime == null) return 1;
                                if (bTime == null) return -1;
                                return bTime.compareTo(aTime);
                              });

                              if (docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No service providers found',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              return GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 0,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: 0.85,
                                    ),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final doc = docs[index];
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final businessName =
                                      data['businessName'] ?? 'Unknown';
                                  final jobCategory =
                                      data['jobCategoryName'] ?? 'Unknown';
                                  final workplaceLocation =
                                      data['workplaceLocationText'] ?? '';
                                  final amount = data['amount'];
                                  final pricingType = data['pricingType'];

                                  // Get portfolio image
                                  final files = data['portfolioFiles'];
                                  String img = '';
                                  if (files is List &&
                                      files.isNotEmpty &&
                                      files.last is String) {
                                    img = files.last;
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              WorkerDetailsScreen(
                                                providerId: doc.id,
                                                data: data,
                                                workerId: '',
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(20),
                                                  topRight: Radius.circular(20),
                                                ),
                                            child: img.isNotEmpty
                                                ? Image.network(
                                                    img,
                                                    height: 100,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    height: 70,
                                                    width: double.infinity,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.person,
                                                      size: 40,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  businessName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  workplaceLocation.isNotEmpty
                                                      ? workplaceLocation
                                                      : 'Location not specified',
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  (amount != null
                                                          ? NumberFormat(
                                                              '#,###',
                                                            ).format(
                                                              num.tryParse(
                                                                    amount
                                                                        .toString(),
                                                                  ) ??
                                                                  0,
                                                            )
                                                          : '') +
                                                      (pricingType != null &&
                                                              pricingType
                                                                  .toString()
                                                                  .isNotEmpty
                                                          ? ' / $pricingType'
                                                          : ''),
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
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

                  // Bottom nav
                  BottomNavBar(currentIndex: 0),
                ],
              ),
              SideBar(key: _sidebarKey),
            ],
          ),
        ),
      ),
    );
  }
}
