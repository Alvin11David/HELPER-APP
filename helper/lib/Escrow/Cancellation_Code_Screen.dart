import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class CancellationCodeScreen extends StatefulWidget {
  final String? bookingId;

  const CancellationCodeScreen({super.key, this.bookingId});

  @override
  State<CancellationCodeScreen> createState() => _CancellationCodeScreenState();
}

class _CancellationCodeScreenState extends State<CancellationCodeScreen> {
  final _bookingIdController = TextEditingController();
  final _codeController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
      _bookingIdController.text = widget.bookingId!;
    }
  }

  @override
  void dispose() {
    _bookingIdController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bookingId = _bookingIdController.text.trim();
    final code = _codeController.text.trim();

    if (bookingId.isEmpty || code.length != 6) {
      _toast('Enter a valid booking ID and 6-digit code');
      return;
    }

    setState(() => _submitting = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'verifyEscrowCancellationCode',
      );
      await callable.call({'bookingId': bookingId, 'code': code});
      if (!mounted) return;
      _toast('Cancellation verified successfully');
      Navigator.pop(context);
    } catch (e) {
      _toast('Verification failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: Colors.black.withOpacity(0.85),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Cancellation Code'),
        backgroundColor: const Color(0xFFFFA10D),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(w * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the 6-digit code you received to release escrow.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: w * 0.06),
            TextField(
              controller: _bookingIdController,
              enabled: widget.bookingId == null || widget.bookingId!.isEmpty,
              decoration: const InputDecoration(
                labelText: 'Booking ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: w * 0.05),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '6-digit code',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            SizedBox(height: w * 0.08),
            SizedBox(
              width: double.infinity,
              height: w * 0.12,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA10D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Verify Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
