import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:helper/Components/User_Name.dart';
import 'package:helper/Components/Side_Bar.dart';
import '../Components/Bottom_Nav_Bar.dart';

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  final GlobalKey<SideBarState> _sidebarKey = GlobalKey();
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
  List<String> filteredProfessions = [];
  List<String> filteredImages = [];
  List<double> filteredRatings = [];
  List<bool> filteredLiked = [];
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _greeting = _getGreeting();
    _focusNode = FocusNode();
    _controller = TextEditingController();
    filteredProfessions = List.from(professions);
    filteredImages = List.from(professionImages);
    filteredRatings = List.from(ratings);
    filteredLiked = List.from(liked);
    _controller.addListener(() {
      String query = _controller.text.toLowerCase();
      setState(() {
        filteredProfessions.clear();
        filteredImages.clear();
        filteredRatings.clear();
        filteredLiked.clear();
        for (int i = 0; i < professions.length; i++) {
          if (professions[i].toLowerCase().contains(query)) {
            filteredProfessions.add(professions[i]);
            filteredImages.add(professionImages[i]);
            filteredRatings.add(ratings[i]);
            filteredLiked.add(liked[i]);
          }
        }
      });
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
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collectionGroup('messages')
                          .where(
                            'receiverId',
                            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                          )
                          .snapshots(),
                      builder: (context, snapshot) {
                        int unreadCount = 0;
                        if (snapshot.hasData) {
                          unreadCount = snapshot.data!.docs.length;
                        }
                        return Stack(
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
                        );
                      },
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      4,
                      (index) => Container(
                        width: 100,
                        height: 40,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          String category = doc['jobCategoryName'] ?? '';
                          providerCounts[category] =
                              (providerCounts[category] ?? 0) + 1;
                        }
                      }
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
                                              builder: (context) => CategoryProvidersScreen(
                                                categoryName: filteredProfessions[profIndex],
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
                                                              Radius.circular(30),
                                                          bottomRight:
                                                              Radius.circular(30),
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
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
                                                    scale: filteredLiked[profIndex]
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
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: Colors.white,
                                                          border: Border.all(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        child: Icon(
                                                          filteredLiked[profIndex]
                                                              ? Icons.favorite
                                                              : Icons
                                                                .favorite_border,
                                                          color: filteredLiked[profIndex]
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
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          filteredRatings[profIndex]
                                                              .toString(),
                                                          style: const TextStyle(
                                                            color: Colors.black,
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
                                              builder: (context) => CategoryProvidersScreen(
                                                categoryName: filteredProfessions[profIndex],
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
                                                              Radius.circular(30),
                                                          bottomRight:
                                                              Radius.circular(30),
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
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
                                                    scale: filteredLiked[profIndex]
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
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: Colors.white,
                                                          border: Border.all(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        child: Icon(
                                                          filteredLiked[profIndex]
                                                              ? Icons.favorite
                                                              : Icons
                                                                .favorite_border,
                                                          color: filteredLiked[profIndex]
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
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          filteredRatings[profIndex]
                                                              .toString(),
                                                          style: const TextStyle(
                                                            color: Colors.black,
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
