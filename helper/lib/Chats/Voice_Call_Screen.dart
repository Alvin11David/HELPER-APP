import 'package:flutter/material.dart';
import 'package:helper/Chats/overlays/incoming_call_overlay_service.dart';
import 'package:helper/main.dart';

class VoiceCallScreen extends StatefulWidget {
  @override
  _VoiceCallScreenState createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool _volumeClicked = false;
  bool _micClicked = false;

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
                        'Business Name',
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
                  child: Icon(Icons.person, color: Colors.black, size: 150),
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
                        onTap: () => setState(() => _volumeClicked = !_volumeClicked),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _volumeClicked ? Color(0xFFFFA10D) : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volume_up,
                            color: _volumeClicked ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _micClicked = !_micClicked),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _micClicked ? Color(0xFFFFA10D) : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mic_off,
                            color: _micClicked ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.call_end, color: Colors.white),
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


