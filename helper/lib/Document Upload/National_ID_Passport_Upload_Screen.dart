import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class NationalIdPassportFrontUploadScreen extends StatefulWidget {
  const NationalIdPassportFrontUploadScreen({super.key});

  @override
  State<NationalIdPassportFrontUploadScreen> createState() =>
      _NationalIdPassportFrontUploadScreenState();
}

class _NationalIdPassportFrontUploadScreenState
    extends State<NationalIdPassportFrontUploadScreen> {
  int selected = 0;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(firstCamera, ResolutionPreset.high);
    return _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final double rectLeft = (screenWidth - 296) / 2;
            final double rectTop = (screenHeight - 489) / 2 + 20;
            return Stack(
              children: [
                CameraPreview(_controller),
                // blur outside frame
                ClipPath(
                  clipper: InvertedRectangleClipper(
                    rect: Rect.fromLTWH(rectLeft, rectTop, 296, 489),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withOpacity(0.5)),
                  ),
                ),
              // Header row (back + title)
              Positioned(
                top: screenHeight * 0.04,
                left: screenWidth * 0.04,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: screenWidth * 0.13,
                        height: screenWidth * 0.13,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.chevron_left,
                            color: Colors.black,
                            size: screenWidth * 0.10,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.06),
                    Text(
                      'ID Front',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              // SizedBox(height: screenHeight * 0.01), // Removed unused SizedBox
              Positioned(
                top:
                    screenHeight * 0.14, // Adjusted to reduce space from header
                left: screenWidth * 0.15,
                right: screenWidth * 0.15,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: screenHeight * 0.004,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      height: 33,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Place the front part of your ID in the frame',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.16 + 42 + 10,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final segmentW = constraints.maxWidth / 2;
                      return Stack(
                        children: [
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 230),
                            curve: Curves.easeOut,
                            alignment: selected == 0
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              width: segmentW,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => selected = 0),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.badge,
                                          size: 18,
                                          color: selected == 0
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'National ID',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                            color: selected == 0
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => selected = 1),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.credit_card,
                                          size: 18,
                                          color: selected == 1
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Passport',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                            color: selected == 1
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top:
                    MediaQuery.of(context).size.height * 0.16 +
                    80 +
                    10 +
                    44 +
                    20,
                left: screenWidth * 0.09,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/front.png',
                      fit: BoxFit.contain,
                      width: screenWidth * 0.7,
                    ),
                    SizedBox(width: screenWidth * 0.05),
                    Opacity(
                      opacity: 0.5,
                      child: Image.asset(
                        'assets/images/back.png',
                        fit: BoxFit.contain,
                        width: screenWidth * 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top:
                    MediaQuery.of(context).size.height * 0.16 +
                    60 +
                    10 +
                    44 +
                    20 +
                    200,
                left: 0,
                right: 0,
                child: Text(
                  'Front Side',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.075,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Positioned(
                top:
                    MediaQuery.of(context).size.height * 0.16 +
                    30 +
                    10 +
                    44 +
                    20 +
                    200 +
                    50 +
                    screenHeight * 0.07,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.062,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Handle continue action
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDF8800),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera,
                                color: Colors.white,
                                size: screenHeight * 0.035,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Take a photo',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.062,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Handle continue action
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library,
                                color: Colors.black,
                                size: screenHeight * 0.035,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Gallery',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // frame border
              Positioned(
                left: rectLeft,
                top: rectTop,
                child: Container(
                  width: 296,
                  height: 489,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              // bottom glass hint
              Positioned(
                bottom: screenHeight * 0.03,
                left: 0,
                right: 0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: screenHeight * 0.011,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'Make sure text is readable before submitting',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.03,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Camera error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
      ),
    );
  }
}

class InvertedRectangleClipper extends CustomClipper<Path> {
  final Rect rect;

  InvertedRectangleClipper({required this.rect});

  @override
  Path getClip(Size size) {
    Path path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(30)));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}