import 'package:flutter/material.dart';
import 'incoming_call_overlay.dart';

class IncomingCallOverlayService {
  IncomingCallOverlayService._();
  static final IncomingCallOverlayService instance = IncomingCallOverlayService._();

  OverlayEntry? _entry;

  bool get isShowing => _entry != null;

  void hide() {
    _entry?.remove();
    _entry = null;
  }

  void show({
    required BuildContext context,
    required String businessName,
    required String subtitle,
    required String timeText,
    required ImageProvider avatarImage,
    required VoidCallback onDecline,
    required VoidCallback onAnswer,
    bool dismissOnTapOutside = false,
  }) {
    if (isShowing) hide();

    _entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // Optional outside tap dismiss (off by default)
            if (dismissOnTapOutside)
              Positioned.fill(
                child: GestureDetector(
                  onTap: hide,
                  child: Container(color: Colors.black.withOpacity(0.0)),
                ),
              ),

            IncomingCallOverlayCard(
              businessName: businessName,
              subtitle: subtitle,
              timeText: timeText,
              avatarImage: avatarImage,
              onDecline: () {
                hide();
                onDecline();
              },
              onAnswer: () {
                hide();
                onAnswer();
              },
            ),
          ],
        );
      },
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(_entry!);
  }
}
