import 'dart:ui';

import 'package:flutter/material.dart';

class AcademicCertificateUploadScreen extends StatelessWidget {
  const AcademicCertificateUploadScreen({Key? key}) : super(key: key);

  static const List<String> professions = [
    'Accountant',
    'Actor',
    'Actuary',
    'Architect',
    'Astronomer',
    'Author',
    'Baker',
    'Banker',
    'Barber',
    'Bartender',
    'Biologist',
    'Bookkeeper',
    'Builder',
    'Business Analyst',
    'Butcher',
    'Carpenter',
    'Cashier',
    'Chef',
    'Chemist',
    'Civil Engineer',
    'Cleaner',
    'Clerk',
    'Coach',
    'Computer Programmer',
    'Consultant',
    'Cook',
    'Counselor',
    'Dentist',
    'Designer',
    'Developer',
    'Dietitian',
    'Doctor',
    'Driver',
    'Economist',
    'Editor',
    'Electrician',
    'Engineer',
    'Farmer',
    'Firefighter',
    'Fisherman',
    'Florist',
    'Gardener',
    'Graphic Designer',
    'Hairdresser',
    'Historian',
    'Housekeeper',
    'Inspector',
    'Instructor',
    'Interpreter',
    'Janitor',
    'Journalist',
    'Judge',
    'Lawyer',
    'Librarian',
    'Machinist',
    'Manager',
    'Marketing Specialist',
    'Mathematician',
    'Mechanic',
    'Model',
    'Musician',
    'Nurse',
    'Nutritionist',
    'Optometrist',
    'Painter',
    'Pharmacist',
    'Photographer',
    'Physician',
    'Physicist',
    'Pilot',
    'Plumber',
    'Police Officer',
    'Politician',
    'Professor',
    'Programmer',
    'Psychologist',
    'Receptionist',
    'Researcher',
    'Salesperson',
    'Scientist',
    'Secretary',
    'Singer',
    'Social Worker',
    'Software Engineer',
    'Soldier',
    'Statistician',
    'Student',
    'Surgeon',
    'Teacher',
    'Technician',
    'Therapist',
    'Translator',
    'Veterinarian',
    'Waiter',
    'Waitress',
    'Web Designer',
    'Welder',
    'Writer',
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
                      'Academic Certificates',
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
            top: screenHeight * 0.14, // Adjusted to reduce space from header
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
                        'Search or add your professiona/Job',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
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
            top: screenHeight * 0.14 + 53,
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
                            fontSize: screenWidth * 0.05,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600
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
                                final String option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option),
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
