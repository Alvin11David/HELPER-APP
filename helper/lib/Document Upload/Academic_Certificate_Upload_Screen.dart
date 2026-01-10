import 'dart:ui';

import 'package:flutter/material.dart';

class AcademicCertificateUploadScreen extends StatefulWidget {
  const AcademicCertificateUploadScreen({Key? key}) : super(key: key);
  static List<String> professions = [];

  @override
  State<AcademicCertificateUploadScreen> createState() =>
      _AcademicCertificateUploadScreenState();
}

class _AcademicCertificateUploadScreenState
    extends State<AcademicCertificateUploadScreen> {
  late List<String> searchHistory;
  late List<String> selectedProfessions;

  @override
  void initState() {
    super.initState();
    searchHistory = [];
    selectedProfessions = [];
  }

  static List<String> professions = [
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
    // Science & Research
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
    // Health & Medical
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
    // Law & Governance
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
    // Engineering & Technical
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
    // ICT & Emerging Tech
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
    // Education & Academia
    'Lecturer',
    'Senior Lecturer',
    'Dean',
    'Academic Registrar',
    'Education Officer',
    'Curriculum Developer',
    'Instructional Designer',
    'Education Psychologist',
    // Business, Economics & Finance
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
    // Social Sciences & Humanities
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background/normalscreenbg.png',
            fit: BoxFit.cover,
          ),
          Positioned(
            top: screenWidth * 0.1,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
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
                      'Academic Profession',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.16, // Adjusted to reduce space from header
            left: screenWidth * 0.12,
            right: screenWidth * 0.12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02,
                    vertical: screenHeight * 0.004,
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
                  height: 33,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Search or add your profession/Job',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: screenHeight * 0.17 + 53,
            left: (screenWidth - 290) / 2,
            child: Container(
              width: 290,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return professions.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    if (!searchHistory.contains(selection)) {
                      searchHistory.insert(0, selection);
                      if (searchHistory.length > 5) searchHistory.removeLast();
                    }
                    if (!selectedProfessions.contains(selection)) {
                      selectedProfessions.add(selection);
                    }
                  });
                },
                fieldViewBuilder:
                    (
                      BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted,
                    ) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.black),
                          hintText: 'Search your Profession here',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: screenWidth * 0.045,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      );
                    },
                optionsViewBuilder:
                    (
                      BuildContext context,
                      AutocompleteOnSelected<String> onSelected,
                      Iterable<String> options,
                    ) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Material(
                            elevation: 4.0,
                            child: Container(
                              width: 290,
                              constraints: BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(
                                    index,
                                  );
                                  return ListTile(
                                    leading: Icon(
                                      Icons.search,
                                      color: Colors.black,
                                    ),
                                    title: Text(
                                      option,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
              ),
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.13,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.18,
            left: (screenWidth - 290) / 2,
            child: Container(
              width: 290,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFBBC04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/academic.png',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedProfessions.isEmpty
                        ? 'Selected Professions will appear here'
                        : selectedProfessions.join(', '),
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.05,
            left: (screenWidth - 290) / 2,
            child: Container(
              width: 290,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    'Add Your Profession',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
