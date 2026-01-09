import 'package:flutter/material.dart';

class AcademicCertificateUploadScreen extends StatelessWidget {
	const AcademicCertificateUploadScreen({Key? key}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: Stack(
				fit: StackFit.expand,
				children: [
					Image.asset(
						'assets/background/normalscreenbg.png',
						fit: BoxFit.cover,
					),
					// Add your screen content here, above the background
				],
			),
		);
	}
}
