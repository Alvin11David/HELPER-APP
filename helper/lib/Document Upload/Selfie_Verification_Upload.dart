import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'Face_Scan_Screen.dart';

class SelfieCaptureScreen extends StatefulWidget {
  const SelfieCaptureScreen({super.key});

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen> {
  static const _brandYellow = Color(0xFFFFC700);
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isUploading = false;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _loadExistingSelfie();
  }

  Future<void> _loadExistingSelfie() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .doc('selfie')
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _existingImageUrl = data['url'];
        });
      }
    }
  }

  void _takePhoto() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => FaceScanScreen()));
    if (result == 'uploaded') {
      Navigator.of(context).pop(true);
    } else if (result is XFile) {
      setState(() {
        _selectedImage = result;
      });
    }
  }

  void _openGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _uploadSelfie() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }

    try {
      final file = File(_selectedImage!.path);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg';
      final ref = FirebaseStorage.instance.ref().child('Selfies/$fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Save to Firestore under user's collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .doc('selfie')
          .set({
            'url': downloadUrl,
            'uploadedAt': FieldValue.serverTimestamp(),
            'type': 'selfie',
            'storagePath': 'Selfies/$fileName',
          });

      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selfie uploaded successfully!')),
      );

      // Navigate back
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final headerFont = (w * 0.06).clamp(20.0, 26.0);
    final pillFont = (w * 0.032).clamp(12.0, 14.0);

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.black, // 🔥 whole screen black
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: 18 + MediaQuery.of(context).padding.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Stack(
                      children: [
                        // Header row
                        Padding(
                          padding: EdgeInsets.only(
                            top: h * 0.03,
                            left: w * 0.04,
                            right: w * 0.04,
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).maybePop(),
                                child: Container(
                                  width: w * 0.13,
                                  height: w * 0.13,
                                  constraints: const BoxConstraints(
                                    maxWidth: 56,
                                    maxHeight: 56,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.chevron_left,
                                      color: Colors.black,
                                      size: (w * 0.10).clamp(20.0, 34.0),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: w * 0.05),
                              Expanded(
                                child: Text(
                                  'Selfie Capture',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'AbrilFatface',
                                    fontSize: headerFont,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Main content
                        Padding(
                          padding: EdgeInsets.only(
                            top: h * 0.14,
                            left: w * 0.06,
                            right: w * 0.06,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: h * 0.03), // space from title
                              // Glass instruction
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 12,
                                    sigmaY: 12,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 26,
                                      vertical: 8,
                                    ), // thinner height
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.25),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          'Make sure your face is clearly visible and well lit.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            height: 1.15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: h * 0.05,
                              ), // space before selfie frame (important)

                              if (_selectedImage == null &&
                                  _existingImageUrl == null) ...[
                                // Framed preview with person.png
                                _PreviewFrame(
                                  height: (h * 0.40).clamp(260.0, 360.0),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: w * 0.06,
                                      vertical: h * 0.02,
                                    ),
                                    child: Image.asset(
                                      'assets/images/person.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  height: h * 0.06,
                                ), // space before buttons (important)
                                // Take a photo button (yellow)
                                _PrimaryButton(
                                  text: 'Take a photo',
                                  icon: Icons.photo_camera_rounded,
                                  onTap: _takePhoto,
                                  background: _brandYellow,
                                  textColor: Colors.black,
                                  iconColor: Colors.black,
                                ),

                                SizedBox(height: h * 0.018),

                                // Gallery button (white)
                                _PrimaryButton(
                                  text: 'Gallery',
                                  icon: Icons.photo_library_rounded,
                                  onTap: _openGallery,
                                  background: Colors.white,
                                  textColor: Colors.black,
                                  iconColor: Colors.black,
                                ),
                              ] else if (_selectedImage == null &&
                                  _existingImageUrl != null) ...[
                                // White stroke rectangle with existing image
                                Container(
                                  width: double.infinity,
                                  height: (h * 0.40).clamp(260.0, 360.0),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: w * 0.06,
                                        vertical: h * 0.02,
                                      ),
                                      child: Image.network(
                                        _existingImageUrl!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: h * 0.06),

                                // Take a photo button (yellow)
                                _PrimaryButton(
                                  text: 'Take a photo',
                                  icon: Icons.photo_camera_rounded,
                                  onTap: _takePhoto,
                                  background: _brandYellow,
                                  textColor: Colors.black,
                                  iconColor: Colors.black,
                                ),

                                SizedBox(height: h * 0.018),

                                // Gallery button (white)
                                _PrimaryButton(
                                  text: 'Gallery',
                                  icon: Icons.photo_library_rounded,
                                  onTap: _openGallery,
                                  background: Colors.white,
                                  textColor: Colors.black,
                                  iconColor: Colors.black,
                                ),
                              ] else ...[
                                // White stroke rectangle with selected image
                                Container(
                                  width: double.infinity,
                                  height: (h * 0.40).clamp(260.0, 360.0),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: w * 0.06,
                                        vertical: h * 0.02,
                                      ),
                                      child: Image.file(
                                        File(_selectedImage!.path),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: h * 0.06),

                                // Orange Continue button
                                GestureDetector(
                                  onTap: _uploadSelfie,
                                  child: Container(
                                    width: w * 0.9,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: _brandYellow,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.16),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: _isUploading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                                strokeWidth: 3,
                                              ),
                                            )
                                          : Text(
                                              'Continue',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w800,
                                                fontSize: (w * 0.040).clamp(
                                                  14.0,
                                                  16.0,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------- UI components ----------------

class _GlassPill extends StatelessWidget {
  final Widget child;
  final double height;

  const _GlassPill({required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.22),
                Colors.white.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.6,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  final Widget child;
  final double height;

  const _PreviewFrame({required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: child),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color textColor;
  final Color iconColor;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
    required this.background,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: (w * 0.05).clamp(18.0, 24.0)),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: (w * 0.040).clamp(14.0, 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
