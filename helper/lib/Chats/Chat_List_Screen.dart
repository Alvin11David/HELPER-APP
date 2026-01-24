import 'package:flutter/material.dart';
import '../Components/Bottom_Nav_Bar.dart';
import 'Chat_Screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scale = 1.0;
  bool hasMessages = true; // Set to true when there are actual messages

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Add navigation logic here based on the tapped index
    print('Bottom nav item tapped: $index');
  }

  void _onScroll() {
    const double maxScroll = 100.0;
    const double minScale = 0.7;
    double offset = _scrollController.offset;
    double newScale = 1.0 - (offset / maxScroll) * (1.0 - minScale);
    newScale = newScale.clamp(minScale, 1.0);
    if (newScale != _scale) {
      setState(() {
        _scale = newScale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
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
              child: Transform.scale(
                scale: _scale,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
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
                      ],
                    ),
                    SizedBox(width: screenWidth * 0.025),
                    Stack(
                      children: [
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
                  ],
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.03,
              left: screenWidth * 0.04,
              child: Transform.scale(
                scale: _scale,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.1,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              bottom: 0,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 16),
                          Icon(Icons.search, color: Colors.black),
                          SizedBox(width: 5),
                          Text(
                            'Search here...',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    if (hasMessages)
                      SizedBox(
                        height: screenWidth * 0.2,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: List.generate(
                            9,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9.0,
                              ),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: screenWidth * 0.12,
                                        height: screenWidth * 0.12,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Color.fromARGB(
                                              255,
                                              0,
                                              233,
                                              8,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Names',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.03,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (hasMessages) SizedBox(height: 20),
                    hasMessages
                        ? Column(
                            children: List.generate(
                              20,
                              (index) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Names',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Hey there',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        'dd/mm/yyyy',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            height: screenHeight * 0.8,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.message,
                                  color: Colors.white,
                                  size: screenWidth * 0.2,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Get in touch with any service provider to start a conversation here',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        onItemTapped: _onItemTapped,
        currentIndex: 2,
      ),
    );
  }
}
