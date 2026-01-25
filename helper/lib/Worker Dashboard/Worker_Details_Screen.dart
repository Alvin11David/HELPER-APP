import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:helper/Components/User_Name.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WorkerDetailsScreen extends StatefulWidget {
  const WorkerDetailsScreen({super.key});

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  late String _greeting;
  String? _businessName;
  int _imageIndex = 0;
  bool _isDescriptionExpanded = false;
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  List<String> _portfolioFiles = [];
  String? _jobCategoryName;
  int? _yearsExperience;
  String? _skillsDescription;
  String? _pricingType;
  int? _amount;
  String? _experienceLevel;
  // Workplace location variables
  final String workplaceLocationText = 'Mbale';
  final LatLng workplaceLatLng = const LatLng(
    0.351719882423072,
    32.59219899773598,
  );

  @override
  void initState() {
    super.initState();
    _greeting = _getGreeting();
    _loadPortfolio();
    _loadBusinessName();
  }

  Future<void> _loadBusinessName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('serviceProviders')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            if (data != null && data['businessName'] != null) {
              _businessName = data['businessName'];
            }
            if (data != null && data['jobCategoryName'] != null) {
              _jobCategoryName = data['jobCategoryName'];
            }
            if (data != null && data['yearsExperience'] != null) {
              _yearsExperience = int.tryParse(
                data['yearsExperience'].toString(),
              );
            }
            if (data != null && data['skillsDescription'] != null) {
              _skillsDescription = data['skillsDescription'];
            }
            if (data != null && data['pricingType'] != null) {
              _pricingType = data['pricingType'];
            }
            if (data != null && data['amount'] != null) {
              _amount = int.tryParse(data['amount'].toString());
            }
            if (data != null && data['experienceLevel'] != null) {
              _experienceLevel = data['experienceLevel'];
            }
          });
        }
      } catch (e) {
        // Handle error if needed
      }
    }
  }

  Future<void> _loadPortfolio() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('serviceProviders')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['portfolioFiles'] is List) {
            setState(() {
              _portfolioFiles = List<String>.from(data['portfolioFiles']);
            });
          }
        }
      } catch (e) {
        // Handle error if needed
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _onWorkplaceLocationTap() {
    // Example: Show a dialog with the coordinates, or navigate to a map
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workplace Location'),
        content: Text(
          'Lat: ${workplaceLatLng.latitude}\nLng: ${workplaceLatLng.longitude}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Container(
                height: h * 2,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/background/normalscreenbg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: h * 0.4,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: _portfolioFiles.isEmpty,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageIndex = 0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(30),
                                    bottomRight: Radius.circular(30),
                                  ),
                                  child: _portfolioFiles.isNotEmpty
                                      ? Image.network(
                                          _portfolioFiles[_imageIndex],
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          'assets/images/water.png',
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _imageIndex =
                                    (_imageIndex + 1) %
                                    (_portfolioFiles.isNotEmpty
                                        ? _portfolioFiles.length
                                        : 1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: _portfolioFiles.isNotEmpty
                                    ? Image.network(
                                        _portfolioFiles[(_imageIndex + 1) %
                                            _portfolioFiles.length],
                                        width: 82,
                                        height: 82,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'assets/images/plumber.png',
                                        width: 82,
                                        height: 82,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _portfolioFiles.isNotEmpty
                                    ? _portfolioFiles.length
                                    : 2,
                                (index) => GestureDetector(
                                  onTap: () =>
                                      setState(() => _imageIndex = index),
                                  child: Container(
                                    width: 9,
                                    height: 9,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: index == _imageIndex
                                          ? Colors.orange
                                          : const Color(0xFFD9D9D9),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 10,
                      left: w * 0.04,
                      child: Text(
                        _businessName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 35,
                      left: w * 0.04,
                      child: Text(
                        '${_jobCategoryName ?? ''} - ${_experienceLevel ?? ''} ${_yearsExperience != null ? _yearsExperience.toString() : ''} Years of Experience',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 60,
                      left: w * 0.04,
                      child: Row(
                        children: [
                          Container(
                            width: 148,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFA10D),
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Call Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 148,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFA10D),
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                const Text(
                                  'Message',
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
                    Positioned(
                      top: h * 0.4 + 100,
                      left: w * 0.04,
                      child: const Text(
                        'About Me',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 130,
                      left: w * 0.04,
                      right: w * 0.04,
                      child: RichText(
                        text: TextSpan(
                          text: _skillsDescription ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          children: [
                            if (_isDescriptionExpanded)
                              const TextSpan(text: 'additional words here '),
                            TextSpan(
                              text: _isDescriptionExpanded
                                  ? 'Read less'
                                  : 'Read more...',
                              style: const TextStyle(
                                color: Color(0xFFFFA10D),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => setState(
                                  () => _isDescriptionExpanded =
                                      !_isDescriptionExpanded,
                                ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 200,
                      left: w * 0.04,
                      child: const Text(
                        'Review Section',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 230,
                      left: w * 0.04,
                      child: SizedBox(
                        height: 120,
                        width: w * 0.92,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(
                              3,
                              (index) => Row(
                                children: [
                                  Container(
                                    width: 280,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: List.generate(
                                              5,
                                              (starIndex) => Icon(
                                                Icons.star,
                                                color: Colors.orange,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'The employer’s review about the services provided by the worker...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          const Text(
                                            'Employer\'s Name',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (index < 2) const SizedBox(width: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 350,
                      left: w * 0.04,
                      child: const Text(
                        'Pricing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 380,
                      left: w * 0.04,
                      child: RichText(
                        text: TextSpan(
                          text:
                              '${_businessName ?? ''} prefers ${_pricingType ?? ''} which is\n',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: _amount != null ? _amount.toString() : '',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 420,
                      left: w * 0.04,
                      child: const Text(
                        'Work Place Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 450,
                      left: w * 0.04,
                      child: RichText(
                        text: TextSpan(
                          text: 'Work Place: ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: workplaceLocationText,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _onWorkplaceLocationTap,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 480,
                      left: w * 0.04,
                      child: const Text(
                        'Reviews and Ratings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 510,
                      left: w * 0.04,
                      child: const Text(
                        'Rate this service',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 540,
                      left: w * 0.04,
                      child: Row(
                        children: List.generate(
                          5,
                          (index) => GestureDetector(
                            onTap: () => setState(() => _rating = index + 1),
                            child: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.orange,
                              size: 35,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 580,
                      left: w * 0.04,
                      child: Container(
                        width: 290,
                        height: 110,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: TextField(
                            controller: _commentController,
                            onChanged: (value) => setState(() {}),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText:
                                  'Please share your ideas with us about this service',
                              hintStyle: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                            ),
                            maxLines: 3,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 650,
                      left: w * 0.06 + 240,
                      child: GestureDetector(
                        onTap: _commentController.text.isNotEmpty
                            ? () {
                                /* Send comment */
                              }
                            : null,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _commentController.text.isNotEmpty
                                ? Colors.orange
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.black,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 10,
                      right: w * 0.04,
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            '4.6',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '(200)',
                            style: TextStyle(color: Colors.white, fontSize: 14),
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
                                _greeting,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              UserName(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  SizedBox(height: h * 0.05),
                  Center(
                    child: SizedBox(
                      width: w * 0.9,
                      height: h * 0.07,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hire Business Name',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: w * 0.045,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Poppins",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
