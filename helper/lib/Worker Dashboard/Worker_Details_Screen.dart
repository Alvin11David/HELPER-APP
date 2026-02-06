import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:helper/Components/User_Name.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:helper/Employer%20Dashboard/job_detail_booking_screen.dart';
import 'package:helper/Employer%20Dashboard/Employer_Dashboard_Screen.dart';
import 'package:helper/Employer%20Dashboard/Employer_Notifications.dart';
import 'package:helper/Maps/Map_Screen.dart';
import 'package:helper/Chats/Chat_Screen.dart';
import '../Components/Side_Bar.dart';

class Review {
  final String reviewerName;
  final int rating;
  final String reviewText;

  Review({
    required this.reviewerName,
    required this.rating,
    required this.reviewText,
  });
}

class WorkerDetailsScreen extends StatefulWidget {
  final String providerId;
  final Map<String, dynamic>? data;
  const WorkerDetailsScreen({
    super.key,
    required this.providerId,
    this.data,
    required String workerId,
  });

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

  final GlobalKey<SideBarState> _sidebarKey = GlobalKey();

  late String _greeting;

  String? _businessName;
  String? _jobCategoryName;
  int? _yearsExperience;
  String? _skillsDescription;
  String? _pricingType;
  int? _amount;
  String? _experienceLevel;
  List<String> _portfolioFiles = [];
  String? _workplaceLocationText;
  GeoPoint? _workplaceLatLng;

