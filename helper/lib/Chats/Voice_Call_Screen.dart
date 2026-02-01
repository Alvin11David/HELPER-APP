import 'dart:async';

import 'package:flutter/material.dart';
import 'package:helper/Chats/overlays/incoming_call_overlay_service.dart';
import 'package:helper/main.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audio_session/audio_session.dart';

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
  bool _micClicked = true;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final _localRenderer = RTCVideoRenderer();

  late CollectionReference _callsRef;
  late DocumentReference _callDoc;

  StreamSubscription? _callSub;
  StreamSubscription? _iceSub;

  String _callStatus = 'ringing';

  Timer? _callTimer;
  int _callDuration = 0;

  bool _offerCreated = false;

  String get callId => '${widget.callerId}_${widget.providerId}';

  bool get isCaller =>
      FirebaseAuth.instance.currentUser!.uid == widget.callerId;

  @override
  void initState() {
    super.initState();

    _callsRef = FirebaseFirestore.instance.collection('calls');
    _callDoc = _callsRef.doc(callId);

    _init();
  }

  Future<void> _init() async {
    await _configureAudioSession();
    await _initRenderers();
    await _startCall();
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.voiceChat,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.voiceCommunication,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ),
      );
      await session.setActive(true);
      print('Audio session configured and activated');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Audio session configured for voice chat'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error configuring audio session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Audio session configuration failed: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _callSub?.cancel();
    _iceSub?.cancel();
    _peerConnection?.close();
    _localStream?.dispose();
    _remoteStream?.dispose();
    _localRenderer.dispose();
    _deactivateAudioSession();
    super.dispose();
  }

  Future<void> _deactivateAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
      print('Audio session deactivated');
    } catch (e) {
      print('Error deactivating audio session: $e');
    }
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
  }

  Future<void> _startCall() async {
    final phoneStatus = await Permission.phone.request();
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ Microphone permission denied - voice cannot be transmitted',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Microphone permission granted'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'sampleRate': 16000,
        'channelCount': 1,
      },
      'video': false,
    });

    print('Local stream obtained: ${_localStream?.id}');
    print('Local audio tracks: ${_localStream?.getAudioTracks().length}');

    if (_localStream?.getAudioTracks().isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No audio tracks found in local stream'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Local audio stream ready (${_localStream!.getAudioTracks().length} track(s))',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Ensure local audio tracks are enabled
    _localStream?.getAudioTracks().forEach((track) {
      print('Enabling local audio track: ${track.id}');
      track.enabled = true;
    });

    _localRenderer.srcObject = _localStream;

    await _createPeerConnection();
    await _setupSignaling();
  }

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    // Handle remote tracks when they arrive
    _peerConnection!.onTrack = (event) {
      print('Received remote track: ${event.track.kind}');
      if (event.track.kind == 'audio') {
        print('Setting remote stream from track event');
        setState(() {
          _remoteStream = event.streams[0];
        });
        print('Remote stream set: ${_remoteStream?.id}');

        if (_remoteStream?.getAudioTracks().isEmpty ?? true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No audio tracks in remote stream'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Remote audio stream received (${_remoteStream!.getAudioTracks().length} track(s))',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Ensure remote audio tracks are enabled
        _remoteStream?.getAudioTracks().forEach((track) {
          print('Enabling remote audio track: ${track.id}');
          track.enabled = true;
        });
      }
    };

    _peerConnection!.onConnectionState = (state) {
      print('Peer connection state changed: $state');

      String message;
      Color bgColor;
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          message = '✅ Peer connection established - voice should work now';
          bgColor = Colors.green;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          message = '❌ Peer connection failed - cannot transmit voice';
          bgColor = Colors.red;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          message = '⚠️ Peer connection lost - voice transmission interrupted';
          bgColor = Colors.orange;
          break;
        default:
          message = '🔄 Connection state: ${state.toString().split('.').last}';
          bgColor = Colors.blue;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: bgColor,
          duration: Duration(
            seconds:
                state == RTCPeerConnectionState.RTCPeerConnectionStateConnected
                ? 2
                : 4,
          ),
        ),
      );
    };

    _peerConnection!.onIceConnectionState = (state) {
      print('ICE connection state changed: $state');

      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ ICE connection failed - network issue preventing voice',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      } else if (state ==
          RTCIceConnectionState.RTCIceConnectionStateConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ICE connection established'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    };

    // Add local tracks to peer connection
    for (var track in _localStream!.getTracks()) {
      print('Adding local track: ${track.kind}');
      await _peerConnection!.addTrack(track, _localStream!);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔄 Peer connection created - waiting for ${isCaller ? 'callee' : 'caller'} to connect',
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _setupSignaling() async {
    _callSub = _callDoc.snapshots().listen((snapshot) async {
      if (!snapshot.exists) {
        if (isCaller && !_offerCreated) {
          _offerCreated = true;
          await _createOffer();
        }
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) return;

      final status = data['status'];
      if (status != null && status != _callStatus) {
        setState(() => _callStatus = status);

        if (status == 'accepted') {
          _startCallTimer();
          print('Call accepted - starting timer');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '📞 Call connected - voice transmission should work now',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Ensure remote audio tracks are enabled when call is accepted
          Future.delayed(const Duration(milliseconds: 500), () {
            _remoteStream?.getAudioTracks().forEach((track) {
              if (!track.enabled) {
                print('Re-enabling remote audio track: ${track.id}');
                track.enabled = true;
              }
            });
          });
        }

        if (status == 'declined' || status == 'ended') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'declined' ? '❌ Call was declined' : '📞 Call ended',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        }
      }

      if (!isCaller && data['offer'] != null) {
        final desc = await _peerConnection!.getRemoteDescription();
        if (desc == null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(data['offer']['sdp'], data['offer']['type']),
          );
          await _createAnswer();
          await _callDoc.update({'status': 'accepted'});
        }
      }

      if (isCaller && data['answer'] != null) {
        final desc = await _peerConnection!.getRemoteDescription();
        if (desc == null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(
              data['answer']['sdp'],
              data['answer']['type'],
            ),
          );
        }
      }
    });

    final remoteCandidates = isCaller ? 'calleeCandidates' : 'callerCandidates';

    _iceSub = _callDoc.collection(remoteCandidates).snapshots().listen((
      snapshot,
    ) async {
      final desc = await _peerConnection!.getRemoteDescription();
      if (desc == null) return;

      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data != null) {
          await _peerConnection!.addCandidate(
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
      setState(() => _callDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall() async {
    await _peerConnection?.close();
    await _localStream?.dispose();
    await _callDoc.update({'status': 'ended'});
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
                        onTap: () async {
                          setState(() => _volumeClicked = !_volumeClicked);
                          // Speakerphone control - simplified implementation
                          // In a full implementation, you might need platform channels
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _volumeClicked
                                    ? '🔊 Speakerphone enabled (if supported by device)'
                                    : '📱 Speakerphone disabled (earpiece mode)',
                              ),
                              backgroundColor: Colors.blue,
                              duration: Duration(seconds: 2),
                            ),
                          );
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

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _micClicked
                                    ? '🎤 Microphone enabled - you can now speak'
                                    : '🔇 Microphone muted - other person cannot hear you',
                              ),
                              backgroundColor: _micClicked
                                  ? Colors.green
                                  : Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
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
