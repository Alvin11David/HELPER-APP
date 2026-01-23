import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:helper/Document%20Upload/National_ID_Passport_Back_Upload_Screen.dart';

class NationalIdPassportBackScanScreen extends StatefulWidget {
  final int selected; // 0 for National ID, 1 for Passport
  const NationalIdPassportBackScanScreen({super.key, required this.selected});

  @override
  State<NationalIdPassportBackScanScreen> createState() =>
      _NationalIdPassportBackScanScreenState();
}

class _NationalIdPassportBackScanScreenState
    extends State<NationalIdPassportBackScanScreen> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  XFile? _capturedImage;
  bool _isAnalyzing = false;
  bool _isVerifying = false;
  DateTime? _streamStartTime;
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(firstCamera, ResolutionPreset.high);
    await _controller.initialize();
    _streamStartTime = DateTime.now();
    _controller.startImageStream(_processImage);
  }

  void _processImage(CameraImage image) async {
    if (_isAnalyzing || _capturedImage != null) return;
    // Wait for 6 seconds after stream starts before allowing capture
    if (_streamStartTime != null &&
        DateTime.now().difference(_streamStartTime!).inSeconds < 6) {
      return;
    }
    _isAnalyzing = true;
    final inputImage = _getInputImageFromCameraImage(image);
    if (inputImage == null) {
      _isAnalyzing = false;
      return;
    }
    final brightness = _calculateBrightness(image);
    if (brightness < 0.1) {
      _isAnalyzing = false;
      return;
    }
    _captureImage();
    _isAnalyzing = false;
  }

  double _calculateBrightness(CameraImage image) {
    final plane = image.planes[0];
    final bytes = plane.bytes;
    double sum = 0;
    int count = 0;
    for (int i = 0; i < bytes.length; i += 100) {
      // Sample every 100th pixel
      sum += bytes[i];
      count++;
    }
    return count > 0 ? sum / count / 255.0 : 0.0;
  }

  InputImage? _getInputImageFromCameraImage(CameraImage image) {
    final camera = _controller.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    switch (sensorOrientation) {
      case 0:
        rotation = InputImageRotation.rotation0deg;
        break;
      case 90:
        rotation = InputImageRotation.rotation90deg;
        break;
      case 180:
        rotation = InputImageRotation.rotation180deg;
        break;
      case 270:
        rotation = InputImageRotation.rotation270deg;
        break;
      default:
        return null;
    }

    final format = _getInputImageFormat(image.format.group);
    if (format == null) return null;

    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image
            .planes[0]
            .bytesPerRow, // Added for completeness, as InputImageMetadata may require it
      ),
    );
  }

  InputImageFormat? _getInputImageFormat(ImageFormatGroup group) {
    switch (group) {
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv420;
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888;
      default:
        return null;
    }
  }

  void _captureImage() async {
    try {
      final image = await _controller.takePicture();
      setState(() {
        _capturedImage = image;
      });
      _controller.stopImageStream();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
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
                child: const Text(
                  'Image captured!',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _controller.stopImageStream();
    _controller.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    if (_initializeControllerFuture == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Camera error: ${snapshot.error}'));
            }
            final double rectLeft = (screenWidth - 296) / 2;
            final double rectTop = (screenHeight - 489) / 2 + 20;

            return Stack(
              children: [
                CameraPreview(_controller),
                ClipPath(
                  clipper: InvertedRectangleClipper(
                    rect: Rect.fromLTWH(rectLeft, rectTop, 296, 489),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withOpacity(0.5)),
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
                            _controller.startImageStream(_processImage);
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
                        _capturedImage != null ? 'ID Back Preview' : 'ID Back',
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
                              _capturedImage != null
                                  ? 'Preview the back of the ID'
                                  : 'Place the back part of your ID in the frame',
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
                  left: (screenWidth - 296) / 2,
                  top: (screenHeight - 489) / 2 + 20,
                  child: SizedBox(
                    width: 296,
                    height: 489,
                    child: _capturedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.file(
                              File(_capturedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: screenHeight * 0.03,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06,
                            vertical: screenHeight * 0.011,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: screenHeight * 0.07),
                              SizedBox(
                                width: double.infinity,
                                height: screenHeight * 0.062,
                                child: ElevatedButton(
                                  onPressed:
                                      _isVerifying || _capturedImage == null
                                      ? null
                                      : () async {
                                          setState(() {
                                            _isVerifying = true;
                                          });
                                          final result =
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      NationalIdPassportBackUploadScreen(
                                                        selected:
                                                            widget.selected,
                                                        initialImage:
                                                            _capturedImage,
                                                      ),
                                                ),
                                              );
                                          setState(() {
                                            _isVerifying = false;
                                          });
                                          if (result == true) {
                                            Navigator.of(context).pop(true);
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.white
                                        .withOpacity(0.6),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: _isVerifying
                                      ? SizedBox(
                                          width: screenHeight * 0.03,
                                          height: screenHeight * 0.03,
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: Colors.white,
                                              ),
                                        )
                                      : Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Continue',
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.045,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              SizedBox(
                                                width: screenWidth * 0.02,
                                              ),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.black,
                                                size: screenHeight * 0.035,
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
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
          } else {
            return const Center(child: CircularProgressIndicator());
          }
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
