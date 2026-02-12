// ignore_for_file: depend_on_referenced_packages

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class FinishedJobCodeScreen extends StatefulWidget {
  final String bookingId;

  const FinishedJobCodeScreen({super.key, required this.bookingId});

  @override
  State<FinishedJobCodeScreen> createState() => _FinishedJobCodeScreenState();
}

class _FinishedJobCodeScreenState extends State<FinishedJobCodeScreen> {
  static const _brandOrange = Color(0xFFFFA10D);
  late TextEditingController _codeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please enter the 6-digit code',
            style: TextStyle(fontFamily: 'Inter'),
          ),
          backgroundColor: Colors.black.withOpacity(0.85),
        ),
      );
      return;
    }

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Code must be exactly 6 digits',
            style: TextStyle(fontFamily: 'Inter'),
          ),
          backgroundColor: Colors.black.withOpacity(0.85),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'verifyJobCompletionCode',
      );
      await callable.call({'bookingId': widget.bookingId, 'code': code});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Job completed successfully! Amount released to worker.',
            style: TextStyle(fontFamily: 'Inter'),
          ),
          backgroundColor: Colors.green.withOpacity(0.85),
        ),
      );

      // Navigate back to previous screen after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: const TextStyle(fontFamily: 'Inter'),
          ),
          backgroundColor: Colors.red.withOpacity(0.85),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Enter Completion Code',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header text
              Text(
                'Job Completion Code',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  fontSize: w * 0.055,
                ),
              ),
              SizedBox(height: h * 0.02),
              Text(
                'Enter the 6-digit code the worker provided to complete the job and release the payment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: w * 0.035,
                  height: 1.5,
                ),
              ),
              SizedBox(height: h * 0.045),

              // Code input field
              TextField(
                controller: _codeController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                enabled: !_isLoading,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: w * 0.06,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: w * 0.06,
                    fontFamily: 'Inter',
                    letterSpacing: 8,
                  ),
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: h * 0.02),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: _brandOrange.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: _brandOrange, width: 2.5),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
              ),
              SizedBox(height: h * 0.06),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: h * 0.075,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandOrange,
                    disabledBackgroundColor: _brandOrange.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: h * 0.04,
                          width: h * 0.04,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Verify & Complete',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: w * 0.045,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Inter',
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
