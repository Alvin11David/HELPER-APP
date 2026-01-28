import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'Voice_Call_Screen.dart';

class ChatScreen extends StatefulWidget {
  final String businessName;
  final String providerId;
  final String employerId;
  const ChatScreen({
    super.key,
    required this.businessName,
    required this.providerId,
    required this.employerId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late String chatId;

  @override
  void initState() {
    super.initState();
    // Create a unique chat ID by sorting the IDs
    final ids = [widget.employerId, widget.providerId]..sort();
    chatId = '${ids[0]}_${ids[1]}';
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .orderBy('timestamp', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            List<Map<String, dynamic>> messages = [];
            if (snapshot.hasData) {
              messages = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  ...data,
                  'isSent': data['senderId'] == widget.employerId,
                  'time': _formatTime(data['timestamp'] as Timestamp?),
                };
              }).toList();
            }
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background/normalscreenbg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Center(child: Text('Chat Screen')),
                  Positioned(
                    top: screenWidth * 0.05,
                    left: screenWidth * 0.04,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.chevron_left,
                                color: Colors.black,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.businessName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('serviceProviders')
                                  .doc(widget.providerId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                bool isOnline = false;
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final data =
                                      snapshot.data!.data()
                                          as Map<String, dynamic>?;
                                  isOnline = data?['isOnline'] ?? false;
                                }
                                return Text(
                                  isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: screenWidth * 0.05 + 60,
                    left: 0,
                    child: Container(
                      height: 1,
                      width: screenWidth,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: screenWidth * 0.05,
                    right: screenWidth * 0.04,
                    child: Transform.scale(
                      scale: 1.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VoiceCallScreen(),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: screenWidth * 0.12,
                                  height: screenWidth * 0.12,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.phone,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
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
                                  Icons.person,
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
                    bottom: 80,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: messages
                          .where((msg) => !msg['isSent'])
                          .map(
                            (msg) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(20),
                                      topLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                  ),
                                  child: msg['type'] == 'text'
                                      ? Text(
                                          msg['text'],
                                          style: const TextStyle(color: Colors.black),
                                        )
                                      : Image.network(
                                          msg['imageUrl'],
                                          width: 200,
                                          height: 200,
                                        ),
                                ),
                                Text(
                                  msg['time'],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: messages
                          .where((msg) => msg['isSent'])
                          .map(
                            (msg) => Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFA10D),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(20),
                                      topLeft: Radius.circular(20),
                                      bottomLeft: Radius.circular(20),
                                    ),
                                  ),
                                  child: msg['type'] == 'text'
                                      ? Text(
                                          msg['text'],
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        )
                                      : Image.network(
                                          msg['imageUrl'],
                                          width: 200,
                                          height: 200,
                                        ),
                                ),
                                Text(
                                  msg['time'],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: screenWidth * 0.05,
                    child: Row(
                      children: [
                        Container(
                          width: screenWidth * 0.75,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: TextField(
                                    controller: _controller,
                                    decoration: const InputDecoration(
                                      hintText: 'Message',
                                      border: InputBorder.none,
                                    ),
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () async {
                                    final ImagePicker picker = ImagePicker();
                                    final List<XFile> images = await picker.pickMultiImage();
                                    for (var image in images) {
                                      final file = File(image.path);
                                      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
                                      final storageRef = FirebaseStorage.instance.ref().child('Chat Images').child(fileName);
                                      final uploadTask = storageRef.putFile(file);
                                      final snapshot = await uploadTask.whenComplete(() {});
                                      final downloadUrl = await snapshot.ref.getDownloadURL();
                                      final message = {
                                        'imageUrl': downloadUrl,
                                        'senderId': widget.employerId,
                                        'receiverId': widget.providerId,
                                        'timestamp': FieldValue.serverTimestamp(),
                                        'type': 'image',
                                      };
                                      await FirebaseFirestore.instance
                                          .collection('chats')
                                          .doc(chatId)
                                          .collection('messages')
                                          .add(message);
                                    }
                                  },
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            if (_controller.text.isNotEmpty) {
                              final message = {
                                'text': _controller.text,
                                'senderId': widget.employerId,
                                'receiverId': widget.providerId,
                                'timestamp': FieldValue.serverTimestamp(),
                                'type': 'text',
                              };
                              await FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(chatId)
                                  .collection('messages')
                                  .add(message);
                              _controller.clear();
                            }
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFC107),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
