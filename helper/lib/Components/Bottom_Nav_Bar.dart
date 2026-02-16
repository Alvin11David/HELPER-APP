import 'package:flutter/material.dart';
import 'package:helper/Employer%20Dashboard/Create_Wallet_PIN_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Wallet/Wallet_Cancelled_screen.dart';
import '../Chats/Chat_List_Screen.dart';
import '../Document Upload/Profile/Profile_Screen.dart'; // Add this import
import '../Maps/Map_Screen.dart'; // Add this import
import '../Employer Dashboard/Employer_Dashboard_Screen.dart';
import '../Worker Dashboard/Workers_Dashboard_Screen.dart';

class BottomNavBar extends StatefulWidget {
  final Function(int)? onItemTapped;
  final int currentIndex; // Rename and make it the main parameter
  const BottomNavBar({
    super.key,
    this.onItemTapped,
    required this.currentIndex, // Required, no default
  });

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex =
        widget.currentIndex; // Use currentIndex to set the active tab
  }

  void _showPINEntryModal() {
    String pin = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final media = MediaQuery.of(context);
            final screenWidth = media.size.width;
            final bottomInset = media.viewInsets.bottom;
            return AnimatedPadding(
              padding: EdgeInsets.only(bottom: bottomInset),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(left: 0, right: 0, bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 20),
                        Image.asset(
                          'assets/images/padlock.png',
                          width: 50,
                          height: 50,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Enter Your PIN',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        pin.isEmpty
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(4, (index) {
                                  return Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      color: pin.length > index
                                          ? Colors.black
                                          : Color(0xFFD9D9D9),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }),
                              )
                            : SizedBox(height: 15),
                        Transform.translate(
                          offset: Offset(0, -30),
                          child: SizedBox(
                            width: screenWidth * 0.35,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              obscureText: true,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 0,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                              ),
                              onChanged: (value) async {
                                setState(() {
                                  pin = value;
                                });
                                if (pin.length == 4) {
                                  try {
                                    final user =
                                        FirebaseAuth.instance.currentUser;
                                    if (user == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('User not logged in'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      setState(() {
                                        pin = '';
                                      });
                                      return;
                                    }

                                    final doc = await FirebaseFirestore.instance
                                        .collection('Sign Up')
                                        .doc(user.uid)
                                        .get();

                                    if (!doc.exists || doc.data() == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('User data not found'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      setState(() {
                                        pin = '';
                                      });
                                      return;
                                    }

                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final savedPin = data['wallet_pin']
                                        ?.toString();

                                    if (savedPin == null || savedPin.isEmpty) {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CreateWalletPINScreen(),
                                        ),
                                      );
                                      return;
                                    }

                                    if (savedPin == pin) {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              WalletFlowScreen(),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Incorrect PIN'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      setState(() {
                                        pin = '';
                                      });
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error validating PIN: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    setState(() {
                                      pin = '';
                                    });
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 0),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateWalletPINScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot PIN?',
                            style: TextStyle(
                              color: Color(0xFFFFA10D),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateWalletPINScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'I have never created a PIN',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      width: MediaQuery.of(context).size.width,
      color: Color(0xFFFFCB05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          bool isSelected = index == _selectedIndex;
          return GestureDetector(
            onTap: () async {
              if (index == 2) {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please log in to access wallet'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final doc = await FirebaseFirestore.instance
                      .collection('Sign Up')
                      .doc(user.uid)
                      .get();

                  if (!doc.exists || doc.data() == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('User data not found'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final data = doc.data() as Map<String, dynamic>;
                  final savedPin = data['wallet_pin']?.toString();

                  if (savedPin == null || savedPin.isEmpty) {
                    print('Navigating to CreateWalletPINScreen');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateWalletPINScreen(),
                      ),
                    );
                  } else {
                    print('Showing PIN modal');
                    _showPINEntryModal();
                  }
                } catch (e) {
                  print('Error in wallet tap: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error accessing wallet'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapScreen()),
                );
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatListScreen()),
                );
              } else if (index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              } else if (index == 0) {
                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    DocumentSnapshot doc = await FirebaseFirestore.instance
                        .collection('Sign Up')
                        .doc(user.uid)
                        .get();
                    if (doc.exists && doc.data() != null) {
                      final data = doc.data() as Map<String, dynamic>;
                      String role = data['role'] ?? '';
                      if (role == 'employer') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EmployerDashboardScreen(),
                          ),
                        );
                      } else if (role == 'worker') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkersDashboardScreen(),
                          ),
                        );
                      } else {
                        // Default or error
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Role not found')),
                        );
                      }
                    }
                  }
                } catch (e) {
                  print('Error fetching role: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error loading dashboard')),
                  );
                }
              } else {
                setState(() {
                  _selectedIndex = index;
                });
                widget.onItemTapped?.call(index);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Container(
                    height: 3,
                    width: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                Icon(
                  _getIcon(index),
                  color: isSelected ? Colors.white : Colors.black,
                ),
                Text(
                  _getLabel(index),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.map;
      case 2:
        return Icons.account_balance_wallet;
      case 3:
        return Icons.chat;
      case 4:
        return Icons.person;
      default:
        return Icons.home;
    }
  }

  String _getLabel(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Map';
      case 2:
        return 'Wallet';
      case 3:
        return 'Chat';
      case 4:
        return 'Profile';
      default:
        return 'Home';
    }
  }
}
