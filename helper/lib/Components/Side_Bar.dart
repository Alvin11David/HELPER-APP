import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helper/Components/User_Name.dart';
import 'package:helper/Components/Worker_Profession.dart';
import 'package:helper/Components/User_Avatar_Circle.dart'; // Add this import
import '../Document Upload/Profile/Profile_Screen.dart'; // Add this import
import '../Auth/Sign_In_Screen.dart'; // Add this import
import '../Employer Dashboard/Employer_Dashboard_Screen.dart';
import '../Employer Dashboard/My_Bookings_Screen.dart';
import '../Worker Dashboard/Workers_Dashboard_Screen.dart';
import '../Worker Dashboard/Worker_Ratings_Reviews_Screen.dart';
import '../Document Upload/Profile/Support_Screen.dart'; // Add this import
import '../Intro/Role_Selection_Screen.dart'; // Add this import

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => SideBarState();
}

class SideBarState extends State<SideBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isOpen = false;
  int _selectedIndex = -1;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole().then((role) => setState(() => _userRole = role));
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -300,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleDrawer() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<String?> _fetchReferralCode() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['referralCode'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _fetchUserRole() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        String? role = (doc.data() as Map<String, dynamic>)['role'] as String?;
        print('Fetched user role: $role'); // Debug print
        return role;
      }
      print('User document does not exist or has no data'); // Debug print
      return null;
    } catch (e) {
      print('Error fetching user role: $e'); // Debug print
      return null;
    }
  }

  Future<bool> _hasWorkerData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('serviceProviders')
          .doc(user.uid)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> _switchRole(String newRole) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .update({'role': newRole});
      setState(() => _userRole = newRole);
    } catch (e) {
      print('Error switching role: $e');
    }
  }

  Future<bool?> _fetchVerifiedStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['verified'] as bool?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = 230.0; // Adjust as needed

    return SafeArea(
      child: Stack(
        children: [
          // Semi-transparent background when open
          if (_isOpen)
            GestureDetector(
              onTap: toggleDrawer,
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          // The sliding sidebar
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                left: _animation.value,
                top: screenHeight * 0, // 5% margin from top
                bottom: screenHeight * 0.05, // 5% margin from bottom
                width: sidebarWidth,
                child: Material(
                  // <-- Wrap with Material
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  child: Column(
                    children: [
                      // Add your sidebar content here
                      // Replace the black circle Container with UserAvatarCircle
                      Padding(
                        padding: EdgeInsets.only(
                          top: 20,
                          right: screenWidth * 0.40, // adjust if needed
                        ),
                        child: Container(
                          width: 80, // increased width
                          height: 80, // increased height
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: UserAvatarCircle(),
                        ),
                      ),
                      // Add Worker's Name text below the circle
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: UserName(),
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Row(
                              children: [
                                Text(
                                  "Referral ID:",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(
                                  width: 16,
                                ), // space between label and ID
                                FutureBuilder<String?>(
                                  future: _fetchReferralCode(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text(
                                        'Loading...',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      );
                                    }
                                    return Text(
                                      snapshot.data ?? 'No ID',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: FutureBuilder<String?>(
                              future: _fetchUserRole(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox.shrink();
                                }
                                if (snapshot.hasData &&
                                    snapshot.data == 'worker') {
                                  return WorkerProfession();
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            height: 1,
                            margin: EdgeInsets.symmetric(
                              horizontal: 0,
                            ), // touches left and right
                            color: Colors.black,
                          ),
                          const SizedBox(height: 20),
                          if (_userRole == 'employer')
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedIndex = 1);
                                toggleDrawer();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MyBookingsScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.only(left: 8, right: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.book_online,
                                      color: _selectedIndex == 1
                                          ? Colors.orange
                                          : Colors.black.withOpacity(0.6),
                                    ),
                                    SizedBox(width: 15),
                                    Text(
                                      "My Bookings",
                                      style: TextStyle(
                                        color: _selectedIndex == 1
                                            ? Colors.orange
                                            : Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_userRole == 'employer')
                            const SizedBox(height: 20),
                          if (_userRole != 'employer') ...[
                            FutureBuilder<bool?>(
                              future: _fetchVerifiedStatus(),
                              builder: (context, snapshot) {
                                bool isVerified = snapshot.data ?? false;
                                return GestureDetector(
                                  onTap: !isVerified
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  RoleSelectionScreen(),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8, right: 8),
                                    child: Row(
                                      children: [
                                        Text(
                                          "Verified?",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Spacer(),
                                        Text(
                                          snapshot.connectionState ==
                                                  ConnectionState.waiting
                                              ? 'Loading...'
                                              : (isVerified ? 'Yes' : 'No'),
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                          GestureDetector(
                            onTap: () async {
                              try {
                                User? user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  DocumentSnapshot doc = await FirebaseFirestore
                                      .instance
                                      .collection('Sign Up')
                                      .doc(user.uid)
                                      .get();
                                  if (doc.exists && doc.data() != null) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    String role = data['role'] ?? '';
                                    toggleDrawer();
                                    if (role == 'employer') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EmployerDashboardScreen(),
                                        ),
                                      );
                                    } else if (role == 'worker') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              WorkersDashboardScreen(),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Role not found'),
                                        ),
                                      );
                                    }
                                  }
                                }
                              } catch (e) {
                                print('Error fetching role: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error loading dashboard'),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.only(left: 8, right: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.home,
                                    color: _selectedIndex == 0
                                        ? Colors.orange
                                        : Colors.black.withOpacity(0.6),
                                  ),
                                  SizedBox(width: 15),
                                  Text(
                                    "Home",
                                    style: TextStyle(
                                      color: _selectedIndex == 0
                                          ? Colors.orange
                                          : Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Switch role row
                          if (_userRole == 'employer') 
                            GestureDetector(
                              onTap: () async {
                                // Switch to worker
                                await _switchRole('worker');
                                toggleDrawer();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const WorkersDashboardScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.only(left: 8, right: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.swap_horiz,
                                      color: Colors.black.withOpacity(0.6),
                                    ),
                                    SizedBox(width: 15),
                                    Text(
                                      "Switch to Worker",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (_userRole == 'worker')
                            GestureDetector(
                              onTap: () async {
                                // Switch to employer
                                await _switchRole('employer');
                                toggleDrawer();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EmployerDashboardScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.only(left: 8, right: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.swap_horiz,
                                      color: Colors.black.withOpacity(0.6),
                                    ),
                                    SizedBox(width: 15),
                                    Text(
                                      "Switch to Employer",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          if (_userRole == 'worker') ...[
                            GestureDetector(
                              onTap: () => setState(() => _selectedIndex = 1),
                              child: Padding(
                                padding: EdgeInsets.only(left: 8, right: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      color: _selectedIndex == 1
                                          ? Colors.orange
                                          : Colors.black.withOpacity(0.6),
                                    ),
                                    SizedBox(width: 15),
                                    Text(
                                      "My Jobs",
                                      style: TextStyle(
                                        color: _selectedIndex == 1
                                            ? Colors.orange
                                            : Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (_userRole == 'worker') const SizedBox(height: 15),
                          if (_userRole == 'worker')
                            GestureDetector(
                              onTap: () => setState(() => _selectedIndex = 2),
                              child: Padding(
                                padding: EdgeInsets.only(left: 8, right: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      color: _selectedIndex == 2
                                          ? Colors.orange
                                          : Colors.black.withOpacity(0.6),
                                    ),
                                    SizedBox(width: 15),
                                    Text(
                                      "Availability &\nSchedule",
                                      style: TextStyle(
                                        color: _selectedIndex == 2
                                            ? Colors.orange
                                            : Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_userRole == 'worker') const SizedBox(height: 20),
                          if (_userRole == 'worker')
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const WorkerRatingsReviewsScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.only(left: 8, right: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: _selectedIndex == 3
                                          ? Colors.orange
                                          : Colors.black.withOpacity(0.6),
                                    ),
                                    SizedBox(width: 15),
                                    Text(
                                      "Ratings & Reviews",
                                      style: TextStyle(
                                        color: _selectedIndex == 3
                                            ? Colors.orange
                                            : Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_userRole == 'worker') const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SupportScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(left: 8, right: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.support_agent,
                                    color: _selectedIndex == 4
                                        ? Colors.orange
                                        : Colors.black.withOpacity(0.6),
                                  ),
                                  SizedBox(width: 15),
                                  Text(
                                    "Support",
                                    style: TextStyle(
                                      color: _selectedIndex == 4
                                          ? Colors.orange
                                          : Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () async {
                              setState(() => _selectedIndex = 7);
                              toggleDrawer();
                              await FirebaseAuth.instance.signOut();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(left: 8, right: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: _selectedIndex == 5
                                        ? Colors.orange
                                        : Colors.black.withOpacity(0.6),
                                  ),
                                  SizedBox(width: 15),
                                  Text(
                                    "Profile",
                                    style: TextStyle(
                                      color: _selectedIndex == 5
                                          ? Colors.orange
                                          : Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(left: 8, right: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.receipt,
                                    color: _selectedIndex == 6
                                        ? Colors.orange
                                        : Colors.black.withOpacity(0.6),
                                  ),
                                  SizedBox(width: 15),
                                  Text(
                                    "Privacy Policy",
                                    style: TextStyle(
                                      color: _selectedIndex == 6
                                          ? Colors.orange
                                          : Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () async {
                              setState(() => _selectedIndex = 7);
                              toggleDrawer();
                              await FirebaseAuth.instance.signOut();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SignInScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(left: 8, right: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: _selectedIndex == 7
                                        ? Colors.orange
                                        : Colors.black.withOpacity(0.6),
                                  ),
                                  SizedBox(width: 15),
                                  Text(
                                    "Log Out",
                                    style: TextStyle(
                                      color: _selectedIndex == 7
                                          ? Colors.orange
                                          : Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_userRole != 'employer')
                            FutureBuilder<bool?>(
                              future: _fetchVerifiedStatus(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox.shrink();
                                }
                                bool isVerified = snapshot.data ?? false;
                                if (!isVerified) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8,
                                      right: 8,
                                    ),
                                    child: Text(
                                      "Tap the Verified Row to Re upload the valid documents",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
