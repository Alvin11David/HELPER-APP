import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Employer Dashboard/Create_Wallet_PIN_Screen.dart';

class BottomNavBar extends StatefulWidget {
  final Function(int)? onItemTapped;
  const BottomNavBar({super.key, this.onItemTapped});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  void _showPINEntryModal() {
    String _pin = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double screenWidth = MediaQuery.of(context).size.width;
            return Container(
              height: 270, // Fixed height to prevent the modal from shrinking
              width: double.infinity, // Fixed width to prevent width changes
              padding: EdgeInsets.only(left: 0, right: 0, bottom: 0),
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
                  _pin.isEmpty
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: _pin.length > index
                                    ? Colors.black
                                    : Color(0xFFD9D9D9),
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        )
                      : SizedBox(
                          height: 15,
                        ), // Maintain height when circles are hidden
                  Transform.translate(
                    offset: Offset(
                      0,
                      -30,
                    ), // Move up by 8 pixels to be very close to the circles
                    child: Container(
                      width: screenWidth * 0.35, // Reduced from 0.8 to 0.6
                      child: TextField(
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                          ), // Reduce vertical padding to lift the underline
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _pin = value;
                          });
                          if (_pin.length == 4) {
                            // TODO: Verify PIN
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 0),
                  Text(
                    'Forgot PIN?',
                    style: TextStyle(
                      color: Color(0xFFFFA10D),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
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
              print('Tapped index: $index');
              if (index == 2) {
                print('Wallet tapped');
                try {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  bool pinSet = prefs.getBool('wallet_pin_set') ?? false;
                  String? savedPin = prefs.getString('wallet_pin');
                  print('pinSet: $pinSet, savedPin: $savedPin');
                  if (!pinSet) {
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
