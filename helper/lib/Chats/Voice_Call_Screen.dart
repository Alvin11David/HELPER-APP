import 'dart:async';

import 'package:flutter/material.dart';
import 'package:helper/Chats/overlays/incoming_call_overlay_service.dart';
import 'package:helper/main.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  String _callStatus = 'ringing';

  Timer? _callTimer;
  int _callDuration = 0;

  String get callId => '${widget.callerId}_${widget.providerId}';

  bool get isCaller =>
      FirebaseAuth.instance.currentUser!.uid == widget.callerId;

  @override
  void initState() {
    super.initState();

    _callsRef = FirebaseFirestore.instance.collection('calls');
    _callDoc = _callsRef.doc(callId);

    _micClicked = true;

    _initRenderers();
    _startCall();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _callSub?.cancel();
    _iceSub?.cancel();
    _peerConnection?.close();
    _localStream?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
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
    await _setupSignaling();

    setState(() {
      _inCall = true;
    });
  }

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'audio') {
        event.track.enabled = true;
      }
    };

    _peerConnection!.onIceCandidate = (candidate) async {
      if (candidate == null) return;

      final collection = isCaller ? 'callerCandidates' : 'calleeCandidates';

      await _callDoc.collection(collection).add(candidate.toMap());
    };

    for (var track in _localStream!.getTracks()) {
      _peerConnection!.addTrack(track, _localStream!);
    }
  }

  Future<void> _setupSignaling() async {
    /// Listen to call document
    _callSub = _callDoc.snapshots().listen((snapshot) async {
      if (!snapshot.exists) {
        if (isCaller) {
          await _createOffer();
        }
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) return;

      final status = data['status'];
      if (status != null && status != _callStatus) {
        setState(() {
          _callStatus = status;
        });

        if (status == 'accepted') {
          _startCallTimer();
        }

        if (status == 'declined') {
          Navigator.of(context).pop();
        }

        if (status == 'ended') {
          Navigator.of(context).pop();
        }
      }

      /// CALLEE receives OFFER
      if (!isCaller && data['offer'] != null) {
        final remoteDesc = await _peerConnection!.getRemoteDescription();
        if (remoteDesc == null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(data['offer']['sdp'], data['offer']['type']),
          );
          await _createAnswer();
          await _callDoc.update({'status': 'accepted'});
        }
      }

      /// CALLER receives ANSWER
      if (isCaller && data['answer'] != null) {
        final remoteDesc = await _peerConnection!.getRemoteDescription();
        if (remoteDesc == null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(
              data['answer']['sdp'],
              data['answer']['type'],
            ),
          );
        }
      }
    });

    /// ICE candidates
    final remoteCandidates = isCaller ? 'calleeCandidates' : 'callerCandidates';

    _iceSub = _callDoc.collection(remoteCandidates).snapshots().listen((
      snapshot,
    ) {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data != null) {
          _peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });
  }

  Future<void> _createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await _callDoc.set({'offer': offer.toMap(), 'status': 'ringing'});
  }

  Future<void> _createAnswer() async {
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await _callDoc.update({'answer': answer.toMap()});
  }

  void _startCallTimer() {
    _callTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _callDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _endCall() async {
    await _peerConnection?.close();
    await _localStream?.dispose();
    await _callDoc.update({'status': 'ended'});

    setState(() {
      _inCall = false;
    });

    Navigator.of(context).pop();
  }

  // ========================= UI (UNCHANGED) =========================

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
                        _callStatus == 'accepted'
                            ? _formatDuration(_callDuration)
                            : 'Ringing...',
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
                        onTap: () {
                          setState(() => _volumeClicked = !_volumeClicked);
                          Helper.setSpeakerphoneOn(_volumeClicked);
                        },
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
                          _localStream?.getAudioTracks().forEach(
                            (t) => t.enabled = _micClicked,
                          );
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

// ===================================================================

void _showIncomingCallOverlay() {
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
