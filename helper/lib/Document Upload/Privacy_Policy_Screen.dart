import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFA10D),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/normalscreenbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Last updated: February 16, 2026',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Introduction
                    _buildSectionTitle('1. Introduction'),
                    const SizedBox(height: 10),
                    const Text(
                      'Welcome to Helper App. We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use our mobile application.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Information We Collect
                    _buildSectionTitle('2. Information We Collect'),
                    const SizedBox(height: 10),
                    const Text(
                      'We collect information you provide directly to us, such as when you create an account, update your profile, or contact us for support. This may include:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildBulletPoint(
                      'Personal information (name, email, phone number)',
                    ),
                    _buildBulletPoint(
                      'Profile information (skills, location, availability)',
                    ),
                    _buildBulletPoint('Payment information for transactions'),
                    _buildBulletPoint(
                      'Communication data (messages, reviews, ratings)',
                    ),
                    const SizedBox(height: 30),

                    // How We Use Your Information
                    _buildSectionTitle('3. How We Use Your Information'),
                    const SizedBox(height: 10),
                    const Text(
                      'We use the information we collect to:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildBulletPoint('Provide and maintain our services'),
                    _buildBulletPoint('Process payments and transactions'),
                    _buildBulletPoint(
                      'Connect service providers with customers',
                    ),
                    _buildBulletPoint('Send notifications and updates'),
                    _buildBulletPoint(
                      'Improve our app and develop new features',
                    ),
                    const SizedBox(height: 30),

                    // Information Sharing
                    _buildSectionTitle('4. Information Sharing'),
                    const SizedBox(height: 10),
                    const Text(
                      'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy. We may share your information in the following circumstances:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildBulletPoint(
                      'With service providers to facilitate bookings',
                    ),
                    _buildBulletPoint(
                      'With payment processors for transaction processing',
                    ),
                    _buildBulletPoint(
                      'When required by law or to protect our rights',
                    ),
                    _buildBulletPoint('With your explicit consent'),
                    const SizedBox(height: 30),

                    // Data Security
                    _buildSectionTitle('5. Data Security'),
                    const SizedBox(height: 10),
                    const Text(
                      'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Your Rights
                    _buildSectionTitle('6. Your Rights'),
                    const SizedBox(height: 10),
                    const Text(
                      'You have the right to:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildBulletPoint(
                      'Access and update your personal information',
                    ),
                    _buildBulletPoint('Request deletion of your data'),
                    _buildBulletPoint('Opt out of marketing communications'),
                    _buildBulletPoint(
                      'File a complaint with supervisory authorities',
                    ),
                    const SizedBox(height: 30),

                    // Contact Us
                    _buildSectionTitle('7. Contact Us'),
                    const SizedBox(height: 10),
                    const Text(
                      'If you have any questions about this Privacy Policy or our data practices, please contact us at:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Email: privacy@helperapp.com\nPhone: +256 700 000 000\nAddress: Kampala, Uganda',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Changes to Policy
                    _buildSectionTitle('8. Changes to This Policy'),
                    const SizedBox(height: 10),
                    const Text(
                      'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last updated" date.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFFA10D),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
