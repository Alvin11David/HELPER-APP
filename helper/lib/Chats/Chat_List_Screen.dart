import 'package:flutter/material.dart';

class ChatListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/background/normalscreenbg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: screenWidth * 0.05,
                  right: screenWidth * 0.04,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: screenWidth * 0.12,
                        height: screenWidth * 0.12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.black),
                      ),
                      SizedBox(width: screenWidth * 0.025),
                      Container(
                        width: screenWidth * 0.12,
                        height: screenWidth * 0.12,
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
                  top: 0,
                  left: screenWidth * 0.04,
                  child: Text(
                    'Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: screenWidth * 0.1,
            left: screenWidth * 0.04,
            child: Text(
              'Messages',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
