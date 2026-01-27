import 'package:flutter/material.dart';
import 'package:helper/Components/User_Name.dart';

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
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
    'Plumbers',
    'Electricians',
    'Engineers',
    'Drivers',
    'Cleaners',
    'Gardeners',
    'Painters',
    'Mechanics',
    'Chefs',
    'Tutors',
    'Doctors',
    'Lawyers',
    'Photographers',
    'Designers',
    'Writers',
    'Musicians',
    'Nurses',
    'Pharmacists',
    'Dentists',
    'Surgeons',
    'Accountants',
    'Managers',
    'Sales Representatives',
    'Consultants',
    'Programmers',
    'Data Scientists',
    'Teachers',
    'Professors',
    'Actors',
    'Artists',
    'Architects',
    'Carpenters',
    'Welders',
    'HVAC Technicians',
    'Locksmiths',
    'Pest Control Specialists',
    'Housekeepers',
    'Nannies',
    'Personal Trainers',
    'Massage Therapists',
    'Hair Stylists',
    'Makeup Artists',
    'Event Planners',
    'Florists',
    'Caterers',
    'Bartenders',
    'Waiters',
    'Librarians',
    'Tour Guides',
    'Translators',
    'IT Support Specialists',
    'Web Developers',
    'Fashion Designers',
    'Interior Designers',
    'Civil Engineers',
    'Mechanical Engineers',
    'Software Engineers',
    'Data Analysts',
    'Scientists',
    'Researchers',
    'Journalists',
    'Editors',
    'Public Relations Specialists',
    'Marketing Specialists',
  ];
  List<String> professionImages = [
    'assets/images/plumbers.png',
    'assets/images/electricians.png',
    'assets/images/engineers.png',
    'assets/images/drivers.png',
    'assets/images/cleaners.png',
    'assets/images/gardeners.png',
    'assets/images/painters.png',
    'assets/images/mechanics.png',
    'assets/images/chefs.png',
    'assets/images/tutors.png',
    'assets/images/doctors.png',
    'assets/images/lawyers.png',
    'assets/images/photographers.png',
    'assets/images/designers.png',
    'assets/images/writers.png',
    'assets/images/musicians.png',
    'assets/images/nurses.png',
    'assets/images/pharmacists.png',
    'assets/images/dentists.png',
    'assets/images/surgeons.png',
    'assets/images/accountants.png',
    'assets/images/managers.png',
    'assets/images/sales_representatives.png',
    'assets/images/consultants.png',
    'assets/images/programmers.png',
    'assets/images/data_scientists.png',
    'assets/images/teachers.png',
    'assets/images/professors.png',
    'assets/images/actors.png',
    'assets/images/artists.png',
    'assets/images/architects.png',
    'assets/images/carpenters.png',
    'assets/images/welders.png',
    'assets/images/hvac_technicians.png',
    'assets/images/locksmiths.png',
    'assets/images/pest_control_specialists.png',
    'assets/images/housekeepers.png',
    'assets/images/nannies.png',
    'assets/images/personal_trainers.png',
    'assets/images/massage_therapists.png',
    'assets/images/hair_stylists.png',
    'assets/images/makeup_artists.png',
    'assets/images/event_planners.png',
    'assets/images/florists.png',
    'assets/images/caterers.png',
    'assets/images/bartenders.png',
    'assets/images/waiters.png',
    'assets/images/librarians.png',
    'assets/images/tour_guides.png',
    'assets/images/translators.png',
    'assets/images/it_support_specialists.png',
    'assets/images/web_developers.png',
    'assets/images/fashion_designers.png',
    'assets/images/interior_designers.png',
    'assets/images/civil_engineers.png',
    'assets/images/mechanical_engineers.png',
    'assets/images/software_engineers.png',
    'assets/images/data_analysts.png',
    'assets/images/scientists.png',
    'assets/images/researchers.png',
    'assets/images/journalists.png',
    'assets/images/editors.png',
    'assets/images/public_relations_specialists.png',
    'assets/images/marketing_specialists.png',
  ];
  List<double> ratings = [
    4.9,
    4.2,
    3.8,
    4.5,
    2.3,
    4.1,
    3.9,
    4.7,
    4.0,
    3.5,
    4.3,
    2.8,
    4.6,
    3.2,
    4.4,
    3.7,
    4.8,
    4.1,
    3.9,
    4.4,
    2.5,
    4.2,
    3.8,
    4.6,
    4.1,
    3.6,
    4.2,
    2.9,
    4.5,
    3.3,
    4.3,
    3.8,
    4.7,
    4.0,
    3.5,
    4.3,
    2.8,
    4.6,
    3.2,
    4.4,
    3.7,
    4.8,
    4.1,
    3.9,
    4.4,
    2.5,
    4.2,
    3.8,
    4.6,
    4.1,
    3.6,
    4.2,
    2.9,
    4.5,
    3.3,
    4.3,
    3.8,
    4.7,
    4.0,
    3.5,
    4.3,
    2.8,
    4.6,
    3.2,
  ];
  List<bool> liked = List.generate(64, (index) => false);
  List<String> filteredProfessions = [];
  List<String> filteredImages = [];
  List<double> filteredRatings = [];
  List<bool> filteredLiked = [];
  bool showSuggestions = false;
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
        showSuggestions = query.isNotEmpty;
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
              if (showSuggestions)
                Positioned(
                  top: 120,
                  left: w * 0.2,
                  right: w * 0.04,
                  height: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
                    ),
                    child: ListView.builder(
                      itemCount: suggestions.where((s) => s.toLowerCase().contains(_controller.text.toLowerCase())).length,
                      itemBuilder: (context, index) {
                        List<String> filteredSuggestions = suggestions.where((s) => s.toLowerCase().contains(_controller.text.toLowerCase())).toList();
                        return ListTile(
                          title: Text(filteredSuggestions[index]),
                          onTap: () {
                            _controller.text = filteredSuggestions[index];
                            setState(() {
                              showSuggestions = false;
                            });
                          },
                        );
                      },
                    ),
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
                  child: Builder(
                    builder: (context) {
                      int half = (filteredProfessions.length / 2).ceil();
                      return SingleChildScrollView(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: List.generate(
                                  half,
                                  (index) => Container(
                                width: 183,
                                height: 200,
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    image: AssetImage(filteredImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(30),
                                            bottomRight: Radius.circular(30),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              filteredProfessions[index],
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              'Number Providers',
                                              style: TextStyle(
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
                                        padding: const EdgeInsets.all(10),
                                        child: AnimatedScale(
                                          scale: filteredLiked[index] ? 1.2 : 1.0,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: GestureDetector(
                                            onTap: () => setState(
                                              () =>
                                                  filteredLiked[index] = !filteredLiked[index],
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
                                                filteredLiked[index]
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: filteredLiked[index]
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
                                        padding: const EdgeInsets.all(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.black,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.star,
                                                color: Colors.orange,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                filteredRatings[index].toString(),
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            children: List.generate(
                              half,
                              (index) {
                                int idx = index + half;
                                if (idx < filteredProfessions.length) {
                                  return Container(
                                    width: 183,
                                    height: 200,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      image: DecorationImage(
                                        image: AssetImage(
                                          filteredImages[idx],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Align(
                                          alignment: Alignment.bottomLeft,
                                          child: Container(
                                            width: double.infinity,
                                            color: Colors.white,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              borderRadius: const BorderRadius.only(
                                                bottomLeft: Radius.circular(30),
                                                bottomRight: Radius.circular(30),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  filteredProfessions[idx],
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Text(
                                                  'Number Providers',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.topLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(
                                                  10,
                                                ),
                                                border: Border.all(
                                                  color: Colors.black,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    color: Colors.orange,
                                                    size: 12,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    filteredRatings[idx].toString(),
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
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: AnimatedScale(
                                              scale: filteredLiked[idx] ? 1.2 : 1.0,
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child: GestureDetector(
                                                onTap: () => setState(
                                                  () =>
                                                      filteredLiked[idx] = !filteredLiked[idx],
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
                                                    filteredLiked[idx]
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color: filteredLiked[idx]
                                                        ? Colors.red
                                                        : Colors.black,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  return SizedBox.shrink();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                    },
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
