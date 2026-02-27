import 'package:flutter/material.dart';
import '../Components/Bottom_Nav_Bar.dart';
import '../Components/User_Avatar_Circle.dart';
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
  late Widget _avatarWidget;

  @override
  void initState() {
    super.initState();
    _avatarWidget = UserAvatarCircle();
    _scrollController.addListener(_onScroll);

    // Show current user info
    User? currentUser = FirebaseAuth.instance.currentUser;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Current User: ${currentUser.uid.substring(0, 15)}...',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user logged in!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No current user logged in')),
        );
      });
      return;
    }
    print('Fetching chats for user: ${user.uid}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fetching chats for: ${user.uid.substring(0, 10)}...',
          ),
        ),
      );
    });

    // Query chats where current user is employer or provider
    QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('employerId', isEqualTo: user.uid)
        .get();

    QuerySnapshot providerChats = await FirebaseFirestore.instance
      .collection('chats')
      .where('providerUid', isEqualTo: user.uid)
      .get();

    QuerySnapshot legacyProviderChats = await FirebaseFirestore.instance
      .collection('chats')
      .where('providerId', isEqualTo: user.uid)
      .get();

    final allChatsById = <String, QueryDocumentSnapshot>{};
    for (final doc in chatSnapshot.docs) {
      allChatsById[doc.id] = doc;
    }
    for (final doc in providerChats.docs) {
      allChatsById[doc.id] = doc;
    }
    for (final doc in legacyProviderChats.docs) {
      allChatsById[doc.id] = doc;
    }
    final allChats = allChatsById.values.toList();

    print('Employer chats found: ${chatSnapshot.docs.length}');
    print(
      'Provider chats found: ${providerChats.docs.length} (legacy: ${legacyProviderChats.docs.length})',
    );
    print('Total chats found: ${allChats.length}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Found: ${chatSnapshot.docs.length} as employer, ${providerChats.docs.length} as provider',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    });

    for (var doc in allChats) {
      print('Chat document ID: ${doc.id}');
      print('Chat data: ${doc.data()}');
    }

    List<Map<String, dynamic>> fetchedChats = [];
    for (var doc in allChats) {
      String chatId = doc.id;
      print('Checking chat: $chatId');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checking chat: ${chatId.substring(0, 15)}...'),
          ),
        );
      });

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
        print('Last message data: ${messagesSnapshot.docs.first.data()}');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Found ${messagesSnapshot.docs.length} messages in chat',
              ),
              backgroundColor: Colors.green,
            ),
          );
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No messages in chat ${chatId.substring(0, 15)}'),
              backgroundColor: Colors.orange,
            ),
          );
        });
      }
        if (messagesSnapshot.docs.isNotEmpty) {
        var lastMessageDoc = messagesSnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final providerUid =
          (data['providerUid'] ?? data['providerId'] ?? '').toString();
        final providerProfileId =
          (data['providerId'] ?? '').toString().trim().isEmpty
            ? null
            : data['providerId'].toString();
        String otherId = data['employerId'] == user.uid
          ? providerUid
          : data['employerId'];
        bool isEmployer = data['employerId'] == user.uid;

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
                .doc(providerProfileId ?? otherId)
                .get();
            if (userDoc.exists) {
              final data = userDoc.data() as Map<String, dynamic>?;
              businessName =
                  data?['businessName'] ??
                  fullName ??
                  data?['name'] ??
                  'Unknown';
              if (data?['portfolioFiles'] is List) {
                portfolioFiles = (data!['portfolioFiles'] as List)
                    .map((e) => e.toString())
                    .toList();
              }
            }
          } else {
            // If current user is provider, other is employer
            userDoc = await FirebaseFirestore.instance
                .collection('Sign Up')
                .doc(otherId)
                .get();
            if (userDoc.exists) {
              final data = userDoc.data() as Map<String, dynamic>?;
              fullName = data?['fullName'] ?? data?['name'] ?? 'Unknown';
              photoUrl = data?['photoUrl'];
            }
          }
        } catch (e) {
          print('Error fetching user data for $otherId: $e');
        }

        String lastMessage = '';
        int unreadCount = 0;
        if (lastMessageDoc.data() != null) {
          final data = lastMessageDoc.data()! as Map<String, dynamic>;
          if (data['type'] == 'image') {
            lastMessage = 'Image';
          } else {
            lastMessage = data['text'] ?? data['message'] ?? '';
          }
        }

        // Count unread messages for this chat
        final unreadSnapshot = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('receiverId', isEqualTo: user.uid)
            .where('read', isEqualTo: false)
            .get();
        unreadCount = unreadSnapshot.docs.length;

        fetchedChats.add({
          'chatId': chatId,
          'otherId': otherId,
          'providerUid': providerUid,
          'providerProfileId': providerProfileId,
          'employerId': data['employerId'],
          'businessName': businessName,
          'lastMessage': lastMessage,
          'timestamp': lastMessageDoc['timestamp'],
          'isEmployer': isEmployer,
          'isOnline': isOnline,
          'portfolioFiles': portfolioFiles,
          'fullName': fullName,
          'photoUrl': photoUrl,
          'displayName': isEmployer ? businessName : (fullName ?? 'Unknown'),
          'unreadCount': unreadCount,
        });
        print(
          'Added chat: ${isEmployer ? businessName : (fullName ?? 'Unknown')}',
        );
      }
    }

    setState(() {
      chats = fetchedChats;
      hasMessages = chats.isNotEmpty;
    });
    print(
      'FINAL RESULT: hasMessages: $hasMessages, chats count: ${chats.length}',
    );
    for (var chat in chats) {
      print(
        'Chat in list: ${chat['displayName']}, lastMessage: ${chat['lastMessage']}',
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasMessages) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Success! Found ${chats.length} chats with messages',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No chats with messages found'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
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
                          child: _avatarWidget,
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
                                    chat['displayName'],
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
                                        chatPartnerName: chat['displayName'],
                                          providerId:
                                          chat['providerProfileId'] ??
                                          chat['providerUid'] ??
                                          chat['otherId'],
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
                                          Row(
                                            children: [
                                              Text(
                                                chat['displayName'],
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (chat['unreadCount'] > 0)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    left: 8,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: Text(
                                                    chat['unreadCount'] > 99
                                                        ? '99+'
                                                        : chat['unreadCount']
                                                              .toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
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
