import 'package:flutter/material.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => SideBarState();
}

class SideBarState extends State<SideBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = 230.0; // Adjust as needed

    return Stack(
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
                    Container(
                      margin: EdgeInsets.only(
                        top: 20,
                        right: screenWidth * 0.47,
                      ), // Padding from top and left
                      width: screenWidth * 0.20 > 70
                          ? 70
                          : screenWidth * 0.20, // Max 70, responsive
                      height: screenWidth * 0.20 > 70 ? 70 : screenWidth * 0.20,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    // Add Worker's Name text below the circle
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            "Worker's Name",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                              SizedBox(width: 16), // space between label and ID
                              Text(
                                "ID Number", // Replace with actual ID if needed
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            "Profession",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
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
                        Padding(
                          padding: EdgeInsets.only(left: 8, right: 8),
                          child: Row(
                            children: [
                              Icon(Icons.home, color: Colors.black.withOpacity(0.6)),
                              SizedBox(width: 15),
                              Text(
                                "Home",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.only(left: 8, right: 8),
                          child: Row(
                            children: [
                              Icon(Icons.receipt_long, color: Colors.black.withOpacity(0.6)),
                              SizedBox(width: 15),
                              Text(
                                "My Jobs",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.only(left: 8, right: 8),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, color: Colors.black.withOpacity(0.6)),
                              SizedBox(width: 15),
                              Text(
                                "Availability & Schedule",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.only(left: 8, right: 8),
                          child: Row(
                            children: [
                              Icon(Icons.star, color: Colors.black.withOpacity(0.6)),
                              SizedBox(width: 15),
                              Text(
                                "Ratings & Reviews",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.only(left: 8, right: 8),
                          child: Row(
                            children: [
                              Icon(Icons.support_agent, color: Colors.black.withOpacity(0.6)),
                              SizedBox(width: 15),
                              Text(
                                "Support",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.only(left: 8, right: 8),
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.black.withOpacity(0.6)),
                              SizedBox(width: 15),
                              Text(
                                "Profile",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.only(left: 8, right: 8),
                          child: Row(
                            children: [
                              Icon(Icons.receipt, color: Colors.black.withOpacity(0.6)),
                              SizedBox(width: 15),
                              Text(
                                "Privacy Policy",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.only(left: 8, right: 8),
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.black.withOpacity(0.6)),
                              SizedBox(width: 15),
                              Text(
                                "Log Out",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
