// ignore_for_file: depend_on_referenced_packages

import 'dart:ui';
import 'package:flutter/material.dart';

/// ✅ WALLET UI exactly like your design:
/// - Balance card (UGX/DOLLARS)
/// - Deposit/Withdraw round buttons (active state orange)
/// - Yellow escrow pills
/// - Status tabs (Pending / Completed / Cancelled)
/// - Transaction cards (different arrow color + amount color)
/// - Transaction Details screen (same file, same flow) with 2 buttons
///
/// NOTE:
/// - Uses your background: assets/background/normalscreenbg.png
/// - Uses your profile image: assets/images/person.png (change path if yours differs)

class WalletFlowScreen extends StatefulWidget {
  const WalletFlowScreen({super.key});

  @override
  State<WalletFlowScreen> createState() => _WalletFlowScreenState();
}

class _WalletFlowScreenState extends State<WalletFlowScreen> {
  static const _brandOrange = Color(0xFFFFA10D);

  int _statusTab = 0; // 0 pending, 1 completed, 2 cancelled
  _ActionMode _actionMode = _ActionMode.none;

  bool _showDetails = false;
  _TxItem? _selected;

  final List<_TxItem> _all = [
    _TxItem(
      type: _TxType.deposit,
      status: _TxStatus.pending,
      title: "Deposit",
      date: "Jan, 19, 2026 | 10:45 am",
      amount: "UGX XXXX",
      txDate: "Date",
      txTime: "Time",
      txId: "ID",
      transferType: "Deposit/Withdraw",
      from: "Employer Wallet",
      to: "Worker Names / Escrow",
    ),
    _TxItem(
      type: _TxType.withdraw,
      status: _TxStatus.completed,
      title: "Withdraw",
      date: "Jan, 20, 2026 | 10:45 am",
      amount: "UGX XXXX",
      txDate: "Date",
      txTime: "Time",
      txId: "ID",
      transferType: "Deposit/Withdraw",
      from: "Employer Wallet",
      to: "Worker Names / Escrow",
    ),
    _TxItem(
      type: _TxType.deposit,
      status: _TxStatus.completed,
      title: "Deposit",
      date: "Jan, 30, 2026 | 10:45 am",
      amount: "UGX XXXX",
      txDate: "Date",
      txTime: "Time",
      txId: "ID",
      transferType: "Deposit/Withdraw",
      from: "Employer Wallet",
      to: "Worker Names / Escrow",
    ),
    _TxItem(
      type: _TxType.withdraw,
      status: _TxStatus.cancelled,
      title: "Withdraw",
      date: "Feb, 08, 2026 | 10:45 am",
      amount: "UGX XXXX",
      txDate: "Date",
      txTime: "Time",
      txId: "ID",
      transferType: "Deposit/Withdraw",
      from: "Employer Wallet",
      to: "Worker Names / Escrow",
    ),
    _TxItem(
      type: _TxType.deposit,
      status: _TxStatus.pending,
      title: "Deposit",
      date: "Feb, 09, 2026 | 10:45 am",
      amount: "UGX XXXX",
      txDate: "Date",
      txTime: "Time",
      txId: "ID",
      transferType: "Deposit/Withdraw",
      from: "Employer Wallet",
      to: "Worker Names / Escrow",
    ),
  ];

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

  List<_TxItem> get _filtered {
    if (_statusTab == 0) {
      return _all.where((e) => e.status == _TxStatus.pending).toList();
    }
    if (_statusTab == 1) {
      return _all.where((e) => e.status == _TxStatus.completed).toList();
    }
    return _all.where((e) => e.status == _TxStatus.cancelled).toList();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
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
                    final slide = Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
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
                          onContact: () => _toast('Contact Support (hook later)'),
                          onDownload: () => _toast('Download Receipt (hook later)'),
                        )
                      : _WalletMain(
                          key: const ValueKey('main'),
                          w: w,
                          h: h,
                          brandOrange: _brandOrange,
                          statusTab: _statusTab,
                          onStatusChange: (i) => setState(() => _statusTab = i),
                          actionMode: _actionMode,
                          onActionChange: (m) => setState(() => _actionMode = m),
                          items: _filtered,
                          onOpen: _openDetails,
                        ),
                ),

                SizedBox(height: h * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== MAIN WALLET =====================

class _WalletMain extends StatelessWidget {
  final double w;
  final double h;
  final Color brandOrange;

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

        SizedBox(height: h * 0.014),

        _EscrowRow(w: w, h: h, brandOrange: brandOrange),

        SizedBox(height: h * 0.012),

        _StatusTabs(
          w: w,
          h: h,
          statusTab: statusTab,
          onChange: onStatusChange,
          brandOrange: brandOrange,
        ),

        SizedBox(height: h * 0.014),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(height: h * 0.012),
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
    final cardH = h * 0.185;

    return Container(
      height: cardH,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.018),
      child: Column(
        children: [
          Text(
            'Balance',
            style: TextStyle(
              color: Colors.black.withOpacity(0.85),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: w * 0.040,
            ),
          ),
          SizedBox(height: h * 0.006),
          Text(
            'UGX/DOLLARS',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'AbrilFatface',
              fontSize: w * 0.060,
            ),
          ),
          SizedBox(height: h * 0.014),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundAction(
                w: w,
                label: 'Deposit',
                icon: Icons.arrow_upward_rounded, // in your design deposit shows up arrow inside
                active: actionMode == _ActionMode.deposit,
                brandOrange: brandOrange,
                onTap: () => onActionChange(
                  actionMode == _ActionMode.deposit ? _ActionMode.none : _ActionMode.deposit,
                ),
              ),
              SizedBox(width: w * 0.12),
              _RoundAction(
                w: w,
                label: 'Withdraw',
                icon: Icons.arrow_downward_rounded, // in your design withdraw shows down arrow inside
                active: actionMode == _ActionMode.withdraw,
                brandOrange: brandOrange,
                onTap: () => onActionChange(
                  actionMode == _ActionMode.withdraw ? _ActionMode.none : _ActionMode.withdraw,
                ),
              ),
            ],
          ),
        ],
      ),
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
            child: Icon(
              icon,
              color: active ? Colors.white : Colors.white,
              size: w * 0.06,
            ),
          ),
        ),
        SizedBox(height: w * 0.014),
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.65),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: w * 0.030,
          ),
        ),
      ],
    );
  }
}

