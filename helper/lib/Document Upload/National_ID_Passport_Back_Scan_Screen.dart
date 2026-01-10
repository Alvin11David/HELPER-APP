import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class NationalIdPassportBackScanScreen extends StatefulWidget {
  const NationalIdPassportBackScanScreen({super.key});

  @override
  State<NationalIdPassportBackScanScreen> createState() =>
      _NationalIdPassportBackScanScreenState();
}

class _NationalIdPassportBackScanScreenState
    extends State<NationalIdPassportBackScanScreen> {
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
            // ✅ keep same frame size/position as your front scan
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

                // header (back + title)
                Positioned(
                  top: screenHeight * 0.05,
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
                        'ID Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat', // keep same as your base
                        ),
                      ),
                    ],
                  ),
                ),

                // top glass pill instruction
                Positioned(
                  top: screenHeight * 0.14,
                  left: screenWidth * 0.10,
                  right: screenWidth * 0.10,
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
                              'Place the back part of your ID in the frame',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.034,
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

                // frame border
                Positioned(
                  left: (screenWidth - 296) / 2,
                  top: (screenHeight - 489) / 2 + 20,
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
