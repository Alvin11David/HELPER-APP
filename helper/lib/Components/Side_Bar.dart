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
    final sidebarWidth = 210.0; // Adjust as needed

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
            margin: const EdgeInsets.only(top: 20, left: 20), // Padding from top and left
            width: screenWidth * 0.18 > 70 ? 70 : screenWidth * 0.18, // Max 70, responsive
            height: screenWidth * 0.18 > 70 ? 70 : screenWidth * 0.18,
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
