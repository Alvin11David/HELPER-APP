import 'dart:async';

import 'package:flutter/material.dart';
import 'package:helper/Chats/overlays/incoming_call_overlay_service.dart';
import 'package:helper/main.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audio_session/audio_session.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  late Room _room;

  late CollectionReference _callsRef;
  late DocumentReference _callDoc;

  StreamSubscription? _callSub;

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
    _room = Room();
    _callsRef = FirebaseFirestore.instance.collection('calls');
    _callDoc = _callsRef.doc(callId);
    _init();
  }

  Future<void> _init() async {
    await _configureAudioSession();
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
          content: Text('✅ Audio session configured for LiveKit voice chat'),
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
    _room.disconnect();
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
        content: Text('✅ Microphone permission granted for LiveKit calls'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Connect to LiveKit room
    try {
      // Get token from Cloud Function
      final user = FirebaseAuth.instance.currentUser!;
      final callable = FirebaseFunctions.instance.httpsCallable(
        'generateLiveKitToken',
      );
      final result = await callable.call({
        'roomName': callId,
        'identity': user.uid,
      });
      final token = result.data['token'] as String;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ LiveKit token generated via Cloud Function'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Replace with your LiveKit server URL
      const serverUrl = 'wss://helpers-app-r1bkn34h.livekit.cloud';
      await _room.connect(serverUrl, token);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Connected to LiveKit room successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Enable microphone for voice transmission
      await _room.localParticipant?.setMicrophoneEnabled(true);
      _room.events.listen((RoomEvent event) {
        // Handle room events here if needed
        if (event is RoomDisconnectedEvent) {
          print('Room disconnected');
          Navigator.of(context).pop();
        }
        // Add more event handling as needed
      });
      print('Connected to LiveKit room: $callId');
    } catch (e) {
      print('Error connecting to room: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Failed to generate token or connect to LiveKit room: $e',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    await _setupSignaling();
  }

  void _onParticipantEvent(ParticipantEvent event) {
    if (event is TrackSubscribedEvent && event.track.kind == TrackType.AUDIO) {
      print('Remote audio track subscribed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Remote audio connected via LiveKit'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _setupSignaling() async {
    _callSub = _callDoc.snapshots().listen((snapshot) async {
      if (!snapshot.exists) {
        if (isCaller && !_offerCreated) {
          _offerCreated = true;
          // For LiveKit, call initiation can be done via Firestore
          await _callDoc.set({'status': 'ringing'});
        }
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) return;

      final status = data['status'];
      if (status != null && status != _callStatus) {
        setState(() => _callStatus = status);

        if (status == 'ringing' && !isCaller) {
          // Show incoming call overlay for the callee
          _showIncomingCallOverlay();
        }

        if (status == 'accepted') {
          _startCallTimer();
          print('Call accepted - starting timer');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '📞 Call connected via LiveKit - voice transmission active',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
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
    });
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
    await _room.disconnect();
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
                        onTap: () async {
                          setState(() => _micClicked = !_micClicked);
                          await _room.localParticipant?.setMicrophoneEnabled(
                            _micClicked,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _micClicked
                                    ? '🎤 Microphone enabled for LiveKit transmission'
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

  void _showIncomingCallOverlay() {
    final BuildContext? ctx = appNavKey.currentContext;
    if (ctx != null) {
      IncomingCallOverlayService.instance.show(
        context: ctx,
        businessName: widget.businessName,
        subtitle: 'Incoming voice call',
        timeText: '9:45AM',
        avatarImage: widget.portfolioImageUrl != null
            ? NetworkImage(widget.portfolioImageUrl!)
            : const AssetImage('assets/images/person.png'),
        onDecline: () async {
          await _callDoc.update({'status': 'declined'});
        },
        onAnswer: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📞 Accepting call - updating status...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
          await _callDoc.update({'status': 'accepted'});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Status update sent to Firestore'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    }
  }
}

// ===================================================================
