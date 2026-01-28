import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'Voice_Call_Screen.dart';

class ChatScreen extends StatefulWidget {
  final String businessName;
  const ChatScreen({super.key, required this.businessName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Container(
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
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Text(
                          'online',
                          style: TextStyle(color: Colors.white, fontSize: 14),
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
                              child: Text(
                                msg['text']!,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                            Text(
                              msg['time']!,
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
                                      msg['text']!,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    )
                                  : Image.file(
                                      File(msg['path']!),
                                      width: 200,
                                      height: 200,
                                    ),
                            ),
                            Text(
                              msg['time']!,
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
                                final List<XFile> images = await picker
                                    .pickMultiImage();
                                for (var image in images) {
                                  setState(() {
                                    messages.add({
                                      'type': 'image',
                                      'path': image.path,
                                      'time': () {
                                        int hour = DateTime.now().hour;
                                        String minute = DateTime.now().minute
                                            .toString()
                                            .padLeft(2, '0');
                                        String period = hour < 12 ? 'AM' : 'PM';
                                        int displayHour = hour == 0
                                            ? 12
                                            : (hour > 12 ? hour - 12 : hour);
                                        return '$displayHour:$minute $period';
                                      }(),
                                      'isSent': true,
                                    });
                                  });
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
                      onTap: () {
                        if (_controller.text.isNotEmpty) {
                          setState(() {
                            messages.add({
                              'type': 'text',
                              'text': _controller.text,
                              'time': () {
                                int hour = DateTime.now().hour;
                                String minute = DateTime.now().minute
                                    .toString()
                                    .padLeft(2, '0');
                                String period = hour < 12 ? 'AM' : 'PM';
                                int displayHour = hour == 0
                                    ? 12
                                    : (hour > 12 ? hour - 12 : hour);
                                return '$displayHour:$minute $period';
                              }(),
                              'isSent': true,
                            });
                            _controller.clear();
                          });
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
        ),
      ),
    );
  }
}
