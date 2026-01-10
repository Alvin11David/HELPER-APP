import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  // Add a variable to hold the captured image
  dynamic _capturedImage;

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isFlashOn = false;
  late FaceDetector _faceDetector;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: false,
        enableLandmarks: false,
        enableTracking: false,
      ),
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      _controller = CameraController(frontCamera, ResolutionPreset.medium);
      await _controller!.initialize();
      await _controller!.startImageStream(_processImage);
      setState(() {});
    }
  }

  void _processImage(CameraImage image) async {
    if (_isCapturing || _capturedImage != null) return;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final camera = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;
    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );

    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      final face = faces.first;
      final centerX = (face.boundingBox.left + face.boundingBox.right) / 2;
      final centerY = (face.boundingBox.top + face.boundingBox.bottom) / 2;

      // Check if face center is within the approximate screen rectangle area
      // Assuming the image is scaled to fit screen, check relative positions
      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();

      // Rectangle covers 0.8 width centered, so 0.1 to 0.9 of image width
      // Height from 0.25 to 0.67 of screen height, map to image
      if (centerX > imageWidth * 0.1 &&
          centerX < imageWidth * 0.9 &&
          centerY > imageHeight * 0.25 &&
          centerY < imageHeight * 0.67) {
        _isCapturing = true;
        try {
          final imageFile = await _controller!.takePicture();
          _capturedImage = imageFile;
          setState(() {});
          _controller!.stopImageStream();
        } catch (e) {
          _isCapturing = false;
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!)
          else
            Container(color: Colors.black),
          Positioned.fill(
            child: ClipPath(
              clipper: InvertedRectangleClipper(
                Rect.fromLTWH(
                  (screenWidth - screenWidth * 0.8) / 2,
                  screenHeight * 0.25,
                  screenWidth * 0.8,
                  screenHeight * 0.42,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.05,
            left: screenWidth * 0.04,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_capturedImage != null) {
                      setState(() {
                        _capturedImage = null;
                      });
                      _controller?.startImageStream(_processImage);
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
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
                  _capturedImage != null ? 'Selfie Preview' : 'Selfie Capture',
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
          Positioned(
            top: screenHeight * 0.14, // Adjusted to reduce space from header
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
                        _capturedImage != null
                            ? 'Preview your selfie'
                            : 'Position your face within the frame',
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
          Positioned(
            top: screenHeight * 0.25,
            left: (screenWidth - screenWidth * 0.8) / 2,
            child: Container(
              width: screenWidth * 0.8,
              height: screenHeight * 0.42,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Positioned(
            top:
                screenHeight * 0.25 + screenHeight * 0.42 + screenHeight * 0.02,
            left: (screenWidth - screenWidth * 0.1) / 2,
            child: GestureDetector(
              onTap: () async {
                if (_controller != null) {
                  if (_isFlashOn) {
                    await _controller!.setFlashMode(FlashMode.off);
                  } else {
                    await _controller!.setFlashMode(FlashMode.torch);
                  }
                  setState(() {
                    _isFlashOn = !_isFlashOn;
                  });
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: screenWidth * 0.1,
                    height: screenWidth * 0.1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
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
                    child: Center(
                      child: Icon(
                        Icons.flashlight_on,
                        color: Colors.white,
                        size: screenWidth * 0.06,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_capturedImage != null)
            Positioned(
              top: screenHeight * 0.8,
              left: (screenWidth - screenWidth * 0.9) / 2,
              child: Container(
                width: screenWidth * 0.9,
                height: screenHeight * 0.08,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.black,
                      size: screenWidth * 0.06,
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: screenHeight * 0.06,
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
                          'Use good lighting and ensure your face matches your\nID photo',
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
      ),
    );
  }
}

class InvertedRectangleClipper extends CustomClipper<Path> {
  final Rect rect;

  InvertedRectangleClipper(this.rect);

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    path.addRect(rect);
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
