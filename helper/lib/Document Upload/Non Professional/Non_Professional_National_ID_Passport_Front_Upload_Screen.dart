import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:helper/Document%20Upload/Non%20Professional/Non_Professional_National_ID_Passport_Back_Upload_Screen.dart';
import 'package:helper/Document%20Upload/Non%20Professional/Non_Professional_National_ID_Passport_Front_Scan_Screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:helper/Document Upload/National_ID_Passport_Front_Scan_Screen.dart';
import 'package:helper/Document Upload/National_ID_Passport_Back_Upload_Screen.dart';

class NonProfessionalNationalIdPassportFrontUploadScreen
    extends StatefulWidget {
  final int selected;
  final XFile? initialImage;
  const NonProfessionalNationalIdPassportFrontUploadScreen({
    super.key,
    required this.selected,
    this.initialImage,
  });

  @override
  State<NonProfessionalNationalIdPassportFrontUploadScreen> createState() =>
      _NonProfessionalNationalIdPassportFrontUploadScreenState();
}

class _NonProfessionalNationalIdPassportFrontUploadScreenState
    extends State<NonProfessionalNationalIdPassportFrontUploadScreen> {
  late int selected;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isAlreadyUploaded = false;
  String? _uploadedUrl;
  bool _isBackUploaded = false;
  String? _backUrl;

  Future<void> _uploadAndSave() async {
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
      final folder = selected == 0
          ? 'Non Professional Workers National IDS'
          : 'Non Professional Workers Passport ID';
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg';
      final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Save to Firestore under user's collection
      final docType = selected == 0 ? 'national_id_front' : 'passport_id_front';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .doc(docType)
          .set({
            'url': downloadUrl,
            'uploadedAt': FieldValue.serverTimestamp(),
            'type': docType,
            'workerType': 'Non Professional Workers',
            'storagePath': '$folder/$fileName',
          });

      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Front uploaded! Now upload the back.')),
      );
      // Navigate to back upload screen and only pop with true if both are uploaded
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              NonProfessionalNationalIdPassportBackUploadScreen(
                selected: selected,
                initialImage: null,
              ),
        ),
      );
      if (result == true) {
        Navigator.of(
          context,
        ).pop(true); // Only mark row orange if both sides uploaded
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_selectedImage != null) return; // Prevent picking if already set
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _removeBackImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docType = selected == 0 ? 'national_id_back' : 'passport_id_back';
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .doc(docType)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final storagePath = data['storagePath'];
        await FirebaseStorage.instance.ref().child(storagePath).delete();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('documents')
            .doc(docType)
            .delete();
        setState(() {
          _isBackUploaded = false;
          _backUrl = null;
        });
      }
    }
  }

  void _navigateToBack() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NonProfessionalNationalIdPassportBackUploadScreen(
          selected: selected,
          initialImage: null,
        ),
      ),
    );
  }

  void _removeImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docType = selected == 0 ? 'national_id_front' : 'passport_id_front';
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('documents')
          .doc(docType)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final storagePath = data['storagePath'];
        await FirebaseStorage.instance.ref().child(storagePath).delete();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('documents')
            .doc(docType)
            .delete();
        setState(() {
          _isAlreadyUploaded = false;
          _uploadedUrl = null;
          _selectedImage = null;
        });
      }
    } else {
      setState(() {
        _selectedImage = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    selected = widget.selected;
    if (widget.initialImage != null) {
      _selectedImage = widget.initialImage;
    }
    _checkExistingUpload();
  }

  Future<void> _checkExistingUpload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final frontDocType = selected == 0
        ? 'national_id_front'
        : 'passport_id_front';
    final backDocType = selected == 0 ? 'national_id_back' : 'passport_id_back';
    final frontDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('documents')
        .doc(frontDocType)
        .get();
    final backDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('documents')
        .doc(backDocType)
        .get();
    setState(() {
      if (frontDoc.exists) {
        final data = frontDoc.data() as Map<String, dynamic>;
        _isAlreadyUploaded = true;
        _uploadedUrl = data['url'];
      }
      if (backDoc.exists) {
        final data = backDoc.data() as Map<String, dynamic>;
        _isBackUploaded = true;
        _backUrl = data['url'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
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
                      'National ID/Passport',
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

              if (_selectedImage == null && !_isAlreadyUploaded) ...[
                Positioned(
                  top: screenHeight * 0.14,
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
                              'Upload the front part of your ID',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
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
                                              fontFamily: 'Inter',
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
                                              fontFamily: 'Inter',
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
                      fontFamily: 'Inter',
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
                          onPressed: _selectedImage != null
                              ? null
                              : () {
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              NonProfessionalNationalIdPassportFrontScanScreen(
                                                selected: selected,
                                              ),
                                        ),
                                      )
                                      .then((result) {
                                        if (result is XFile) {
                                          setState(() {
                                            _selectedImage = result;
                                          });
                                        }
                                      });
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
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.062,
                        child: ElevatedButton(
                          onPressed: _selectedImage != null
                              ? null
                              : _pickImageFromGallery,
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
                                    fontFamily: 'Inter',
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
              ] else ...[
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 70),
                      // Front image
                      Container(
                        width: screenWidth * 0.9,
                        height: screenWidth * 0.7,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 4),
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.black.withOpacity(0.1),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: _isAlreadyUploaded
                                  ? Image.network(
                                      _uploadedUrl!,
                                      fit: BoxFit.contain,
                                      width: screenWidth * 0.8,
                                    )
                                  : Image.file(
                                      File(_selectedImage!.path),
                                      fit: BoxFit.contain,
                                      width: screenWidth * 0.8,
                                    ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isBackUploaded) ...[
                        const SizedBox(height: 20),
                        // Back image
                        Container(
                          width: screenWidth * 0.9,
                          height: screenWidth * 0.7,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 4),
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.black.withOpacity(0.1),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Image.network(
                                  _backUrl!,
                                  fit: BoxFit.contain,
                                  width: screenWidth * 0.8,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _removeBackImage(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: screenWidth * 0.9,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isAlreadyUploaded
                              ? (_isBackUploaded
                                    ? null
                                    : () => _navigateToBack())
                              : (_isUploading || _selectedImage == null
                                    ? null
                                    : _uploadAndSave),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDF8800),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  _isAlreadyUploaded
                                      ? (_isBackUploaded
                                            ? 'Both Uploaded'
                                            : 'Upload Back')
                                      : 'Continue',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