  int _imageIndex = 0;
  bool _isDescriptionExpanded = false;
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _greeting = _getGreeting();
    if (widget.data != null) {
      _setData(widget.data!);
      _loadReviews();
    } else {
      _loadProvider();
    }
  }

  Future<void> _markMessagesAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final query = await FirebaseFirestore.instance
        .collection('Support Issues')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
      bool updated = false;
      for (int i = 0; i < messages.length; i++) {
        if ((messages[i]['sender'] == 'admin' ||
                messages[i]['sender'] == 'system') &&
            messages[i]['read'] != true) {
          messages[i]['read'] = true;
          updated = true;
        }
      }
      if (updated) {
        batch.update(doc.reference, {'messages': messages});
      }
    }

    await batch.commit();
  }

  void _setData(Map<String, dynamic> data) {
    setState(() {
      _businessName = (data['businessName'] ?? '').toString();
      _jobCategoryName = (data['jobCategoryName'] ?? '').toString();
      _skillsDescription = (data['skillsDescription'] ?? '').toString();
      _pricingType = (data['pricingType'] ?? '').toString();
      _experienceLevel = (data['experienceLevel'] ?? '').toString();

      _yearsExperience = int.tryParse(
        (data['yearsExperience'] ?? '').toString(),
      );
      _amount = int.tryParse((data['amount'] ?? '').toString());

      _workplaceLocationText = (data['workplaceLocationText'] ?? '').toString();
      final gp = data['workplaceLatLng'];
      if (gp is GeoPoint) _workplaceLatLng = gp;

      final portfolioFilesRaw = data['portfolioFiles'];
      if (portfolioFilesRaw is List) {
        _portfolioFiles = portfolioFilesRaw.map((e) => e.toString()).toList();
        if (_imageIndex >= _portfolioFiles.length &&
            _portfolioFiles.isNotEmpty) {
          _imageIndex = 0;
        }
      }
    });
  }

  Future<void> _loadProvider() async {
    final docId = widget.providerId;

    if (docId.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('serviceProviders')
          .doc(docId)
          .get();

      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      _setData(data);
      _loadReviews();
    } catch (e) {
      // Swallow errors to avoid breaking UI; consider logging in the future
    }
  }

  Future<void> _loadReviews() async {
    final providerId = widget.data?['uid'] ?? widget.providerId;
    if (providerId.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('Reviews')
          .where('providerId', isEqualTo: providerId)
          .get();

      final docs = snap.docs;
      docs.sort((a, b) {
        final ta = a.data()['timestamp'] as Timestamp?;
        final tb = b.data()['timestamp'] as Timestamp?;
        if (ta == null || tb == null) return 0;
        return tb.compareTo(ta); // descending
      });

      final limitedDocs = docs.take(10).toList();

      setState(() {
        _reviews = limitedDocs.map((doc) {
          final d = doc.data();
          return Review(
            reviewerName: (d['reviewerName'] ?? '').toString(),
            rating: d['rating'] is int ? d['rating'] : 0,
            reviewText: (d['reviewText'] ?? '').toString(),
          );
        }).toList();
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showWorkplaceDialog(GeoPoint gp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Workplace Location'),
        content: Text('Lat: ${gp.latitude}\nLng: ${gp.longitude}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _onWorkplaceLocationTap() {
    final workerData = {
      'businessName': _businessName,
      'jobCategoryName': _jobCategoryName,
      'skillsDescription': _skillsDescription,
      'pricingType': _pricingType,
      'amount': _amount,
      'experienceLevel': _experienceLevel,
      'yearsExperience': _yearsExperience,
      'portfolioFiles': _portfolioFiles,
      'workplaceLocationText': _workplaceLocationText,
      'workplaceLatLng': _workplaceLatLng,
      'uid': widget.data?['uid'] ?? widget.providerId,
    };
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapScreen(worker: workerData)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
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
                            child: _portfolioFiles.isNotEmpty
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _portfolioFiles.length,
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
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: w * 0.2,
                      left: w * 0.04,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => EmployerDashboardScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.black,
                          ),
                        ),
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
                      right: w * 0.31,
                      child: Center(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                final businessName =
                                    _businessName ?? 'Provider';
                                final providerId =
                                    widget.data?['uid'] ?? widget.providerId;
                                final employerId =
                                    FirebaseAuth.instance.currentUser!.uid;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatPartnerName: businessName,
                                      providerId: providerId,
                                      employerId: employerId,
                                    ),
                                  ),
                                );
                              },
                              child: Center(
                                child: Container(
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
                                        Icons.chat,
                                        color: Colors.white,
                                        size: 16,
                                      ),
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
                              ),
                            ),
                          ],
                        ),
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
                            children: _reviews.isNotEmpty
                                ? _reviews
                                      .map(
                                        (review) => Row(
                                          children: [
                                            Container(
                                              width: 280,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: List.generate(
                                                        5,
                                                        (starIndex) => Icon(
                                                          starIndex <
                                                                  review.rating
                                                              ? Icons.star
                                                              : Icons
                                                                    .star_border,
                                                          color: Colors.orange,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      review.reviewText,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      review.reviewerName,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                          ],
                                        ),
                                      )
                                      .toList()
                                : [
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
                                      child: const Center(
                                        child: Text(
                                          'No reviews as of yet',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
                              '${_businessName ?? ''} prefers ${_pricingType ?? ''} which\nis ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: _amount != null
                                  ? NumberFormat('#,##0').format(_amount)
                                  : '',
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
                              text: _workplaceLocationText ?? '',
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
                      top: h * 0.4 + 470,
                      left: w * 0.04,
                      child: const Text(
                        'Tap the orange underlined text to navigate to the worker\'s location',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 485,
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
                      top: h * 0.4 + 520,
                      left: w * 0.04,
                      child: const Text(
                        'Rate this service',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    Positioned(
                      top: h * 0.4 + 550,
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
                      top: h * 0.4 + 590,
                      left: w * 0.04,
                      child: Container(
                        width: 320,
                        height: 130,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            Padding(
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
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap:
                                    (_rating > 0 &&
                                        _commentController.text.isNotEmpty)
                                    ? () async {
                                        final user =
                                            FirebaseAuth.instance.currentUser;
                                        if (user == null) return;

                                        final reviewerId = user.uid;
                                        final reviewerName =
                                            user.displayName ?? 'Anonymous';
                                        final providerId =
                                            widget.data?['uid'] ??
                                            widget.providerId;
                                        final providerName =
                                            _businessName ?? 'Provider';

                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('Reviews')
                                              .add({
                                                'reviewerId': reviewerId,
                                                'reviewerName': reviewerName,
                                                'providerId': providerId,
                                                'providerName': providerName,
                                                'rating': _rating,
                                                'reviewText':
                                                    _commentController.text,
                                                'timestamp':
                                                    FieldValue.serverTimestamp(),
                                              });

                                          // Add notification to Support Issues
                                          await FirebaseFirestore.instance
                                              .collection('Support Issues')
                                              .add({
                                                'userId': reviewerId,
                                                'messages': [
                                                  {
                                                    'sender': 'system',
                                                    'senderId': 'system',
                                                    'senderName': 'System',
                                                    'message':
                                                        'Your review has been successfully sent for $providerName.',
                                                    'timestamp':
                                                        Timestamp.fromDate(
                                                          DateTime.now(),
                                                        ),
                                                    'read': false,
                                                    'status': 'info',
                                                  },
                                                ],
                                                'status': 'info',
                                              });

                                          setState(() {
                                            _reviews.insert(
                                              0,
                                              Review(
                                                reviewerName: reviewerName,
                                                rating: _rating,
                                                reviewText:
                                                    _commentController.text,
                                              ),
                                            );
                                            _rating = 0;
                                            _commentController.clear();
                                          });

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Review sent successfully!',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to send review: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color:
                                        (_rating > 0 &&
                                            _commentController.text.isNotEmpty)
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
                          ],
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
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Support Issues')
                                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              int unreadCount = 0;
                              if (snapshot.hasData) {
                                for (var doc in snapshot.data!.docs) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final messages = data['messages'] as List<dynamic>? ?? [];
                                  for (var msg in messages) {
                                    if (msg is Map<String, dynamic> && (msg['sender'] == 'admin' || msg['sender'] == 'system') && msg['read'] != true) {
                                      unreadCount++;
                                    }
                                  }
                                }
                              }
                              return GestureDetector(
                                onTap: () async {
                                  await _markMessagesAsRead();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EmployerNotifications(),
                                    ),
                                  );
                                },
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
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            unreadCount > 99
                                                ? '99+'
                                                : unreadCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobDetailBookingScreen(
                                serviceProviderId: widget.providerId,
                                businessName: _businessName ?? 'Provider',
                                profession: _jobCategoryName ?? 'Service',
                                amount: _amount,
                                pricingType: _pricingType,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Hire ${_businessName?.isNotEmpty ?? false ? _businessName : "Provider"}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: w * 0.045,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Poppins",
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
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
            SideBar(key: _sidebarKey),
          ],
        ),
      ),
    );
  }
}
