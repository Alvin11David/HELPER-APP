import 'dart:io';

import 'package:flutter/material.dart';
import 'package:helper/Chats/overlays/incoming_call_overlay_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:helper/Document Upload/Profile/Support_Screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'Wallet_TopUp_Screen.dart';
import 'Wallet_Withdraw_Screen.dart';

class WalletFlowScreen extends StatefulWidget {
  const WalletFlowScreen({super.key});

  @override
  State<WalletFlowScreen> createState() => _WalletFlowScreenState();
}

class _WalletFlowScreenState extends State<WalletFlowScreen> {
  static const _brandOrange = Color(0xFFFFA10D);

  // ✅ lighter orange/yellow for pending active
  static const _pendingActive = Color(0xFFFFC233);

  int _statusTab = 0; // 0 pending, 1 completed, 2 cancelled
  _ActionMode _actionMode = _ActionMode.none;

  bool _showDetails = false;
  _TxItem? _selected;

  StreamSubscription<QuerySnapshot>? _paymentListener;

  @override
  void initState() {
    super.initState();
    _setupPaymentListener();
    _checkExistingSuccessPayments();
  }

  @override
  void dispose() {
    _paymentListener?.cancel();
    super.dispose();
  }

  void _setupPaymentListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _paymentListener = FirebaseFirestore.instance
          .collection('Payment Data')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((querySnapshot) {
            for (var change in querySnapshot.docChanges) {
              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                final data = change.doc.data() as Map<String, dynamic>?;
                if (data != null &&
                    data['status'] == 'SUCCESS' &&
                    !data.containsKey('balanceUpdated')) {
                  final amount = data['amount'] as int?;
                  if (amount != null) {
                    FirebaseFirestore.instance
                        .collection('Sign Up')
                        .doc(user.uid)
                        .update({'amount': FieldValue.increment(amount)});
                    // Mark as updated
                    change.doc.reference.update({'balanceUpdated': true});
                  }
                }
              }
            }
          });
    }
  }

  Future<void> _checkExistingSuccessPayments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('Payment Data')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'SUCCESS')
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('balanceUpdated')) {
          final amount = data['amount'] as int?;
          if (amount != null) {
            await FirebaseFirestore.instance
                .collection('Sign Up')
                .doc(user.uid)
                .update({'amount': FieldValue.increment(amount)});
            await doc.reference.update({'balanceUpdated': true});
          }
        }
      }
    }
  }

  void _back() {
    if (_showDetails) {
      setState(() {
        _showDetails = false;
        _selected = null;
      });
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _openDetails(_TxItem item) {
    setState(() {
      _selected = item;
      _showDetails = true;
    });
  }

  Future<Directory?> _getReceiptDirectory() async {
    if (Platform.isAndroid) {
      final baseDir = await getExternalStorageDirectory();
      if (baseDir == null) return null;
      final receiptsDir = Directory('${baseDir.path}/receipts');
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }
      return receiptsDir;
    }

    final baseDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${baseDir.path}/receipts');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    return receiptsDir;
  }

  Future<void> _downloadReceipt(_TxItem? item) async {
    if (item == null) {
      _toast('No transaction selected');
      return;
    }

    try {
      final receiptsDir = await _getReceiptDirectory();
      if (receiptsDir == null) {
        _toast('Unable to access storage');
        return;
      }

      final fileName = item.txId.isNotEmpty
          ? item.txId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
          : DateTime.now().millisecondsSinceEpoch.toString();
      final file = File('${receiptsDir.path}/receipt_$fileName.pdf');

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Transaction Receipt',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generated: ${DateFormat('MMM dd, yyyy | hh:mm a').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 10),
                _receiptRow('Transaction Date', item.txDate),
                _receiptRow('Transaction Time', item.txTime),
                _receiptRow('Transaction ID', item.txId),
                _receiptRow('Transfer Type', item.transferType),
                _receiptRow('Amount', item.amount),
                _receiptRow('From', item.from),
                _receiptRow('To', item.to),
                _receiptRow('Status', _statusText(item.status)),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Thank you for using Helper.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            );
          },
        ),
      );

      await file.writeAsBytes(await doc.save(), flush: true);
      _toast('Receipt saved to ${file.path}');
    } catch (e) {
      _toast('Failed to download receipt');
    }
  }

  pw.Widget _receiptRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(_TxStatus s) {
    if (s == _TxStatus.pending) return 'Pending';
    if (s == _TxStatus.completed) return 'Completed';
    return 'Cancelled';
  }

  Future<List<_TxItem>> _fetchPayments(String statusFilter) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    Query query = FirebaseFirestore.instance
        .collection('Payment Data')
        .where('userId', isEqualTo: user.uid);
    if (statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => _TxItem.fromPaymentDoc(doc)).toList();
  }

  Future<List<_TxItem>> _fetchWithdrawals(String statusFilter) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    Query query = FirebaseFirestore.instance
        .collection('Withdrawals')
        .where('userId', isEqualTo: user.uid);
    if (statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => _TxItem.fromWithdrawalDoc(doc)).toList();
  }

  Future<List<_TxItem>> get _filtered async {
    if (_statusTab == 0) {
      final payments = await _fetchPayments('PENDING_USER_CONFIRMATION');
      final withdrawals = await _fetchWithdrawals('PROCESSING');
      return [...payments, ...withdrawals];
    }
    if (_statusTab == 1) {
      final payments = await _fetchPayments('SUCCESS');
      final withdrawals = await _fetchWithdrawals('SUCCESS');
      return [...payments, ...withdrawals];
    }
    return [];
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
    final h = MediaQuery.of(context).size.height;

    final sidePad = w * 0.06;
    final topPad = h * 0.03;

    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/normalscreenbg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: sidePad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: topPad),

                _HeaderRow(
                  title: _showDetails ? 'Trans Details' : 'Your Wallet',
                  onBack: _back,
                ),

                SizedBox(height: h * 0.018),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) {
                    final slide =
                        Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOut),
                        );
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _showDetails
                      ? _TransactionDetails(
                          key: const ValueKey('details'),
                          w: w,
                          h: h,
                          brandOrange: _brandOrange,
                          item: _selected,
                          onContact: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SupportScreen(),
                              ),
                            );
                          },
                          onDownload: () => _downloadReceipt(_selected),
                        )
                      : FutureBuilder<List<_TxItem>>(
                          future: _filtered,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }
                            final items = snapshot.data ?? [];
                            return _WalletMain(
                              key: const ValueKey('main'),
                              w: w,
                              h: h,
                              brandOrange: _brandOrange,
                              pendingActive: _pendingActive,
                              statusTab: _statusTab,
                              onStatusChange: (i) =>
                                  setState(() => _statusTab = i),
                              actionMode: _actionMode,
                              onActionChange: (m) {
                                if (m == _ActionMode.deposit) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WalletTopUpScreen(),
                                    ),
                                  );
                                } else if (m == _ActionMode.withdraw) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WalletWithdrawScreen(),
                                    ),
                                  );
                                } else {
                                  setState(() => _actionMode = m);
                                }
                              },
                              items: items,
                              onOpen: _openDetails,
                            );
                          },
                        ),
                ),

                SizedBox(height: h * 0.07),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== MODELS =====================

