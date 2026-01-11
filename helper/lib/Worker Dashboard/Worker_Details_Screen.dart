import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class WorkerDetailsScreen extends StatefulWidget {
  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  bool _isExpanded = false;
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/normalscreenbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: h * 0.4,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_isExpanded,
                      child: GestureDetector(
                        onTap: () => setState(() => _isExpanded = false),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                          child: Image.asset(
                            _isExpanded
                                ? 'assets/images/plumber.png'
                                : 'assets/images/water.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          _isExpanded
                              ? 'assets/images/water.png'
                              : 'assets/images/plumber.png',
                          width: 82,
                          height: 82,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => GestureDetector(
                          onTap: () {
                            if (index == 0) {
                              setState(() => _isExpanded = false);
                            } else if (index == 1) {
                              setState(() => _isExpanded = true);
                            }
                            // Others do nothing
                          },
                          child: Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: index == (_isExpanded ? 1 : 0)
                                  ? Colors.orange
                                  : const Color(0xFFD9D9D9),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: h * 0.4 + 10,
              left: w * 0.04,
              child: const Text(
                'Business Name',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: h * 0.4 + 35,
              left: w * 0.04,
              child: const Text(
                'Profession - Years of Experience',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            Positioned(
              top: h * 0.4 + 60,
              left: w * 0.04,
              child: Row(
                children: [
                  Container(
                    width: 148,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA10D),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Call Now',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 148,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA10D),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Message',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: h * 0.4 + 100,
              left: w * 0.04,
              child: const Text(
                'About Me',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: h * 0.4 + 130,
              left: w * 0.04,
              right: w * 0.04,
              child: RichText(
                text: TextSpan(
                  text:
                      'Worker’s Profession Description appears here like what the profession is all about, the location, the specialities and many more ',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  children: [
                    if (_isDescriptionExpanded)
                      const TextSpan(text: 'additional words here '),
                    TextSpan(
                      text: _isDescriptionExpanded
                          ? 'Read less'
                          : 'Read more...',
                      style: const TextStyle(
                        color: Color(0xFFFFA10D),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => setState(
                          () =>
                              _isDescriptionExpanded = !_isDescriptionExpanded,
                        ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: h * 0.4 + 200,
              left: w * 0.04,
              child: const Text(
                'Review Section',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: h * 0.4 + 230,
              left: w * 0.04,
              right: w * 0.04,
              child: Container(
                height: 105,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Positioned(
              top: h * 0.4 + 10,
              right: w * 0.04,
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    '4.6',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '(200)',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 20,
              right: w * 0.04,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications, color: Colors.black),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 20,
              left: w * 0.04,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
