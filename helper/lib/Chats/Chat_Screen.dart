import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

class ChatScreen extends StatefulWidget {
  final String chatPartnerName;
  final String providerId;
  final String employerId;
  const ChatScreen({
    super.key,
    required this.chatPartnerName,
    required this.providerId,
    required this.employerId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String chatId;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedFilePath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingAudioUrl;
  bool _showRecordingUI = false;
  bool _showPlaybackUI = false;
  bool _isPlayingRecorded = false;

  @override
  void initState() {
    super.initState();
    // Create a unique chat ID by sorting the IDs
    final ids = [widget.employerId, widget.providerId]..sort();
    chatId = '${ids[0]}_${ids[1]}';
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('read', isEqualTo: false)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
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

  Future<void> _playAudio(String audioUrl) async {
    if (_currentlyPlayingAudioUrl == audioUrl) {
      // If the same audio is playing, stop it
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlayingAudioUrl = null;
      });
    } else {
      // Stop any currently playing audio
      if (_currentlyPlayingAudioUrl != null) {
        await _audioPlayer.stop();
      }
      // Play the new audio
      await _audioPlayer.play(UrlSource(audioUrl));
      setState(() {
        _currentlyPlayingAudioUrl = audioUrl;
      });

      // Listen for when the audio finishes
      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _currentlyPlayingAudioUrl = null;
          _isPlayingRecorded = false;
        });
      });
    }
  }

  Future<void> _playRecordedAudio() async {
    if (_recordedFilePath == null) return;
    if (_isPlayingRecorded) {
      await _audioPlayer.pause();
      setState(() {
        _isPlayingRecorded = false;
      });
    } else {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
      setState(() {
        _isPlayingRecorded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    Widget inputWidget;
    if (_showRecordingUI) {
      inputWidget = Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic, color: Colors.red),
              SizedBox(width: 10),
              Text('Recording...', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    } else if (_showPlaybackUI) {
      inputWidget = Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _playRecordedAudio,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Row(
                    children: [
                      Icon(_isPlayingRecorded ? Icons.pause : Icons.play_arrow, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Play Recorded Audio', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showPlaybackUI = false;
                    _recordedFilePath = null;
                    _isPlayingRecorded = false;
                  });
                },
                child: Icon(Icons.cancel, color: Colors.black),
              ),
            ),
          ],
        ),
      );
    } else {
      inputWidget = Container(
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
                  style: const TextStyle(
                    color: Colors.black,
                  ),
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
                    // Ensure the chat document exists
                    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);
                    final docSnapshot = await chatDoc.get();
                    if (!docSnapshot.exists) {
                      await chatDoc.set({
                        'employerId': widget.employerId,
                        'providerId': widget.providerId,
                        'chatPartnerName': widget.chatPartnerName,
                      });
                    }
                    final file = File(image.path);
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
                    final storageRef = FirebaseStorage.instance.ref().child('Chat Images').child(fileName);
                    final uploadTask = storageRef.putFile(file);
                    final snapshot = await uploadTask.whenComplete(() {});
                    final downloadUrl = await snapshot.ref.getDownloadURL();
                    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
                    final receiverId = currentUserId == widget.employerId ? widget.providerId : widget.employerId;
                    final message = {
                      'imageUrl': downloadUrl,
                      'senderId': currentUserId,
                      'receiverId': receiverId,
                      'timestamp': FieldValue.serverTimestamp(),
                      'type': 'image',
                      'read': false,
                    };
                    await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add(message);
                  }
                },
                child: const Icon(
                  Icons.image,
                  color: Colors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () async {
                  if (_isRecording) {
                    final path = await _audioRecorder.stop();
                    setState(() {
                      _isRecording = false;
                      _recordedFilePath = path;
                      _showRecordingUI = false;
                      _showPlaybackUI = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recording stopped'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    final micStatus = await Permission.microphone.request();
                    if (!micStatus.isGranted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Microphone permission required'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    final path = '${Directory.systemTemp.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
                    await _audioRecorder.start(const RecordConfig(), path: path);
                    setState(() {
                      _isRecording = true;
                      _recordedFilePath = null;
                      _showRecordingUI = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recording started...'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Icon(
                  Icons.mic,
                  color: _isRecording ? Colors.red : Colors.black,
                ),
              ),
            ),
          ],
        ),
      );
    }
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
                  'isSent':
                      data['senderId'] ==
                      FirebaseAuth.instance.currentUser!.uid,
                  'time': _formatTime(data['timestamp'] as Timestamp?),
                };
              }).toList();
              // Scroll to bottom when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background/normalscreenbg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenWidth * 0.05,
                    ),
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
                              widget.chatPartnerName,
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
                        const Spacer(),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('serviceProviders')
                              .doc(widget.providerId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            String? imageUrl;
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data =
                                  snapshot.data!.data()
                                      as Map<String, dynamic>?;
                              final portfolioFiles =
                                  data?['portfolioFiles'] as List<dynamic>?;
                              if (portfolioFiles != null &&
                                  portfolioFiles.isNotEmpty) {
                                imageUrl = portfolioFiles.first as String?;
                              }
                            }
                            return Container(
                              width: screenWidth * 0.12,
                              height: screenWidth * 0.12,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: imageUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.black,
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  Container(height: 1, width: screenWidth, color: Colors.white),
                  // Messages
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Align(
                            alignment: msg['isSent']
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              constraints: BoxConstraints(
                                maxWidth: screenWidth * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: msg['isSent']
                                    ? const Color(0xFFFFA10D)
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: msg['isSent']
                                      ? const Radius.circular(20)
                                      : Radius.zero,
                                  bottomRight: msg['isSent']
                                      ? Radius.zero
                                      : const Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: msg['isSent']
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  msg['type'] == 'text'
                                      ? Text(
                                          msg['text'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        )
                                      : msg['type'] == 'audio'
                                      ? GestureDetector(
                                          onTap: () {
                                            if (msg['audioUrl'] != null) {
                                              _playAudio(msg['audioUrl']);
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  _currentlyPlayingAudioUrl ==
                                                      msg['audioUrl']
                                                  ? Colors.blue.withOpacity(0.2)
                                                  : Colors.grey.withOpacity(
                                                      0.1,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _currentlyPlayingAudioUrl ==
                                                          msg['audioUrl']
                                                      ? Icons.pause
                                                      : Icons.play_arrow,
                                                  color: Colors.black,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _currentlyPlayingAudioUrl ==
                                                          msg['audioUrl']
                                                      ? 'Playing...'
                                                      : '🎵 Audio',
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : msg['imageUrl'] != null
                                      ? Image.network(
                                          msg['imageUrl'],
                                          width: 200,
                                          height: 200,
                                        )
                                      : const Text(
                                          'Image not available',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                  const SizedBox(height: 5),
                                  Text(
                                    msg['time'],
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.6),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Input
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: inputWidget,
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            // Ensure the chat document exists
                            final chatDoc = FirebaseFirestore.instance
                                .collection('chats')
                                .doc(chatId);
                            final docSnapshot = await chatDoc.get();
                            if (!docSnapshot.exists) {
                              await chatDoc.set({
                                'employerId': widget.employerId,
                                'providerId': widget.providerId,
                                'chatPartnerName': widget.chatPartnerName,
                              });
                            }
                            final currentUserId =
                                FirebaseAuth.instance.currentUser!.uid;
                            final receiverId =
                                currentUserId == widget.employerId
                                ? widget.providerId
                                : widget.employerId;

                            if (_recordedFilePath != null) {
                              // Send audio message
                              final file = File(_recordedFilePath!);
                              final fileName =
                                  'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
                              final storageRef = FirebaseStorage.instance
                                  .ref()
                                  .child('Chat Audio')
                                  .child(fileName);
                              final uploadTask = storageRef.putFile(file);
                              final snapshot = await uploadTask.whenComplete(
                                () {},
                              );
                              final downloadUrl = await snapshot.ref
                                  .getDownloadURL();
                              final message = {
                                'audioUrl': downloadUrl,
                                'senderId': currentUserId,
                                'receiverId': receiverId,
                                'timestamp': FieldValue.serverTimestamp(),
                                'type': 'audio',
                                'read': false,
                              };
                              await FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(chatId)
                                  .collection('messages')
                                  .add(message);
                              setState(() {
                                _recordedFilePath = null;
                                _showPlaybackUI = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Voice message sent!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else if (_controller.text.isNotEmpty) {
                              // Send text message
                              final message = {
                                'text': _controller.text,
                                'senderId': currentUserId,
                                'receiverId': receiverId,
                                'timestamp': FieldValue.serverTimestamp(),
                                'type': 'text',
                                'read': false,
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
