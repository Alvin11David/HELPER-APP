import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:helper/Components/User_Name.dart';
import 'package:helper/Components/Side_Bar.dart';
import 'package:helper/Employer%20Dashboard/Employer_Notifications.dart';
import 'package:intl/intl.dart';
import '../Components/User_Avatar_Circle.dart';
import '../Components/EmployerNotificationsBadge.dart';
import 'package:helper/Employer%20Dashboard/Category_Providers_Screen.dart';
import '../Components/Bottom_Nav_Bar.dart';

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  final GlobalKey<SideBarState> _sidebarKey = GlobalKey();
  late Widget _avatarWidget;
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  late String _greeting;
  late FocusNode _focusNode;
  late TextEditingController _controller;
  List<String> suggestions = [
    'House',
    'Electricity',
    'Driver',
    'Plumbing',
    'Cleaning',
    'Gardening',
  ];

  Future<List<String>> _getDynamicCategories() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('serviceProviders')
          .get();

      final Set<String> uniqueCategories = {};
      for (var doc in snapshot.docs) {
        final category = doc['jobCategoryName'] as String?;
        if (category != null && category.isNotEmpty) {
          uniqueCategories.add(category);
        }
      }

      // Return categories that are not already in suggestions
      return uniqueCategories
          .where((category) => !suggestions.contains(category))
          .toList();
    } catch (e) {
      print('Error fetching dynamic categories: $e');
      return [];
    }
  }

  Future<List<String>> _getAllCategories() async {
    final dynamicCategories = await _getDynamicCategories();
    return [...suggestions, ...dynamicCategories];
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

      return result;
    } catch (e) {
      print('Error getting category ratings: $e');
      return {};
    }
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

    print('Current user UID: ${currentUser.uid}');

    // For employer dashboard, receiver is employer
    bool isEmployer = true;

    List<String> notifications = [];
    try {
      // Fetch unread messages
      try {
        final snapshot = await FirebaseFirestore.instance
            .collectionGroup('messages')
            .where('receiverId', isEqualTo: currentUser.uid)
            .get();

        print('Unread messages docs: ${snapshot.docs.length}');

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
        print('Error fetching unread messages: $e');
      }

      // Fetch admin support messages
      final supportSnapshot = await FirebaseFirestore.instance
          .collection('Support Issues')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      print('Support Issues docs: ${supportSnapshot.docs.length}');

      for (var doc in supportSnapshot.docs) {
        final data = doc.data();
        print('Support doc data: $data');
        final messages = data['messages'] as List<dynamic>? ?? [];
        print('Messages in doc: $messages');
        for (var msg in messages) {
          if (msg is Map<String, dynamic> && msg['sender'] == 'admin') {
            final message = msg['message'] as String? ?? '';
            final status = msg['status'] as String? ?? '';
            final timestamp = msg['timestamp'] as Timestamp?;
            String timeStr = '';
            if (timestamp != null) {
              final dateTime = timestamp.toDate();
              timeStr = DateFormat('MMM d, h:mm a').format(dateTime);
            }
            final notificationText =
                'Support ($status): $message${timeStr.isNotEmpty ? " at $timeStr" : ""}';
            notifications.add(notificationText);
            print('Added admin message: $notificationText');
          }
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }

    print('Total notifications: ${notifications.length}');

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

  List<String> professions = [
    'Accountant',
    'Actor',
    'Actress',
    'Actuary',
    'Administrator',
    'Advisor',
    'Agent',
    'Aide',
    'Analyst',
    'Apprentice',
    'Architect',
    'Assistant',
    'Associate',
    'Astronomer',
    'Auditor',
    'Author',
    'Baker',
    'Banker',
    'Barber',
    'Barista',
    'Bartender',
    'Beautician',
    'Biochemist',
    'Biologist',
    'Bookkeeper',
    'Brewer',
    'Broker',
    'Builder',
    'Business Analyst',
    'Butcher',
    'Carpenter',
    'Cashier',
    'Caterer',
    'Chef',
    'Chemist',
    'Chiropractor',
    'Civil Engineer',
    'Cleaner',
    'Clerk',
    'Coach',
    'Collector',
    'Commentator',
    'Composer',
    'Computer Programmer',
    'Conductor',
    'Consultant',
    'Contractor',
    'Cook',
    'Coordinator',
    'Counselor',
    'Courier',
    'Critic',
    'Dancer',
    'Decorator',
    'Dentist',
    'Designer',
    'Developer',
    'Dietitian',
    'Director',
    'Doctor',
    'Drafter',
    'Driver',
    'Economist',
    'Editor',
    'Educator',
    'Electrician',
    'Engineer',
    'Entrepreneur',
    'Estimator',
    'Executive',
    'Farmer',
    'Firefighter',
    'Fisher',
    'Fisherman',
    'Florist',
    'Gardener',
    'Geologist',
    'Graphic Designer',
    'Hairdresser',
    'Healer',
    'Historian',
    'Housekeeper',
    'Illustrator',
    'Inspector',
    'Instructor',
    'Interpreter',
    'Inventor',
    'Janitor',
    'Jeweler',
    'Journalist',
    'Judge',
    'Laborer',
    'Lawyer',
    'Librarian',
    'Machinist',
    'Manager',
    'Manufacturer',
    'Marketer',
    'Marketing Specialist',
    'Mathematician',
    'Mechanic',
    'Mediator',
    'Model',
    'Musician',
    'Nurse',
    'Nutritionist',
    'Operator',
    'Optometrist',
    'Painter',
    'Paralegal',
    'Paramedic',
    'Pathologist',
    'Pharmacist',
    'Photographer',
    'Physician',
    'Physicist',
    'Pilot',
    'Plumber',
    'Poet',
    'Police Officer',
    'Politician',
    'Presenter',
    'Priest',
    'Principal',
    'Producer',
    'Professor',
    'Programmer',
    'Psychiatrist',
    'Psychologist',
    'Publisher',
    'Radiologist',
    'Realtor',
    'Receptionist',
    'Researcher',
    'Salesperson',
    'Scientist',
    'Secretary',
    'Security Guard',
    'Singer',
    'Social Worker',
    'Software Engineer',
    'Soldier',
    'Statistician',
    'Student',
    'Supervisor',
    'Surgeon',
    'Surveyor',
    'Tailor',
    'Teacher',
    'Technician',
    'Therapist',
    'Translator',
    'Treasurer',
    'Tutor',
    'Veterinarian',
    'Waiter',
    'Waitress',
    'Web Designer',
    'Welder',
    'Writer',
    'Zookeeper',
    'Zoologist',
    'Microbiologist',
    'Molecular Biologist',
    'Geneticist',
    'Immunologist',
    'Epidemiologist',
    'Toxicologist',
    'Environmental Scientist',
    'Marine Biologist',
    'Forensic Scientist',
    'Neuroscientist',
    'Data Scientist',
    'Bioinformatician',
    'Anesthesiologist',
    'Cardiologist',
    'Dermatologist',
    'Endocrinologist',
    'Gynecologist',
    'Obstetrician',
    'Neurologist',
    'Oncologist',
    'Pediatrician',
    'Orthopedic Surgeon',
    'Urologist',
    'Ophthalmologist',
    'Radiographer',
    'Sonographer',
    'Medical Laboratory Scientist',
    'Clinical Officer',
    'Public Health Officer',
    'Occupational Therapist',
    'Speech Therapist',
    'Physiotherapist',
    'Dental Hygienist',
    'Dental Surgeon',
    'Magistrate',
    'Legal Advisor',
    'Legal Consultant',
    'Prosecutor',
    'Public Defender',
    'Notary Public',
    'Arbitrator',
    'Compliance Officer',
    'Policy Analyst',
    'Diplomat',
    'Mechanical Engineer',
    'Electrical Engineer',
    'Electronics Engineer',
    'Mechatronics Engineer',
    'Biomedical Engineer',
    'Chemical Engineer',
    'Petroleum Engineer',
    'Mining Engineer',
    'Agricultural Engineer',
    'Environmental Engineer',
    'Structural Engineer',
    'Telecommunications Engineer',
    'Network Engineer',
    'Systems Engineer',
    'Robotics Engineer',
    'Data Analyst',
    'Machine Learning Engineer',
    'AI Engineer',
    'Cloud Engineer',
    'DevOps Engineer',
    'Cybersecurity Analyst',
    'Information Security Officer',
    'Database Administrator',
    'Systems Analyst',
    'IT Consultant',
    'UX Researcher',
    'Game Developer',
    'Lecturer',
    'Senior Lecturer',
    'Dean',
    'Academic Registrar',
    'Education Officer',
    'Curriculum Developer',
    'Instructional Designer',
    'Education Psychologist',
    'Financial Analyst',
    'Investment Analyst',
    'Risk Analyst',
    'Actuarial Analyst',
    'Economist (Applied)',
    'Business Consultant',
    'Management Consultant',
    'Project Manager',
    'Product Manager',
    'Supply Chain Analyst',
    'Procurement Officer',
    'Human Resource Manager',
    'Industrial Psychologist',
    'Sociologist',
    'Anthropologist',
    'Criminologist',
    'Political Scientist',
    'Development Economist',
    'Demographer',
    'Urban Planner',
    'Town Planner',
    'International Relations Specialist',
  ];
  List<String> professionImages = List.generate(
    243,
    (index) => 'assets/images/professional.png',
  );
  List<double> ratings = List.generate(243, (index) => 2.5 + (index % 6) * 0.5);
  List<bool> liked = List.generate(243, (index) => false);
  bool _dynamicAdded = false;
  List<String> filteredProfessions = [];
  List<String> filteredImages = [];
  List<double> filteredRatings = [];
  List<bool> filteredLiked = [];
  bool _showFilters = false;
  String? selectedFilter;
  Position? userPosition;
  List<String> topRatedCategories = [];
  Map<String, double> categoryRatings = {};

  @override
  void initState() {
    super.initState();
    _avatarWidget = UserAvatarCircle();
    _greeting = _getGreeting();
    _focusNode = FocusNode();
    _controller = TextEditingController();
    _getUserPosition();
    _getTopRatedCategories();
    _getCategoryRatings().then((map) => setState(() => categoryRatings = map));
    filteredProfessions = List.from(professions);
    filteredImages = List.from(professionImages);
    filteredRatings = List.from(ratings);
    filteredLiked = List.from(liked);
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: _showFilters ? 225 : 175,
                left: w * 0.04,
                child: Text(
                  'All Categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: w * 0.05,
                    fontWeight: FontWeight.bold,
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
                          _greeting,
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
                top: 125,
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
                    child: const Icon(Icons.chevron_left, color: Colors.black),
                  ),
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
                      child: _avatarWidget,
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EmployerNotifications(),
                            ),
                          ),
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
                            child: EmployerNotificationsBadge(),
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
                              decoration: InputDecoration(
                                hintText: 'Search for services here...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.black),
                              ),
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() => _showFilters = !_showFilters),
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
                top: 175,
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
                                  (index == 0 && selectedFilter == 'Nearest') ||
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
                top: (_showFilters ? 225 : 175) + 30,
                left: w * 0.04,
                child: SizedBox(
                  width: w - 2 * w * 0.04,
                  height:
                      MediaQuery.of(context).size.height -
                      ((_showFilters ? 225 : 175) + 30),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('serviceProviders')
                        .snapshots(),
                    builder: (context, snapshot) {
                      Map<String, int> providerCounts = {};
                      Set<String> dynamicCategories = {};
                      Set<String> nearbyCategories = {};

                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          String category = doc['jobCategoryName'] ?? '';
                          if (category.isNotEmpty) {
                            bool isNearby = true;
                            if (selectedFilter == 'Nearest' &&
                                userPosition != null) {
                              Map<String, dynamic>? data =
                                  doc.data() as Map<String, dynamic>?;
                              if (data != null &&
                                  data.containsKey('workplaceLatLng')) {
                                GeoPoint? geoPoint =
                                    data['workplaceLatLng'] as GeoPoint?;
                                if (geoPoint != null) {
                                  double lat = geoPoint.latitude;
                                  double lng = geoPoint.longitude;
                                  double distance = Geolocator.distanceBetween(
                                    userPosition!.latitude,
                                    userPosition!.longitude,
                                    lat,
                                    lng,
                                  );
                                  // Assuming 50km radius
                                  isNearby = distance <= 50000;
                                } else {
                                  isNearby = false;
                                }
                              } else {
                                isNearby = false;
                              }
                            }
                            if (isNearby) {
                              providerCounts[category] =
                                  (providerCounts[category] ?? 0) + 1;
                              // Collect unique categories not in suggestions
                              if (!suggestions.contains(category)) {
                                dynamicCategories.add(category);
                              }
                              nearbyCategories.add(category);
                            }
                          }
                        }
                      }

                      // If Nearest is selected, only show nearby categories
                      List<String> allProfessions = [...professions];
                      if (selectedFilter == 'Nearest') {
                        allProfessions = allProfessions
                            .where((cat) => nearbyCategories.contains(cat))
                            .toList();
                      } else if (selectedFilter == 'Top Rated') {
                        allProfessions = allProfessions
                            .where((cat) => topRatedCategories.contains(cat))
                            .toList();
                      }
                      List<String> dynamicCategoriesList = dynamicCategories
                          .toList();
                      allProfessions.addAll(dynamicCategoriesList);

                      // Update corresponding lists for dynamic categories
                      List<String> allImages = [...professionImages];
                      List<double> allRatings = [...ratings];
                      List<bool> allLiked = [...liked];

                      // Update class-level lists if dynamic categories were added
                      if (!_dynamicAdded &&
                          dynamicCategoriesList.isNotEmpty &&
                          professions.length != allProfessions.length) {
                        _dynamicAdded = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            professions.addAll(dynamicCategoriesList);
                            professionImages.addAll(
                              List.generate(
                                dynamicCategoriesList.length,
                                (index) => 'assets/images/professional.png',
                              ),
                            );
                            ratings.addAll(
                              dynamicCategoriesList
                                  .map((cat) => categoryRatings[cat] ?? 3.0)
                                  .toList(),
                            );
                            liked.addAll(
                              List.generate(
                                dynamicCategoriesList.length,
                                (index) => false,
                              ),
                            );
                            suggestions.addAll(dynamicCategoriesList);
                          });
                        });
                      }

                      // Apply filters
                      List<String> currentProfessions = List.from(
                        allProfessions,
                      );
                      if (selectedFilter == 'Nearest') {
                        currentProfessions = currentProfessions
                            .where((cat) => nearbyCategories.contains(cat))
                            .toList();
                      } else if (selectedFilter == 'Top Rated') {
                        currentProfessions = currentProfessions
                            .where((cat) => topRatedCategories.contains(cat))
                            .toList();
                      }
                      // Ensure only categories with providers are shown
                      currentProfessions = currentProfessions
                          .where((cat) => (providerCounts[cat] ?? 0) > 0)
                          .toList();
                      String query = _controller.text.toLowerCase();
                      if (query.isNotEmpty) {
                        currentProfessions = currentProfessions
                            .where((prof) => prof.toLowerCase().contains(query))
                            .toList();
                      }

                      // Build corresponding lists
                      List<String> currentImages = [];
                      List<double> currentRatings = [];
                      List<bool> currentLiked = [];
                      for (String prof in currentProfessions) {
                        int index = allProfessions.indexOf(prof);
                        if (index >= 0 && index < professionImages.length) {
                          currentImages.add(professionImages[index]);
                          currentRatings.add(ratings[index]);
                          currentLiked.add(liked[index]);
                        } else {
                          // Dynamic category
                          currentImages.add('assets/images/professional.png');
                          currentRatings.add(3.0);
                          currentLiked.add(false);
                        }
                      }

                      // Update filtered lists
                      filteredProfessions = currentProfessions;
                      filteredImages = currentImages;
                      filteredRatings = currentRatings;
                      filteredLiked = currentLiked;

                      return Builder(
                        builder: (context) {
                          int half = (filteredProfessions.length / 2).ceil();
                          return SingleChildScrollView(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: List.generate(half, (index) {
                                      int profIndex = 2 * index;
                                      if (profIndex >=
                                              filteredProfessions.length ||
                                          profIndex >= filteredLiked.length ||
                                          profIndex >= filteredRatings.length) {
                                        return const SizedBox(
                                          width: 183,
                                          height: 110,
                                        );
                                      }
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CategoryProvidersScreen(
                                                    categoryName:
                                                        filteredProfessions[profIndex],
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 183,
                                          height: 100,
                                          margin: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              Align(
                                                alignment: Alignment.bottomLeft,
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                30,
                                                              ),
                                                          bottomRight:
                                                              Radius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        filteredProfessions[profIndex],
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${providerCounts[filteredProfessions[profIndex]] ?? 0} Providers',
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.topRight,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  child: AnimatedScale(
                                                    scale:
                                                        filteredLiked[profIndex]
                                                        ? 1.2
                                                        : 1.0,
                                                    duration: const Duration(
                                                      milliseconds: 200,
                                                    ),
                                                    child: GestureDetector(
                                                      onTap: () => setState(
                                                        () => filteredLiked[profIndex] =
                                                            !filteredLiked[profIndex],
                                                      ),
                                                      child: Container(
                                                        width: 30,
                                                        height: 30,
                                                        decoration:
                                                            BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color:
                                                                  Colors.white,
                                                              border: Border.all(
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                        child: Icon(
                                                          filteredLiked[profIndex]
                                                              ? Icons.favorite
                                                              : Icons
                                                                    .favorite_border,
                                                          color:
                                                              filteredLiked[profIndex]
                                                              ? Colors.red
                                                              : Colors.black,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.star,
                                                          color: Colors.orange,
                                                          size: 12,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          (categoryRatings[filteredProfessions[profIndex]] ??
                                                                  filteredRatings[profIndex])
                                                              .toStringAsFixed(
                                                                1,
                                                              ),
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 10,
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
                                      );
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    children: List.generate(half, (index) {
                                      int profIndex = 2 * index + 1;
                                      if (profIndex >=
                                              filteredProfessions.length ||
                                          profIndex >= filteredLiked.length ||
                                          profIndex >= filteredRatings.length) {
                                        return const SizedBox(
                                          width: 183,
                                          height: 110,
                                        );
                                      }
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CategoryProvidersScreen(
                                                    categoryName:
                                                        filteredProfessions[profIndex],
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 183,
                                          height: 100,
                                          margin: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              Align(
                                                alignment: Alignment.bottomLeft,
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                30,
                                                              ),
                                                          bottomRight:
                                                              Radius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        filteredProfessions[profIndex],
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${providerCounts[filteredProfessions[profIndex]] ?? 0} Providers',
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.topRight,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  child: AnimatedScale(
                                                    scale:
                                                        filteredLiked[profIndex]
                                                        ? 1.2
                                                        : 1.0,
                                                    duration: const Duration(
                                                      milliseconds: 200,
                                                    ),
                                                    child: GestureDetector(
                                                      onTap: () => setState(
                                                        () => filteredLiked[profIndex] =
                                                            !filteredLiked[profIndex],
                                                      ),
                                                      child: Container(
                                                        width: 30,
                                                        height: 30,
                                                        decoration:
                                                            BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color:
                                                                  Colors.white,
                                                              border: Border.all(
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                        child: Icon(
                                                          filteredLiked[profIndex]
                                                              ? Icons.favorite
                                                              : Icons
                                                                    .favorite_border,
                                                          color:
                                                              filteredLiked[profIndex]
                                                              ? Colors.red
                                                              : Colors.black,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.star,
                                                          color: Colors.orange,
                                                          size: 12,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          (categoryRatings[filteredProfessions[profIndex]] ??
                                                                  filteredRatings[profIndex])
                                                              .toStringAsFixed(
                                                                1,
                                                              ),
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 10,
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
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              SideBar(key: _sidebarKey),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }
}
