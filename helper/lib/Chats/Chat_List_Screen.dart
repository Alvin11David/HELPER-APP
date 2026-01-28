import 'package:flutter/material.dart';
import '../Components/Bottom_Nav_Bar.dart';
import 'Chat_Screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scale = 1.0;
  bool hasMessages = false;
  List<Map<String, dynamic>> chats = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchChats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchChats() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No current user');
      return;
    }
    print('Fetching chats for user: ${user.uid}');

    // Query chats where current user is employer or provider
    QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('employerId', isEqualTo: user.uid)
        .get();

    QuerySnapshot providerChats = await FirebaseFirestore.instance
        .collection('chats')
        .where('providerId', isEqualTo: user.uid)
        .get();

    List<QueryDocumentSnapshot> allChats = [
      ...chatSnapshot.docs,
      ...providerChats.docs,
    ];

    print('Found ${allChats.length} chat documents');

    List<Map<String, dynamic>> fetchedChats = [];
    for (var doc in allChats) {
      String chatId = doc.id;
      print('Checking chat: $chatId');
      // Check if there are messages in the subcollection
      QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      print('Messages in $chatId: ${messagesSnapshot.docs.length}');
      if (messagesSnapshot.docs.isNotEmpty) {
        var lastMessageDoc = messagesSnapshot.docs.first;
        String otherId = doc['employerId'] == user.uid
            ? doc['providerId']
            : doc['employerId'];
        bool isEmployer = doc['employerId'] == user.uid;

        // Fetch online status and business name
        bool isOnline = false;
        String businessName = '';
        List<String> portfolioFiles = [];
        String? photoUrl;
        String? fullName;
        try {
          DocumentSnapshot userDoc;
          if (isEmployer) {
            // If current user is employer, other is provider
            userDoc = await FirebaseFirestore.instance
                .collection('serviceProviders')
                .doc(otherId)
                .get();
            if (userDoc.exists) {
              final data = userDoc.data() as Map<String, dynamic>?;
              businessName =
                  data?['businessName'] ??
                  fullName ??
                  data?['name'] ??
                  'Unknown';
            }
          } else {
            // If current user is provider, other is employer
            userDoc = await FirebaseFirestore.instance
                .collection('Sign Up')
                .doc(otherId)
                .get();
            if (userDoc.exists) {
              final data = userDoc.data() as Map<String, dynamic>?;
              fullName = data?['fullName'];
              photoUrl = data?['photoUrl'];
              businessName =
                  fullName ??
                  data?['businessName'] ??
                  data?['name'] ??
                  'Unknown';
            }
            // Fetch isOnline from users collection
            final userDocForOnline = await FirebaseFirestore.instance
                .collection('users')
                .doc(otherId)
                .get();
            if (userDocForOnline.exists) {
              final data = userDocForOnline.data() as Map<String, dynamic>?;
              isOnline = data?['isOnline'] ?? false;
            }
          }
        } catch (e) {
          print('Error fetching user data for $otherId: $e');
        }

        String lastMessage = '';
        if (lastMessageDoc.data() != null) {
          final data = lastMessageDoc.data()! as Map<String, dynamic>;
          if (data['type'] == 'image') {
            lastMessage = 'Image';
          } else {
            lastMessage = data['text'] ?? data['message'] ?? '';
          }
        }
        fetchedChats.add({
          'chatId': chatId,
          'otherId': otherId,
          'businessName': businessName,
          'lastMessage': lastMessage,
          'timestamp': lastMessageDoc['timestamp'],
          'isEmployer': isEmployer,
          'isOnline': isOnline,
          'portfolioFiles': portfolioFiles,
          'fullName': fullName,
          'photoUrl': photoUrl,
        });
        print('Added chat: $businessName');
      }
    }

    setState(() {
      chats = fetchedChats;
      hasMessages = chats.isNotEmpty;
    });
    print('hasMessages: $hasMessages, chats count: ${chats.length}');
  }

  Widget _getProfileImage(Map<String, dynamic> chat, double size) {
    String? imageUrl;
    if (chat['photoUrl'] != null && chat['photoUrl'].toString().isNotEmpty) {
      imageUrl = chat['photoUrl'];
    } else if ((chat['portfolioFiles'] as List<String>).isNotEmpty) {
      imageUrl = (chat['portfolioFiles'] as List<String>)[0];
    }

    if (imageUrl != null) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, color: Colors.black),
        ),
      );
    } else {
      return const Icon(Icons.person, color: Colors.black);
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    int hour = dateTime.hour;
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String period = hour < 12 ? 'AM' : 'PM';
    int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
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
                          children: chats.map((chat) {
                            return Padding(
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
                                        child: _getProfileImage(
                                          chat,
                                          screenWidth * 0.12,
                                        ),
                                      ),
                                      if (chat['isOnline'] == true)
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
                                    chat['businessName'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.03,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (hasMessages) SizedBox(height: 20),
                    hasMessages
                        ? Column(
                            children: chats.map((chat) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        businessName: chat['businessName'],
                                        providerId: chat['isEmployer']
                                            ? chat['otherId']
                                            : FirebaseAuth
                                                  .instance
                                                  .currentUser!
                                                  .uid,
                                        employerId: chat['isEmployer']
                                            ? FirebaseAuth
                                                  .instance
                                                  .currentUser!
                                                  .uid
                                            : chat['otherId'],
                                      ),
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
                                            child: _getProfileImage(chat, 40),
                                          ),
                                          if (chat['isOnline'] == true)
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
                                            chat['businessName'],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            chat['lastMessage'],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatTime(chat['timestamp']),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
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
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
    );
  }
}