enum _TxType { deposit, withdraw }

enum _TxStatus { pending, completed, cancelled }

class _TxItem {
  final _TxType type;
  final _TxStatus status;

  final String title;
  final String date;
  final String amount;

  final String txDate;
  final String txTime;
  final String txId;
  final String transferType;
  final String from;
  final String to;

  const _TxItem({
    required this.type,
    required this.status,
    required this.title,
    required this.date,
    required this.amount,
    required this.txDate,
    required this.txTime,
    required this.txId,
    required this.transferType,
    required this.from,
    required this.to,
  });

  static String _formatAmount(num amount) {
    return 'UGX ${NumberFormat('#,###').format(amount)}';
  }

  factory _TxItem.fromPaymentDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final statusStr = data['status'] as String? ?? '';
    _TxStatus status;
    if (statusStr == 'PENDING_USER_CONFIRMATION') {
      status = _TxStatus.pending;
    } else if (statusStr == 'SUCCESS') {
      status = _TxStatus.completed;
    } else {
      status = _TxStatus.cancelled;
    }
    final amount = (data['amount'] as num?) ?? 0;
    final reference = data['reference'] as String? ?? '';
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final dateFormat = DateFormat('MMM, dd, yyyy | hh:mm a');
    final date = dateFormat.format(createdAt);
    final txDateFormat = DateFormat('MMM dd, yyyy');
    final txDate = txDateFormat.format(createdAt);
    final txTimeFormat = DateFormat('hh:mm a');
    final txTime = txTimeFormat.format(createdAt);
    return _TxItem(
      type: _TxType.deposit,
      status: status,
      title: 'Deposit',
      date: date,
      amount: _formatAmount(amount),
      txDate: txDate,
      txTime: txTime,
      txId: reference,
      transferType: 'Deposit',
      from: 'Mobile Money',
      to: 'Worker Wallet',
    );
  }

  factory _TxItem.fromWithdrawalDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final statusStr = data['status'] as String? ?? '';
    _TxStatus status;
    if (statusStr == 'PROCESSING') {
      status = _TxStatus.pending;
    } else if (statusStr == 'SUCCESS') {
      status = _TxStatus.completed;
    } else {
      status = _TxStatus.cancelled;
    }
    final amount = (data['amount'] as num?) ?? 0;
    final reference = data['reference'] as String? ?? '';
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final dateFormat = DateFormat('MMM, dd, yyyy | hh:mm a');
    final date = dateFormat.format(createdAt);
    final txDateFormat = DateFormat('MMM dd, yyyy');
    final txDate = txDateFormat.format(createdAt);
    final txTimeFormat = DateFormat('hh:mm a');
    final txTime = txTimeFormat.format(createdAt);
    return _TxItem(
      type: _TxType.withdraw,
      status: status,
      title: 'Withdraw',
      date: date,
      amount: _formatAmount(amount),
      txDate: txDate,
      txTime: txTime,
      txId: reference,
      transferType: 'Withdrawal',
      from: 'Worker Wallet',
      to: 'Mobile Money',
    );
  }
}

