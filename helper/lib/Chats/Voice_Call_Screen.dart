import 'dart:async';

import 'package:flutter/material.dart';
import 'package:helper/Chats/overlays/incoming_call_overlay_service.dart';
import 'package:helper/main.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceCallScreen extends StatefulWidget {
  final String businessName;
  final String providerId;
  final String callerId;
  final String? portfolioImageUrl;

  const VoiceCallScreen({
    super.key,
    required this.businessName,
    required this.providerId,
    required this.callerId,
    this.portfolioImageUrl,
  });

  @override
  _VoiceCallScreenState createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool _volumeClicked = false;
  bool _micClicked = false;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _inCall = false;
  late CollectionReference _callsRef;
  late DocumentReference _callDoc;
  StreamSubscription? _callSub;
  StreamSubscription? _iceSub;

  String get callId =>
      widget.callerId + '_' + widget.providerId; // Example unique callId

  @override
  void initState() {
    super.initState();
    _callsRef = FirebaseFirestore.instance.collection('calls');
    _callDoc = _callsRef.doc(callId);
    _initRenderers();
    _startCall();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.close();
    _callSub?.cancel();
    _iceSub?.cancel();
    super.dispose();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _startCall() async {
    await Permission.microphone.request();
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    _localRenderer.srcObject = _localStream;
    await _createPeerConnection();
    setState(() {
      _inCall = true;
    });
    await _setupSignaling();
  }

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };
    _peerConnection = await createPeerConnection(config);
    _peerConnection?.onTrack = (event) {
      if (event.track.kind == 'audio') {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };
    _peerConnection?.onIceCandidate = (candidate) async {
      if (candidate != null) {
        await _callDoc.collection('candidates').add(candidate.toMap());
      }
    };
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
  }

  Future<void> _setupSignaling() async {
    // Listen for signaling changes
    _callSub = _callDoc.snapshots().listen((snapshot) async {
      if (!snapshot.exists) {
        // If caller, create offer
        await _createOffer();
      } else {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data == null) return;
        if (data['offer'] != null) {
          final remoteDesc = await _peerConnection?.getRemoteDescription();
          if (remoteDesc == null) {
            // If callee, set remote offer and create answer
            await _peerConnection?.setRemoteDescription(
              RTCSessionDescription(
                data['offer']['sdp'],
                data['offer']['type'],
              ),
            );
            await _createAnswer();
          }
        } else if (data['answer'] != null) {
          final localDesc = await _peerConnection?.getLocalDescription();
          if (localDesc != null && localDesc.type == 'offer') {
            // If caller, set remote answer
            await _peerConnection?.setRemoteDescription(
              RTCSessionDescription(
                data['answer']['sdp'],
                data['answer']['type'],
              ),
            );
          }
        }
      }
    });
    // Listen for ICE candidates
    _iceSub = _callDoc.collection('candidates').snapshots().listen((
      snapshot,
    ) async {
      for (var doc in snapshot.docChanges) {
        final data = doc.doc.data();
        if (data != null) {
          final candidate = RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          );
          await _peerConnection?.addCandidate(candidate);
        }
      }
    });
  }

  Future<void> _createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    await _callDoc.set({'offer': offer.toMap()});
  }

  Future<void> _createAnswer() async {
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    await _callDoc.update({'answer': answer.toMap()});
  }

  void _endCall() async {
    await _peerConnection?.close();
    await _localStream?.dispose();
    await _callDoc.delete();
    setState(() {
      _inCall = false;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.businessName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'AbrilFatface',
                        ),
                      ),
                      Text(
                        'Ringing...',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: widget.portfolioImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            widget.portfolioImageUrl!,
                            fit: BoxFit.cover,
                            width: 280,
                            height: 280,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                color: Colors.black,
                                size: 150,
                              );
                            },
                          ),
                        )
                      : Icon(Icons.person, color: Colors.black, size: 150),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _volumeClicked = !_volumeClicked),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _volumeClicked
                                ? Color(0xFFFFA10D)
                                : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volume_up,
                            color: _volumeClicked ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _micClicked = !_micClicked);
                          _localStream?.getAudioTracks().forEach((track) {
                            track.enabled = _micClicked;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _micClicked
                                ? Color(0xFFFFA10D)
                                : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _micClicked ? Icons.mic : Icons.mic_off,
                            color: _micClicked ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _endCall,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.call_end, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showIncomingCallOverlay() {
  // use appNavKey.currentContext!
  final BuildContext? ctx = appNavKey.currentContext;
  if (ctx != null) {
    IncomingCallOverlayService.instance.show(
      context: ctx,
      businessName: 'Business Name',
      subtitle: 'Incoming voice call',
      timeText: '9:45AM',
      avatarImage: const AssetImage('assets/images/person.png'),
      onDecline: () {},
      onAnswer: () {},
    );
  }
}
