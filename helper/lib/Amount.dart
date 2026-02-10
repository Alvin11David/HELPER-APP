import 'package:cloud_firestore/cloud_firestore.dart';

class AmountService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> applyPaymentSuccess({
    required DocumentReference paymentRef,
    required String userId,
  }) async {
    try {
      await _db.runTransaction((transaction) async {
        final paymentSnap = await transaction.get(paymentRef);
        final paymentData = paymentSnap.data() as Map<String, dynamic>?;
        if (paymentData == null) return;
        if (paymentData['status'] != 'SUCCESS') return;
        if (paymentData['balanceUpdated'] == true) return;

        final amount = paymentData['amount'] as num?;
        if (amount == null) return;

        final userRef = _db.collection('Sign Up').doc(userId);
        transaction.update(userRef, {
          'amount': FieldValue.increment(amount.toInt()),
        });
        transaction.update(paymentRef, {'balanceUpdated': true});
      });
    } catch (_) {
      // Avoid surfacing transient errors in UI.
    }
  }

  static Future<void> setAmountIfMissing(
    String userId, {
    int initialAmount = 0,
  }) async {
    final userRef = _db.collection('Sign Up').doc(userId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data() as Map<String, dynamic>?;
      final hasAmount = data != null && data.containsKey('amount');
      if (hasAmount) return;
      transaction.update(userRef, {'amount': initialAmount});
    });
  }

  static Future<int> recalcBalance(String userId) async {
    final payments = await _db
        .collection('Payment Data')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'SUCCESS')
        .get();

    int depositsTotal = 0;
    for (final doc in payments.docs) {
      final data = doc.data();
      final amount = data['amount'] as num?;
      if (amount != null) {
        depositsTotal += amount.toInt();
      }
    }

    final withdrawals = await _db
        .collection('Withdrawals')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'SUCCESS')
        .get();

    int withdrawalsTotal = 0;
    for (final doc in withdrawals.docs) {
      final data = doc.data();
      final amount = data['amount'] as num?;
      if (amount != null) {
        withdrawalsTotal += amount.toInt();
      }
    }

    final newBalance = depositsTotal - withdrawalsTotal;
    await _db.collection('Sign Up').doc(userId).update({'amount': newBalance});
    return newBalance;
  }
}
