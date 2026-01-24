import 'package:flutter/material.dart';
import 'package:helper/Components/Bottom_Nav_Bar.dart';
import 'package:helper/Components/user_avatar_circle.dart';
import 'package:helper/Components/User_Name.dart'; // Add this import
import 'package:helper/Components/User_Email_Or_Phone_Number.dart'; // Add this import
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/services.dart'; // For input formatters

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _imageUrl; // To store the uploaded image URL
  bool _isExpanded = false; // To control expansion
  bool _isWalletExpanded = false; // To control Wallet PIN expansion
  bool _isHelpExpanded = false; // To control Help & Support expansion

  final TextEditingController _previousPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      try {
        // Get current user
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
          return;
        }

        // Upload to Firebase Storage
        String fileName =
            'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(
          'Profile Pictures/$fileName',
        );
        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Save URL to Firestore
        await FirebaseFirestore.instance
            .collection('Sign Up')
            .doc(user.uid)
            .update({'photoUrl': downloadUrl});

        setState(() {
          _imageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    }
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows full height if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            bool _isButtonEnabled = false;

            Future<String?> _fetchStoredPassword() async {
              try {
                User? user = FirebaseAuth.instance.currentUser;
                if (user == null) return null;
                DocumentSnapshot doc = await FirebaseFirestore.instance
                    .collection('Sign Up')
                    .doc(user.uid)
                    .get();
                if (doc.exists && doc.data() != null) {
                  return (doc.data() as Map<String, dynamic>)['password']
                      as String?;
                }
                return null;
              } catch (e) {
                return null;
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(
                  context,
                ).viewInsets.bottom, // Adjust for keyboard
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _previousPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Previous Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                    ),
                    onChanged: (value) async {
                      String? stored = await _fetchStoredPassword();
                      setState(() {
                        _isButtonEnabled = value == stored && value.isNotEmpty;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isButtonEnabled
                          ? Colors.orange
                          : Colors
                                .grey, // Orange when enabled, grey when disabled
                    ),
                    onPressed: _isButtonEnabled
                        ? () async {
                            String newPass = _newPasswordController.text;
                            if (newPass.isNotEmpty) {
                              try {
                                User? user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  await FirebaseFirestore.instance
                                      .collection('Sign Up')
                                      .doc(user.uid)
                                      .update({'password': newPass});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password updated successfully!',
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context); // Close the sheet
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error updating password: $e',
                                    ),
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a new password'),
                                ),
                              );
                            }
                          }
                        : null, // Disabled when not enabled
                    child: const Text(
                      'Change Password',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChangeWalletPinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (BuildContext context) {
        return const _ChangeWalletPinSheet();
      },
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (BuildContext context) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              );
            }
            Map<String, dynamic>? data = snapshot.data;
            final TextEditingController _fullNameController =
                TextEditingController(text: data?['fullName'] ?? '');
            final TextEditingController _contactController =
                TextEditingController();
            String _contactLabel = '';
            if (data?.containsKey('email') == true && data!['email'] != null) {
              _contactController.text = data['email'];
              _contactLabel = 'Email Address';
            } else if (data?.containsKey('phoneNumber') == true &&
                data!['phoneNumber'] != null) {
              _contactController.text = data['phoneNumber'];
              _contactLabel = 'Phone Number';
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Names',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_contactLabel.isNotEmpty)
                    TextFormField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        labelText: _contactLabel,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: () async {
                      try {
                        User? user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          Map<String, dynamic> updates = {};
                          if (_fullNameController.text.isNotEmpty) {
                            updates['fullName'] = _fullNameController.text;
                          }
                          if (_contactLabel == 'Email Address' &&
                              _contactController.text.isNotEmpty) {
                            updates['email'] = _contactController.text;
                          } else if (_contactLabel == 'Phone Number' &&
                              _contactController.text.isNotEmpty) {
                            updates['phoneNumber'] = _contactController.text;
                          }
                          if (updates.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('Sign Up')
                                .doc(user.uid)
                                .update(updates);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully!'),
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No changes made')),
                            );
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating profile: $e')),
                        );
                      }
                    },
                    child: const Text(
                      'Change',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
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
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: screenHeight * 0.10, // Moved below the Profile row
                left: screenWidth / 2 - 100,
                right: screenWidth / 2 - 100, // Center horizontally
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Squeezed to form 5 rows
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          child: UserAvatarCircle(
                            imageUrl: _imageUrl,
                          ), // Pass imageUrl if supported
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAndUploadImage,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.upload,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    UserName(), // Added below the circle
                    UserEmailOrPhoneNumber(), // Added below UserName
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: screenHeight * 0.59, // Adjust height as needed
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    left: 0,
                    right: 0,
                    bottom: 0,
                  ), // Bottom left and right padding set to 0
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Account Overview',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCAE8FA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF027AC1),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'My Profile',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isExpanded = !_isExpanded),
                              child: Icon(
                                _isExpanded
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _isExpanded
                            ? 50
                            : 20, // Increased height to prevent overflow
                        child: _isExpanded
                            ? SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showEditProfileSheet(context),
                                        child: Row(
                                          children: [
                                            const SizedBox(
                                              width: 45,
                                            ), // Space for removed square
                                            const Text(
                                              'Edit Profile',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showChangePasswordSheet(context),
                                        child: Row(
                                          children: [
                                            const SizedBox(
                                              width: 45,
                                            ), // Space for removed square
                                            const Text(
                                              'Change Password',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(
                                            width: 45,
                                          ), // Space for removed square
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFEF96),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.wallet,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Wallet PIN',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(
                                () => _isWalletExpanded = !_isWalletExpanded,
                              ),
                              child: Icon(
                                _isWalletExpanded
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _isWalletExpanded
                            ? 30
                            : 25, // Height for Wallet PIN options
                        child: _isWalletExpanded
                            ? SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showChangeWalletPinSheet(context),
                                        child: Row(
                                          children: [
                                            const SizedBox(
                                              width: 45,
                                            ), // Space for removed square
                                            const Text(
                                              'Change Wallet PIN',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC491E2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.help,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Help & Support',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(
                                () => _isHelpExpanded = !_isHelpExpanded,
                              ),
                              child: Icon(
                                _isHelpExpanded
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _isHelpExpanded
                            ? 100
                            : 0, // Height for Help & Support options
                        child: _isHelpExpanded
                            ? SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          // Add logic for Contact Support
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Contact Support tapped',
                                              ),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            const SizedBox(
                                              width: 45,
                                            ), // Space for removed square
                                            const Text(
                                              'Contact Support',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          // Add logic for FAQ
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('FAQ tapped'),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            const SizedBox(
                                              width: 45,
                                            ), // Space for removed square
                                            const Text(
                                              'FAQ',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(), // Add BottomNavBar at the bottom
    );
  }
}

class _ChangeWalletPinSheet extends StatefulWidget {
  const _ChangeWalletPinSheet();

  @override
  _ChangeWalletPinSheetState createState() => _ChangeWalletPinSheetState();
}

class _ChangeWalletPinSheetState extends State<_ChangeWalletPinSheet> {
  String? currentPin;
  final TextEditingController _currentPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  bool _isButtonEnabled = false;
  String _enteredCurrentPin = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentPin();
  }

  Future<void> _fetchCurrentPin() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          currentPin =
              (doc.data() as Map<String, dynamic>)['wallet_pin'] as String?;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Change Wallet PIN',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _currentPinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: const InputDecoration(
              labelText: 'Current PIN (4 digits)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
            ),
            onChanged: (value) {
              _enteredCurrentPin = value;
              setState(() {
                _isButtonEnabled =
                    (_enteredCurrentPin == currentPin) &&
                    _newPinController.text.length == 4 &&
                    _newPinController.text != currentPin;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: const InputDecoration(
              labelText: 'New PIN (4 digits)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _isButtonEnabled =
                    (_enteredCurrentPin == currentPin) &&
                    value.length == 4 &&
                    value != currentPin;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isButtonEnabled ? Colors.orange : Colors.grey,
            ),
            onPressed: _isButtonEnabled
                ? () async {
                    String newPin = _newPinController.text;
                    if (newPin.length == 4 &&
                        _enteredCurrentPin == currentPin) {
                      try {
                        User? user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('Sign Up')
                              .doc(user.uid)
                              .update({'wallet_pin': newPin});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Wallet PIN updated successfully!'),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating PIN: $e')),
                        );
                      }
                    }
                  }
                : null,
            child: const Text(
              'Change PIN',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
