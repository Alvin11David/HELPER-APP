import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 77,
      width: MediaQuery.of(context).size.width,
      color: Color(0xFFFFCB05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.home, color: Colors.black),
          Icon(Icons.search, color: Colors.black),
          Icon(Icons.person, color: Colors.black),
        ],
      ),
    );
  }
}