void showIncomingCall(BuildContext context) {
  IncomingCallOverlayService.instance.show(
    context: context,
    businessName: 'Business Name',
    subtitle: 'Incoming voice call',
    timeText: '9:45AM',
    avatarImage: const AssetImage(
      'assets/images/person.png',
    ), // or NetworkImage(...)
    onDecline: () {
      // TODO: send "declined" to backend
      debugPrint('Declined');
    },
    onAnswer: () {
      // TODO: navigate to call screen
      debugPrint('Answered');
    },
  );
}

// ===================== MAIN WALLET =====================

class _WalletMain extends StatelessWidget {
  final double w;
  final double h;
  final Color brandOrange;
  final Color pendingActive;

  final int statusTab;
  final ValueChanged<int> onStatusChange;

  final _ActionMode actionMode;
  final ValueChanged<_ActionMode> onActionChange;

  final List<_TxItem> items;
  final ValueChanged<_TxItem> onOpen;

  const _WalletMain({
    super.key,
    required this.w,
    required this.h,
    required this.brandOrange,
    required this.pendingActive,
    required this.statusTab,
    required this.onStatusChange,
    required this.actionMode,
    required this.onActionChange,
    required this.items,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BalanceCard(
          w: w,
          h: h,
          brandOrange: brandOrange,
          actionMode: actionMode,
          onActionChange: onActionChange,
        ),

        SizedBox(height: h * 0.02),

        // ✅ ONE combined escrow tab like your image
        _EscrowSingleTab(w: w, h: h, brandOrange: brandOrange),

        SizedBox(height: h * 0.016),

        _StatusTabs(
          w: w,
          h: h,
          statusTab: statusTab,
          onChange: onStatusChange,
          brandOrange: brandOrange,
          pendingActive: pendingActive,
        ),

        SizedBox(height: h * 0.04),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(height: h * 0.02),
          itemBuilder: (context, i) {
            final item = items[i];
            return _TxCard(
              w: w,
              h: h,
              brandOrange: brandOrange,
              item: item,
              onTap: () => onOpen(item),
            );
          },
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double w;
  final double h;
  final Color brandOrange;
  final _ActionMode actionMode;
  final ValueChanged<_ActionMode> onActionChange;

  const _BalanceCard({
    required this.w,
    required this.h,
    required this.brandOrange,
    required this.actionMode,
    required this.onActionChange,
  });

  @override
  Widget build(BuildContext context) {
    final cardH = h * 0.20;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseAuth.instance.currentUser != null
          ? FirebaseFirestore.instance
                .collection('Sign Up')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots()
          : null,
      builder: (context, snapshot) {
        int balance = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          balance = data?['amount'] ?? 0;
        }

        return Container(
          height: cardH,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.06,
            vertical: h * 0.018,
          ),
          child: Column(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Balance: UGX ',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.85),
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        fontSize: w * 0.040,
                      ),
                    ),
                    TextSpan(
                      text: NumberFormat('#,###').format(balance),
                      style: TextStyle(
                        color: brandOrange,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        fontSize: w * 0.040,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: h * 0.006),
              SizedBox(height: h * 0.014),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundAction(
                    w: w,
                    label: 'Deposit',
                    icon: Icons.arrow_upward_rounded,
                    active: actionMode == _ActionMode.deposit,
                    brandOrange: brandOrange,
                    onTap: () => onActionChange(
                      actionMode == _ActionMode.deposit
                          ? _ActionMode.none
                          : _ActionMode.deposit,
                    ),
                  ),
                  SizedBox(width: w * 0.12),
                  _RoundAction(
                    w: w,
                    label: 'Withdraw',
                    icon: Icons.arrow_downward_rounded,
                    active: actionMode == _ActionMode.withdraw,
                    brandOrange: brandOrange,
                    onTap: () => onActionChange(
                      actionMode == _ActionMode.withdraw
                          ? _ActionMode.none
                          : _ActionMode.withdraw,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoundAction extends StatelessWidget {
  final double w;
  final String label;
  final IconData icon;
  final bool active;
  final Color brandOrange;
  final VoidCallback onTap;

  const _RoundAction({
    required this.w,
    required this.label,
    required this.icon,
    required this.active,
    required this.brandOrange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: w * 0.11,
            height: w * 0.11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? brandOrange : Colors.black,
            ),
            child: Icon(icon, color: Colors.white, size: w * 0.06),
          ),
        ),
        SizedBox(height: w * 0.014),
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.65),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: w * 0.030,
          ),
        ),
      ],
    );
  }
}

