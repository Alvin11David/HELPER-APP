import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserAvatarCircle extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final double borderWidth;

  const UserAvatarCircle({
    super.key,
    this.size = 40,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black,
    this.borderWidth = 1.5, String? imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return _buildDefaultAvatar();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Sign Up')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingAvatar();
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildDefaultAvatar();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final photoUrl = userData?['photoUrl'] as String?;

        if (photoUrl == null || photoUrl.isEmpty) {
          return _buildDefaultAvatar();
        }

        return _buildNetworkAvatar(photoUrl);
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: iconColor, width: borderWidth),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: size * 0.6,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: iconColor, width: borderWidth),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkAvatar(String photoUrl) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: iconColor, width: borderWidth),
      ),
      child: ClipOval(
        child: Image.network(
          photoUrl,
          fit: BoxFit.cover,
          width: size,
          height: size,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: iconColor,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      ),
    );
  }
}