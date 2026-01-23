import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ProfessionalLicenseUploadScreen extends StatefulWidget {
  const ProfessionalLicenseUploadScreen({super.key});

  @override
  State<ProfessionalLicenseUploadScreen> createState() =>
      _ProfessionalLicenseUploadScreenState();
}

class _ProfessionalLicenseUploadScreenState
    extends State<ProfessionalLicenseUploadScreen> {
  static const _brandYellow = Color(0xFFFFC700);

  String? _selectedType;
  PlatformFile? _selectedFile;

  void _onContinue() {
    // TODO: next
  }

  void _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpeg', 'jpg'],
    );
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    // ✅ prevent right overflow on wide web screens: clamp content width
    final contentMaxWidth = w < 520 ? w : 420.0;

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
              // Header
              Positioned(
                top: h * 0.04,
                left: w * 0.04,
                right: w * 0.04,
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
                            size: (w * 0.10).clamp(20, 34),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Professional License',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (w * 0.06).clamp(20, 26),
                          fontFamily: 'AbrilFatface',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Scrollable body (fixes bottom overflow)
              Positioned(
                top: h * 0.14,
                left: 0,
                right: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        24 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GlassPill(
                            height: 34, // ✅ thinner like the design
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Center(
                              child: Text(
                                'This license is required to verify your eligibility to work',
                                maxLines: 2, // ✅ force one line
                                overflow: TextOverflow
                                    .ellipsis, // ✅ if very small phones
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontFamily: 'AbrilFatface',
                                  fontWeight: FontWeight.w300,
                                  fontSize: 12.5,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ✅ Yellow selected type (shrinks nicely)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _brandYellow,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 12,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/icons/license.png',
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selectedType == null
                                        ? 'Selected license type will appear here'
                                        : _selectedType!,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w900,
                                      fontSize: (w * 0.034).clamp(12, 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ✅ Dropdown (no right overflow)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dropdownMenuTheme: DropdownMenuThemeData(
                                  menuStyle: MenuStyle(
                                    shape: WidgetStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedType,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  isExpanded: true,
                                  borderRadius: BorderRadius.circular(20),
                                  hint: Text(
                                    'Select Your License Type',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w900,
                                      fontSize: (w * 0.034).clamp(12, 14),
                                      color: Colors.black,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Medical License',
                                      child: Text('Medical License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Engineering License',
                                      child: Text('Engineering License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Teaching License',
                                      child: Text('Teaching License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Nursing License',
                                      child: Text('Nursing License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Pharmacy License',
                                      child: Text('Pharmacy License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Dental License',
                                      child: Text('Dental License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Veterinary License',
                                      child: Text('Veterinary License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Law License',
                                      child: Text('Law License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Accounting License',
                                      child: Text('Accounting License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Architecture License',
                                      child: Text('Architecture License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Real Estate License',
                                      child: Text('Real Estate License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Insurance License',
                                      child: Text('Insurance License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Cosmetology License',
                                      child: Text('Cosmetology License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Physical Therapy License',
                                      child: Text('Physical Therapy License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Occupational Therapy License',
                                      child: Text(
                                        'Occupational Therapy License',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Chiropractic License',
                                      child: Text('Chiropractic License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Optometry License',
                                      child: Text('Optometry License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Podiatry License',
                                      child: Text('Podiatry License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Psychologist License',
                                      child: Text('Psychologist License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Social Worker License',
                                      child: Text('Social Worker License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Counselor License',
                                      child: Text('Counselor License'),
                                    ),
                                    DropdownMenuItem(
                                      value:
                                          'Marriage and Family Therapist License',
                                      child: Text(
                                        'Marriage and Family Therapist License',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value:
                                          'Speech-Language Pathologist License',
                                      child: Text(
                                        'Speech-Language Pathologist License',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Audiologist License',
                                      child: Text('Audiologist License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Dietitian License',
                                      child: Text('Dietitian License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Physician Assistant License',
                                      child: Text(
                                        'Physician Assistant License',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Nurse Practitioner License',
                                      child: Text('Nurse Practitioner License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Registered Nurse License',
                                      child: Text('Registered Nurse License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Licensed Practical Nurse License',
                                      child: Text(
                                        'Licensed Practical Nurse License',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Respiratory Therapist License',
                                      child: Text(
                                        'Respiratory Therapist License',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Radiologic Technologist License',
                                      child: Text(
                                        'Radiologic Technologist License',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value:
                                          'Medical Laboratory Scientist License',
                                      child: Text(
                                        'Medical Laboratory Scientist License',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Paramedic License',
                                      child: Text('Paramedic License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'EMT License',
                                      child: Text('EMT License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Firefighter License',
                                      child: Text('Firefighter License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Police Officer License',
                                      child: Text('Police Officer License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Private Investigator License',
                                      child: Text(
                                        'Private Investigator License',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Notary Public License',
                                      child: Text('Notary Public License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Auctioneer License',
                                      child: Text('Auctioneer License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Appraiser License',
                                      child: Text('Appraiser License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Surveyor License',
                                      child: Text('Surveyor License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Geologist License',
                                      child: Text('Geologist License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Chemist License',
                                      child: Text('Chemist License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Biologist License',
                                      child: Text('Biologist License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Actuary License',
                                      child: Text('Actuary License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Financial Planner License',
                                      child: Text('Financial Planner License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Mortgage Broker License',
                                      child: Text('Mortgage Broker License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Barber License',
                                      child: Text('Barber License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Massage Therapist License',
                                      child: Text('Massage Therapist License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Acupuncturist License',
                                      child: Text('Acupuncturist License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Naturopathic Physician License',
                                      child: Text(
                                        'Naturopathic Physician License',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Midwife License',
                                      child: Text('Midwife License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Funeral Director License',
                                      child: Text('Funeral Director License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Landscape Architect License',
                                      child: Text(
                                        'Landscape Architect License',
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Pilot License',
                                      child: Text('Pilot License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Maritime License',
                                      child: Text('Maritime License'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Truck Driver License',
                                      child: Text('Truck Driver License'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() => _selectedType = val);
                                  },
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ✅ Dashed upload box (responsive height)
                          _DashedUploadBox(
                            height: (h * 0.26).clamp(180, 240),
                            onTap: _uploadFile,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'License Verification Rules',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'AbrilFatface',
                              fontWeight: FontWeight.w200,
                              fontSize: (w * 0.036).clamp(13, 15),
                            ),
                          ),
                          const SizedBox(height: 10),

                          _RuleRow('License must belong to you'),
                          _RuleRow(
                            'Name must match your National ID / Passport',
                          ),
                          _RuleRow('License must be valid and unexpired'),
                          _RuleRow('Document must be clear and readable'),
                          _RuleRow('No edited or altered documents'),

                          const SizedBox(height: 18),

                          // Continue button
                          GestureDetector(
                            onTap: _onContinue,
                            child: Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                color: _brandYellow,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Continue →',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w900,
                                    fontSize: (w * 0.040).clamp(14, 16),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),
                        ],
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

// -------------------- Widgets --------------------

class _GlassPill extends StatelessWidget {
  final Widget child;
  final double height;
  final EdgeInsets padding;

  const _GlassPill({
    required this.child,
    this.height = 36,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          height: height, // ✅ fixed thin height
          padding: padding,
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

class _DashedUploadBox extends StatelessWidget {
  final double height;
  final VoidCallback onTap;

  const _DashedUploadBox({required this.height, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: Colors.white.withOpacity(0.9),
          strokeWidth: 2,
          radius: 24,
          dashWidth: 10,
          dashSpace: 8,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 56),
                const SizedBox(height: 10),
                Text(
                  'Upload File',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'AbrilFatface',
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Supported files: PDF/PNG/JPEG/JPG',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Max Size: 5MB',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String text;
  const _RuleRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white.withOpacity(0.9),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// dashed border painter (real dashed like your design)
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
