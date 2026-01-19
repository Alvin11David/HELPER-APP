// ignore_for_file: depend_on_referenced_packages

import 'dart:ui';
import 'package:flutter/material.dart';

class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  static const _brandOrange = Color(0xFFFFA10D);

  int _phase = 0; // 0 = summary, 1 = time & payment

  // ---- Fake data (hook to real data later) ----
  final String status = "On Job";
  final String jobId = "ID Number";
  final String jobCountdown = "00:00:00";

  final String employerName = "Name";
  final String jobCategory = "Category";
  final String jobLocation = "Location";
  final String jobDescription = "Description";

  final String type = "Hour/Fixed";
  final String totalTime = "Time";
  final String elapsedTime = "Time";
  final String amount = "Amount";

  void _back() {
    if (_phase == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _phase = 0);
    }
  }

  void _goPhase(int v) {
    if (_phase == v) return;
    setState(() => _phase = v);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final sidePad = w * 0.06;
    final topPad = h * 0.03;

    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Body
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) {
                  final slide =
                      Tween<Offset>(
                        begin: Offset(_phase == 0 ? -0.04 : 0.04, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeOut),
                      );
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: _phase == 0
                    ? _phaseSummary(w, h, sidePad, topPad)
                    : _phasePayment(w, h, sidePad, topPad),
              ),

              // Top bar
              Positioned(
                top: h * 0.02,
                left: sidePad,
                right: sidePad,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _back,
                      child: Container(
                        width: w * 0.13,
                        height: w * 0.13,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.black,
                          size: w * 0.10,
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.04),
                    Expanded(
                      child: Text(
                        'Active Job',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.055,
                          fontFamily: 'AbrilFatface',
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    _TopAvatar(w: w),
                    SizedBox(width: w * 0.025),
                    _TopIcon(
                      w: w,
                      icon: Icons.notifications_none_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // Phase dots (like small step indicator)
              Positioned(
                top: h * 0.12,
                left: 0,
                right: 0,
                child: Center(
                  child: _PhaseDots(
                    activeIndex: _phase,
                    onTap: _goPhase,
                    accent: _brandOrange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- PHASE 0 ----------------

  Widget _phaseSummary(double w, double h, double sidePad, double topPad) {
    return SingleChildScrollView(
      key: const ValueKey('phase0'),
      padding: EdgeInsets.fromLTRB(sidePad, h * 0.16, sidePad, h * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Job Status', w),
          SizedBox(height: h * 0.012),
          _WhiteCard(
            child: Column(
              children: [
                _InfoRow(
                  label: 'Status:',
                  value: status,
                  valueColor: Colors.green,
                ),
                _InfoRow(label: 'Job ID:', value: jobId),
                _InfoRow(label: 'Job Countdown:', value: jobCountdown),
              ],
            ),
          ),

          SizedBox(height: h * 0.018),

          _sectionTitle('Employer & Job Summary', w),
          SizedBox(height: h * 0.012),
          _WhiteCard(
            child: Column(
              children: [
                _InfoRow(label: 'Employer Name:', value: employerName),
                _InfoRow(label: 'Job Category:', value: jobCategory),
                _InfoRow(label: 'Job Location:', value: jobLocation),
                _InfoRow(label: 'Job Description:', value: jobDescription),
                SizedBox(height: h * 0.012),
                Row(
                  children: [
                    Expanded(
                      child: _OrangeMiniButton(
                        text: 'Call Now',
                        icon: Icons.call,
                        onTap: () {
                          // TODO: show incoming/outgoing call UI
                        },
                      ),
                    ),
                    SizedBox(width: w * 0.04),
                    Expanded(
                      child: _OrangeMiniButton(
                        text: 'Message',
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: () {
                          // TODO: open chat
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: h * 0.018),

          _sectionTitle('Location & Navigation', w),
          SizedBox(height: h * 0.012),

          _MapCard(
            w: w,
            h: h,
            onNavigate: () {
              // TODO: deep link to maps / in-app navigation
            },
          ),

          SizedBox(height: h * 0.018),

          _sectionTitle('Time & Payment Tracking', w),
          SizedBox(height: h * 0.012),
          _WhiteCard(
            child: Column(
              children: [
                _InfoRow(label: 'Type:', value: type),
                _InfoRow(label: 'Total Time:', value: totalTime),
                _InfoRow(label: 'Elapsed Time:', value: elapsedTime),
                _InfoRow(label: 'Amount:', value: amount),
              ],
            ),
          ),

          SizedBox(height: h * 0.02),

          // Swipe/Next hint button (optional, matches the idea of going to next panel)
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _phase = 1),
              child: _GlassPill(
                radius: 20,
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.05,
                  vertical: h * 0.008,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Time & Payment',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: w * 0.032,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(width: w * 0.02),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withOpacity(0.92),
                      size: w * 0.05,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PHASE 1 ----------------

  Widget _phasePayment(double w, double h, double sidePad, double topPad) {
    return SingleChildScrollView(
      key: const ValueKey('phase1'),
      padding: EdgeInsets.fromLTRB(sidePad, h * 0.16, sidePad, h * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Time & Payment Tracking', w),
          SizedBox(height: h * 0.012),
          _WhiteCard(
            child: Column(
              children: [
                _InfoRow(label: 'Type:', value: type),
                _InfoRow(label: 'Total Time:', value: totalTime),
                _InfoRow(label: 'Elapsed Time:', value: elapsedTime),
                _InfoRow(label: 'Amount:', value: amount),
              ],
            ),
          ),

          SizedBox(height: h * 0.015),

          Center(
            child: _GlassPill(
              radius: 20,
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.05,
                vertical: h * 0.007,
              ),
              child: Text(
                'Payment is held in Escrow',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: w * 0.03,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),

          SizedBox(height: h * 0.06),

          // Terminate job (big red)
          SizedBox(
            width: double.infinity,
            height: h * 0.078,
            child: ElevatedButton(
              onPressed: () {
                // TODO: confirm dialog -> terminate
                _showTerminateDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE80B0B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              child: Text(
                'Terminate Job',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTerminateDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final w = MediaQuery.of(ctx).size.width;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Terminate Job?',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w900,
                        fontSize: w * 0.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This will end the active job. You can hook the real termination API later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: w * 0.032,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.35),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Terminated (hook API later)',
                                    style: TextStyle(fontFamily: 'Inter'),
                                  ),
                                  backgroundColor: Colors.black.withOpacity(
                                    0.85,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandOrange,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Terminate',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Text _sectionTitle(String t, double w) {
    return Text(
      t,
      style: TextStyle(
        color: Colors.white,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w900,
        fontSize: w * 0.038,
      ),
    );
  }
}

// --------------------------- UI Parts ---------------------------

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _BulletIcon(size: w * 0.055),
          const SizedBox(width: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w900,
              fontSize: w * 0.033,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? Colors.black.withOpacity(0.85),
              fontFamily: 'Inter',
              fontWeight: FontWeight.normal,
              fontSize: w * 0.032,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletIcon extends StatelessWidget {
  final double size;
  const _BulletIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.18)),
      ),
      child: Center(
        child: Icon(
          Icons.info_outline_rounded,
          size: size * 0.62,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _OrangeMiniButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _OrangeMiniButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: w * 0.11,
        decoration: BoxDecoration(
          color: const Color(0xFFFFA10D),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: w * 0.05),
            SizedBox(width: w * 0.02),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.034,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final double w;
  final double h;
  final VoidCallback onNavigate;

  const _MapCard({required this.w, required this.h, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final mapH = h * 0.22;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: mapH,
        width: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            // placeholder map look
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEDEDED), Color(0xFFF7F7F7)],
                  ),
                ),
              ),
            ),

            // pins
            Positioned(
              left: w * 0.06,
              top: mapH * 0.18,
              child: _MapPin(label: 'You', color: Colors.redAccent, w: w),
            ),
            Positioned(
              right: w * 0.22,
              top: mapH * 0.28,
              child: _MapPin(label: 'Employer', color: Colors.purple, w: w),
            ),

            // zoom controls
            Positioned(
              right: w * 0.03,
              top: mapH * 0.30,
              child: Column(
                children: [
                  _ZoomBtn(icon: Icons.add, w: w),
                  SizedBox(height: h * 0.01),
                  _ZoomBtn(icon: Icons.remove, w: w),
                ],
              ),
            ),

            // navigate button
            Positioned(
              left: 0,
              right: 0,
              bottom: mapH * 0.12,
              child: Center(
                child: GestureDetector(
                  onTap: onNavigate,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.12,
                      vertical: w * 0.028,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA10D),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                          size: w * 0.05,
                        ),
                        SizedBox(width: w * 0.02),
                        Text(
                          'Navigate',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.034,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final String label;
  final Color color;
  final double w;

  const _MapPin({required this.label, required this.color, required this.w});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.location_pin, color: color, size: w * 0.07),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: w * 0.028,
            ),
          ),
        ),
      ],
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final double w;

  const _ZoomBtn({required this.icon, required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w * 0.10,
      height: w * 0.10,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black, size: w * 0.06),
    );
  }
}

class _PhaseDots extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;
  final Color accent;

  const _PhaseDots({
    required this.activeIndex,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    Widget dot(int i) {
      final active = i == activeIndex;
      return GestureDetector(
        onTap: () => onTap(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 18 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: active ? accent : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [dot(0), dot(1)]);
  }
}

class _TopAvatar extends StatelessWidget {
  final double w;
  const _TopAvatar({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w * 0.10,
      height: w * 0.10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white.withOpacity(0.35)),
        image: const DecorationImage(
          image: AssetImage('assets/images/person.png'), // change if needed
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  final double w;
  final IconData icon;
  final VoidCallback onTap;

  const _TopIcon({required this.w, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w * 0.10,
        height: w * 0.10,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: w * 0.06),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const _GlassPill({
    required this.child,
    required this.padding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.22),
                Colors.white.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
