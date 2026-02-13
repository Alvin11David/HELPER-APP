import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helper/Components/User_Name.dart';
import 'package:helper/Components/Worker_Profession.dart';
import 'package:helper/Components/User_Avatar_Circle.dart';
import 'package:helper/Verfication/RoleSelectionVerification.dart';
import '../Document Upload/Profile/Profile_Screen.dart';
import '../Auth/Sign_In_Screen.dart';
import '../Employer Dashboard/Employer_Dashboard_Screen.dart';
import '../Employer Dashboard/My_Bookings_Screen.dart';
import '../Worker Dashboard/Workers_Dashboard_Screen.dart';
import '../Worker Dashboard/Worker_Ratings_Reviews_Screen.dart';
import '../Document Upload/Profile/Support_Screen.dart';
import '../Intro/Role_Selection_Screen.dart';
import '../Escrow/Finished_Job_Code_Screen.dart';
import '../Escrow/Cancellation_Code_Screen.dart';

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
        String? activeRole =
            (doc.data() as Map<String, dynamic>)['activeRole'] as String?;
        if (activeRole != null) return activeRole;
        String? role = (doc.data() as Map<String, dynamic>)['role'] as String?;
        return role;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _hasWorkerData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _hasEmployerData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _switchRole(String newRole) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      Map<String, dynamic> updates = {'activeRole': newRole, 'role': newRole};
      await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .update(updates);
      if (!mounted) return false;
      setState(() => _userRole = newRole);
      return true;
    } catch (e) {
      print('Error switching role: $e');
      return false;
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

  Future<void> _openLatestCompletionCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Temporary: fetch all completed_pending jobs and sort in-memory
      // Once the Firestore index is built, you can revert to the commented query below
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('employerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed_pending')
          .get();

      if (snap.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No jobs awaiting completion code.')),
        );
        return;
      }

      // Sort by updatedAt in-memory
      final sortedDocs = snap.docs.toList()
        ..sort((a, b) {
          final aTime = (a.data()['updatedAt'] as Timestamp?)?.toDate();
          final bTime = (b.data()['updatedAt'] as Timestamp?)?.toDate();
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // descending
        });

      final bookingId = sortedDocs.first.id;
      if (!mounted) return;
      toggleDrawer();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FinishedJobCodeScreen(bookingId: bookingId),
        ),
      );

      /* Original query (requires index):
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('employerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed_pending')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();
      */
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load completion code: $e')),
      );
    }
  }

  Future<void> _openLatestCancellationCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Query Escrow collection for pending cancellations where user is the receiver
      final snap = await FirebaseFirestore.instance
          .collection('Escrow')
          .where('cancellationStatus', isEqualTo: 'pending')
          .where('cancellationReceiverId', isEqualTo: user.uid)
          .get();

      if (snap.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pending cancellations.')),
        );
        return;
      }

      // Sort by cancellationRequestedAt in-memory
      final sortedDocs = snap.docs.toList()
        ..sort((a, b) {
          final aTime = (a.data()['cancellationRequestedAt'] as Timestamp?)
              ?.toDate();
          final bTime = (b.data()['cancellationRequestedAt'] as Timestamp?)
              ?.toDate();
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // descending
        });

      final bookingId = sortedDocs.first.data()['bookingId'] as String?;
      if (bookingId == null || bookingId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid booking ID.')));
        return;
      }

      if (!mounted) return;
      toggleDrawer();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CancellationCodeScreen(bookingId: bookingId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load cancellation code: $e')),
      );
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
                          child: UserAvatarCircle(role: _userRole),
                        ),
                      ),
                      // Add Worker's Name text below the circle
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: UserName(role: _userRole),
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
                          if (_userRole == 'employer')
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedIndex = 2);
                                _openLatestCompletionCode();
                              },
                              child: Padding(
                                padding: EdgeInsets.only(left: 8, right: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: _selectedIndex == 2
                                          ? Colors.orange
                                          : Colors.black.withOpacity(0.6),
                                    ),
                                    SizedBox(width: 15),
                                    Flexible(
                                      child: Text(
                                        'Enter Completion Code',
                                        style: TextStyle(
                                          color: _selectedIndex == 2
                                              ? Colors.orange
                                              : Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                                                  RoleSelectionVerificationScreen(),
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
                          if (_userRole == 'worker')
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedIndex = 3);
                                _openLatestCancellationCode();
                              },
                              child: Padding(
                                padding: EdgeInsets.only(left: 8, right: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.cancel_outlined,
                                      color: _selectedIndex == 3
                                          ? Colors.orange
                                          : Colors.black.withOpacity(0.6),
                                    ),
                                    SizedBox(width: 15),
                                    Flexible(
                                      child: Text(
                                        'Enter Cancellation Code',
                                        style: TextStyle(
                                          color: _selectedIndex == 3
                                              ? Colors.orange
                                              : Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_userRole == 'worker') const SizedBox(height: 20),
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
                                final didSwitch = await _switchRole('worker');
                                if (!didSwitch || !mounted) return;
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
                                final didSwitch = await _switchRole('employer');
                                if (!didSwitch || !mounted) return;
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
                          const SizedBox(height: 15),
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
                          if (_userRole == 'worker') const SizedBox(height: 10),
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
                          if (_userRole == 'worker') const SizedBox(height: 15),
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
