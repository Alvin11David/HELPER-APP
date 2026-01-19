import 'package:flutter/material.dart';

class IncomingCallOverlayCard extends StatelessWidget {
  final String businessName;
  final String subtitle;
  final String timeText;
  final ImageProvider avatarImage;

  final VoidCallback onDecline;
  final VoidCallback onAnswer;

  const IncomingCallOverlayCard({
    super.key,
    required this.businessName,
    required this.subtitle,
    required this.timeText,
    required this.avatarImage,
    required this.onDecline,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    // Match your design: wide rounded white card
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.03),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: w * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row: avatar + texts + time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: w * 0.06,
                        backgroundImage: avatarImage,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      SizedBox(width: w * 0.035),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              businessName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                                fontSize: w * 0.045,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: w * 0.006),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                fontSize: w * 0.034,
                                color: Colors.black.withOpacity(0.70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: w * 0.02),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: w * 0.034,
                          color: Colors.black.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: w * 0.03),

                  // dotted / subtle line (like your design)
                  Container(
                    width: double.infinity,
                    height: 1,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),

                  SizedBox(height: w * 0.03),

                  // Buttons row
                  Row(
                    children: [
                      Expanded(
                        child: _ActionPillButton(
                          text: 'Decline',
                          bg: const Color(0xFFE60012), // strong red
                          onTap: onDecline,
                        ),
                      ),
                      SizedBox(width: w * 0.04),
                      Expanded(
                        child: _ActionPillButton(
                          text: 'Answer',
                          bg: const Color(0xFF2DFF2D), // bright green
                          onTap: onAnswer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionPillButton extends StatelessWidget {
  final String text;
  final Color bg;
  final VoidCallback onTap;

  const _ActionPillButton({
    required this.text,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return SizedBox(
      height: w * 0.13,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            fontSize: w * 0.04,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