class _EscrowRow extends StatelessWidget {
  final double w;
  final double h;
  final Color brandOrange;

  const _EscrowRow({
    required this.w,
    required this.h,
    required this.brandOrange,
  });

  @override
  Widget build(BuildContext context) {
    final pillH = h * 0.05;

    Widget pill(IconData icon, String text) {
      return Expanded(
        child: Container(
          height: pillH,
          decoration: BoxDecoration(
            color: brandOrange,
            borderRadius: BorderRadius.circular(999),
          ),
          padding: EdgeInsets.symmetric(horizontal: w * 0.035),
          child: Row(
            children: [
              Icon(icon, color: Colors.black, size: w * 0.045),
              SizedBox(width: w * 0.02),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: w * 0.030,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        pill(Icons.lock_rounded, 'Held in Escrow'),
        SizedBox(width: w * 0.03),
        pill(Icons.account_balance_wallet_rounded, 'UGX/DOLLARS'),
      ],
    );
  }
}

class _StatusTabs extends StatelessWidget {
  final double w;
  final double h;
  final int statusTab;
  final ValueChanged<int> onChange;
  final Color brandOrange;

  const _StatusTabs({
    required this.w,
    required this.h,
    required this.statusTab,
    required this.onChange,
    required this.brandOrange,
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
                    fontFamily: 'Poppins',
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
        chip('Pending', statusTab == 0, Colors.black, 0),
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
    final isDeposit = item.type == _TxType.deposit;

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

    final arrowIcon = isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_downward_rounded;
    // ✅ Design shows orange down arrow for pending, green down arrow for completed, red down arrow for cancelled.
    // We'll just tint by status:
    final arrowColor = item.status == _TxStatus.completed
        ? Colors.green
        : item.status == _TxStatus.cancelled
            ? Colors.red
            : brandOrange;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.014),
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
              decoration: BoxDecoration(
                color: arrowBg,
                shape: BoxShape.circle,
              ),
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
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.034,
                    ),
                  ),
                  SizedBox(height: h * 0.002),
                  Text(
                    item.date,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.55),
                      fontFamily: 'Poppins',
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
                fontFamily: 'Poppins',
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
          padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.02),
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

        SizedBox(height: h * 0.018),

        SizedBox(
          width: double.infinity,
          height: h * 0.065,
          child: OutlinedButton(
            onPressed: onContact,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: brandOrange, width: 2),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(
              "Contact Support",
              style: TextStyle(
                color: brandOrange,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.036,
              ),
            ),
          ),
        ),

        SizedBox(height: h * 0.012),

        SizedBox(
          width: double.infinity,
          height: h * 0.065,
          child: ElevatedButton(
            onPressed: onDownload,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: brandOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(
              "Download Receipt",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
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
                fontFamily: 'Poppins',
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
              fontFamily: 'Poppins',
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

  const _HeaderRow({
    required this.title,
    required this.onBack,
  });

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
            child: Icon(Icons.chevron_left, color: Colors.black, size: w * 0.10),
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
              fontFamily: 'AbrilFatface',
              fontSize: w * 0.055,
            ),
          ),
        ),
        SizedBox(width: w * 0.03),

        // profile image
        Container(
          width: w * 0.10,
          height: w * 0.10,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black12),
          child: ClipOval(
            child: Image.asset(
              'assets/images/person.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.person, size: w * 0.055),
            ),
          ),
        ),
        SizedBox(width: w * 0.02),

        // bell
        Container(
          width: w * 0.10,
          height: w * 0.10,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          child: Icon(Icons.notifications_none_rounded, color: Colors.black, size: w * 0.06),
        ),
      ],
    );
  }
}

// ===================== DASHED LINE PAINTER =====================

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
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}

// ===================== MODELS =====================

enum _ActionMode { none, deposit, withdraw }

enum _TxType { deposit, withdraw }

enum _TxStatus { pending, completed, cancelled }

class _TxItem {
  final _TxType type;
  final _TxStatus status;

  // list card
  final String title;
  final String date;
  final String amount;

  // details
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
}
