import 'package:flutter/material.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> with SingleTickerProviderStateMixin {
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
    final sidebarWidth = 300.0; // Adjust as needed

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
              top: screenHeight * 0.05, // 5% margin from top
              bottom: screenHeight * 0.05, // 5% margin from bottom
              width: sidebarWidth,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Header or close button
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: toggleDrawer,
                        ),
                      ),
                      // Add your sidebar content here
                      Expanded(
                        child: ListView(
                          children: const [
                            ListTile(title: Text('Menu Item 1')),
                            ListTile(title: Text('Menu Item 2')),
                            ListTile(title: Text('Menu Item 3')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