/// ✅ One combined tab: "Held in Escrow:  UGX/DOLLARS"
class _EscrowSingleTab extends StatelessWidget {
  final double w;
  final double h;
  final Color brandOrange;

  const _EscrowSingleTab({
    required this.w,
    required this.h,
    required this.brandOrange,
  });

  @override
  Widget build(BuildContext context) {
    final pillH = h * 0.05;

    return Container(
      height: pillH,
      width: double.infinity,
      decoration: BoxDecoration(
        color: brandOrange,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: Colors.black, size: w * 0.045),
          SizedBox(width: w * 0.02),
          Expanded(
            child: Text(
              'Held in Escrow:',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.030,
              ),
            ),
          ),
          SizedBox(width: w * 0.02),
          Text(
            'UGX/DOLLARS',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w900,
              fontSize: w * 0.030,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  final double w;
  final double h;
  final int statusTab;
  final ValueChanged<int> onChange;
  final Color brandOrange;
  final Color pendingActive;

  const _StatusTabs({
    required this.w,
    required this.h,
    required this.statusTab,
    required this.onChange,
    required this.brandOrange,
    required this.pendingActive,
  });

  @override
  Widget build(BuildContext context) {
    final chipH = h * 0.045;

    Widget chip(String text, bool active, Color activeColor, int idx) {
      return Expanded(
        child: GestureDetector(
          onTap: () => onChange(idx),
          child: Container(
            height: chipH,
            decoration: BoxDecoration(
              color: active ? activeColor : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active ? activeColor : Colors.black.withOpacity(0.10),
              ),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: w * 0.030,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        // ✅ Pending active = lighter orange/yellow
        chip('Pending', statusTab == 0, pendingActive, 0),
        SizedBox(width: w * 0.03),
        chip('Completed', statusTab == 1, Colors.green, 1),
        SizedBox(width: w * 0.03),
        chip('Cancelled', statusTab == 2, Colors.red, 2),
      ],
    );
  }
}

class _TxCard extends StatelessWidget {
  final double w;
  final double h;
  final Color brandOrange;
  final _TxItem item;
  final VoidCallback onTap;

  const _TxCard({
    required this.w,
    required this.h,
    required this.brandOrange,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amountColor = item.status == _TxStatus.completed
        ? Colors.green
        : item.status == _TxStatus.cancelled
        ? Colors.red
        : brandOrange;

    final arrowBg = item.status == _TxStatus.completed
        ? Colors.green.withOpacity(0.14)
        : item.status == _TxStatus.cancelled
        ? Colors.red.withOpacity(0.14)
        : const Color(0xFFF1F1F1);

    // design shows a down arrow on the circle; tint by status
    final arrowColor = item.status == _TxStatus.completed
        ? Colors.green
        : item.status == _TxStatus.cancelled
        ? Colors.red
        : brandOrange;

    final arrowIcon = item.type == _TxType.withdraw
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: h * 0.014,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 14,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: w * 0.10,
              height: w * 0.10,
              decoration: BoxDecoration(color: arrowBg, shape: BoxShape.circle),
              child: Icon(arrowIcon, color: arrowColor, size: w * 0.06),
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.034,
                    ),
                  ),
                  SizedBox(height: h * 0.002),
                  Text(
                    item.date,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.55),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: w * 0.028,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.02),
            Text(
              item.amount,
              style: TextStyle(
                color: amountColor,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.032,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== DETAILS =====================

class _TransactionDetails extends StatelessWidget {
  final double w;
  final double h;
  final Color brandOrange;
  final _TxItem? item;
  final VoidCallback onContact;
  final VoidCallback onDownload;

  const _TransactionDetails({
    super.key,
    required this.w,
    required this.h,
    required this.brandOrange,
    required this.item,
    required this.onContact,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    if (item == null) return const SizedBox();

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.06,
            vertical: h * 0.02,
          ),
          child: Column(
            children: [
              Text(
                "Transaction Details",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'AbrilFatface',
                  fontSize: w * 0.050,
                ),
              ),
              SizedBox(height: h * 0.010),
              _dashedLine(color: Colors.black.withOpacity(0.35)),
              SizedBox(height: h * 0.012),
              _kv("Transaction Date", item!.txDate),
              _kv("Transaction Time", item!.txTime),
              _kv("Transaction ID", item!.txId),
              _kv("Transfer Type", item!.transferType),
              _kv("Amount Transferred", item!.amount),
              _kv("From", item!.from),
              _kv("To", item!.to),
              _kv("Status", _statusText(item!.status)),
              SizedBox(height: h * 0.012),
              _dashedLine(color: Colors.black.withOpacity(0.35)),
            ],
          ),
        ),
        SizedBox(height: h * 0.050),
        SizedBox(
          width: double.infinity,
          height: h * 0.065,
          child: OutlinedButton(
            onPressed: onContact,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: brandOrange, width: 2),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              "Contact Support",
              style: TextStyle(
                color: brandOrange,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.036,
              ),
            ),
          ),
        ),
        SizedBox(height: h * 0.04),
        SizedBox(
          width: double.infinity,
          height: h * 0.065,
          child: ElevatedButton(
            onPressed: onDownload,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: brandOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              "Download Receipt",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.036,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.008),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black.withOpacity(0.80),
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: w * 0.030,
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          Text(
            v,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black.withOpacity(0.75),
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: w * 0.030,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedLine({required Color color}) {
    return SizedBox(
      width: double.infinity,
      height: 2,
      child: CustomPaint(painter: _DashedLinePainter(color: color)),
    );
  }

  String _statusText(_TxStatus s) {
    if (s == _TxStatus.pending) return "Pending";
    if (s == _TxStatus.completed) return "Completed";
    return "Cancelled";
  }
}

// ===================== HEADER =====================

class _HeaderRow extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _HeaderRow({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: w * 0.13,
            height: w * 0.13,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.chevron_left,
              color: Colors.black,
              size: w * 0.10,
            ),
          ),
        ),
        SizedBox(width: w * 0.05),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
              fontSize: w * 0.055,
            ),
          ),
        ),
        SizedBox(width: w * 0.03),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.black),
        ),
      ],
    );
  }
}

// ===================== DASHED LINE =====================

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const dashWidth = 7.0;
    const dashSpace = 6.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ===================== MODELS =====================

enum _ActionMode { none, deposit, withdraw }
