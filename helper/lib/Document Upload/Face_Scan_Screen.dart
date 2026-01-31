import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isCapturing = false;
  Timer? _captureTimer;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
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
      setState(() {});
      _captureTimer = Timer(Duration(seconds: 10), _takePicture);
    }
  }

  void _takePicture() async {
    if (_controller != null && !_isCapturing && _capturedImage == null) {
      _isCapturing = true;
      try {
        final imageFile = await _controller!.takePicture();
        _capturedImage = imageFile;
        setState(() {});
        _controller!.stopImageStream();
        _captureTimer?.cancel();
      } catch (e) {
        _isCapturing = false;
      }
    }
  }

  void _uploadImage() async {
    if (_capturedImage == null) return;
    setState(() {
      _isUploading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg';
        final ref = FirebaseStorage.instance.ref().child(
          'Professional Workers Selfies/$fileName',
        );
        await ref.putFile(File(_capturedImage.path));
        final downloadUrl = await ref.getDownloadURL();

        // Save to Firestore under user's collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('documents')
            .doc('Professional Workers')
            .set({
              'selfie': {
                'url': downloadUrl,
                'uploadedAt': FieldValue.serverTimestamp(),
                'type': 'selfie',
                'workerType': 'Professional Workers',
                'storagePath': 'Professional Workers Selfies/$fileName',
              },
            }, SetOptions(merge: true));

        Navigator.of(context).pop('uploaded');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _captureTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          child: Stack(
            children: [
              if (_controller != null && _controller!.value.isInitialized)
                Positioned.fill(child: CameraPreview(_controller!))
              else
                Positioned.fill(child: Container(color: Colors.black)),
              if (_capturedImage != null)
                Positioned(
                  top: screenHeight * 0.25,
                  left: (screenWidth - screenWidth * 0.8) / 2,
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.42,
                  child: Image.file(
                    File(_capturedImage.path),
                    fit: BoxFit.cover,
                  ),
                ),
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
                          _captureTimer?.cancel();
                          _captureTimer = Timer(
                            Duration(seconds: 10),
                            _takePicture,
                          );
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
                      _capturedImage != null
                          ? 'Selfie Preview'
                          : 'Selfie Capture',
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
                top:
                    screenHeight * 0.14, // Adjusted to reduce space from header
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
                    screenHeight * 0.25 +
                    screenHeight * 0.42 +
                    screenHeight * 0.02,
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
                  child: GestureDetector(
                    onTap: _isUploading ? null : _uploadImage,
                    child: Container(
                      width: screenWidth * 0.9,
                      height: screenHeight * 0.08,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: _isUploading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            )
                          : Row(
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
                ),
              Positioned(
                bottom: screenHeight * 0.0,
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
        ),
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
