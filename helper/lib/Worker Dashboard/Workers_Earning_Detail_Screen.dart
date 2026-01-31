import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:helper/Components/Worker_Notifications.dart';

class WorkerEarningsScreen extends StatefulWidget {
  const WorkerEarningsScreen({super.key});

  @override
  State<WorkerEarningsScreen> createState() => _WorkerEarningsScreenState();
}

class _WorkerEarningsScreenState extends State<WorkerEarningsScreen> {
  static const _brandOrange = Color(0xFFFFA10D);

  int _tab = 0; // 0 today, 1 week, 2 month, 3 custom

  // Fake totals (replace later)
  final String _totalEarnings = "UGX/DOLLARS";
  final String _platformFee = "UGX/DOLLARS";

  // Fake summary (replace later)
  final _summaryRows = const [
    _KeyVal("Release Fee", "Amount"),
    _KeyVal("Pending (Escrow) Fee", "Amount"),
    _KeyVal("Processing", "Amount"),
  ];

  // Fake jobs list (replace later)
  final List<_EarningJobItem> _jobs = List.generate(
    4,
    (i) => _EarningJobItem(
      employerName: "Employer Name",
      jobCategory: "Job Category",
      grossAmount: "Gross Amount",
      commissionDeducted: "Commission Deducted",
      amountEarned: "Amount Earned",
      jobLocation: "Location",
      duration: "Duration",
      status: "Status",
      employerNotes: "Notes",
      jobDescription: "Description",
      grossEarnings: "Amount",
      platformCommission: "Amount",
      netEarnings: "Amount",
      referralRewards: "Amount",
    ),
  );

  void _setTab(int i) => setState(() => _tab = i);

  void _openJobDetails(_EarningJobItem job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _JobEarningsDetailsSheet(
        job: job,
        accent: _brandOrange,
        onDownload: () {
          Navigator.pop(context);
          _toast("Download Payslip (hook later)");
        },
      ),
    );
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePad),
            child: Column(
              children: [
                SizedBox(height: h * 0.02),

                // Top bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
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
                        "Earnings",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: w * 0.055,
                          fontFamily: 'Montserrat',
                          letterSpacing: 0.2,
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
                    const SizedBox(width: 10),
                    Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications,
                            color: Colors.black,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: WorkerNotificationsBadge(),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: h * 0.012),

                // helper pill
                Center(
                  child: _GlassPill(
                    radius: 18,
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.05,
                      vertical: h * 0.007,
                    ),
                    child: Text(
                      "View all today’s earnings here",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: w * 0.03,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.018),

                // Tabs row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TabChip(
                        text: "Today",
                        active: _tab == 0,
                        onTap: () => _setTab(0),
                      ),
                      SizedBox(width: w * 0.04),
                      _TabChip(
                        text: "This week",
                        active: _tab == 1,
                        onTap: () => _setTab(1),
                      ),
                      SizedBox(width: w * 0.04),
                      _TabChip(
                        text: "This Month",
                        active: _tab == 2,
                        onTap: () => _setTab(2),
                      ),
                      SizedBox(width: w * 0.04),
                      _TabChip(
                        text: "Custom",
                        active: _tab == 3,
                        onTap: () => _setTab(3),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: h * 0.014),

                // Scrollable body
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(bottom: h * 0.02),
                    children: [
                      // Total earnings bar
                      _MetricBar(
                        w: w,
                        bg: _brandOrange,
                        leftIcon: Icons.account_balance_wallet_outlined,
                        leftText: "Total Earnings:",
                        rightText: _totalEarnings,
                        rightBold: true,
                      ),
                      SizedBox(height: h * 0.01),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Based on completed Jobs",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: w * 0.028,
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.012),

                      // Platform fee bar
                      _MetricBar(
                        w: w,
                        bg: const Color(0xFF17F31B),
                        leftIcon: Icons.lock_outline_rounded,
                        leftText: "Platform Fee:",
                        rightText: _platformFee,
                        rightBold: true,
                      ),
                      SizedBox(height: h * 0.01),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Platform fee is 5% of every job",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: w * 0.028,
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.018),

                      // Earnings Summary header
                      Text(
                        "Earnings Summary",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w900,
                          fontSize: w * 0.04,
                        ),
                      ),
                      SizedBox(height: h * 0.012),

                      // Transaction Details white card
                      _WhiteCard(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.05,
                            vertical: h * 0.018,
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Transaction Details",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'AbrilFatface',
                                  fontSize: w * 0.05,
                                ),
                              ),
                              SizedBox(height: h * 0.01),
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: Colors.black.withOpacity(0.18),
                              ),
                              SizedBox(height: h * 0.012),
                              ..._summaryRows.map(
                                (r) => Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: h * 0.006,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          r.k,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w900,
                                            fontSize: w * 0.032,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        r.v,
                                        style: TextStyle(
                                          color: Colors.black.withOpacity(0.75),
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w900,
                                          fontSize: w * 0.032,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.018),

                      // Earnings by Job header
                      Text(
                        "Earnings By Job",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w900,
                          fontSize: w * 0.04,
                        ),
                      ),
                      SizedBox(height: h * 0.012),

                      // Jobs list cards
                      ..._jobs.map(
                        (job) => Padding(
                          padding: EdgeInsets.only(bottom: h * 0.012),
                          child: _EarningJobCard(
                            job: job,
                            onMore: () => _openJobDetails(job),
                          ),
                        ),
                      ),
                    ],
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

// ------------------------------ Data ------------------------------

class _KeyVal {
  final String k;
  final String v;
  const _KeyVal(this.k, this.v);
}

class _EarningJobItem {
  final String employerName;
  final String jobCategory;
  final String grossAmount;
  final String commissionDeducted;
  final String amountEarned;

  // details
  final String employerNotes;
  final String jobDescription;
  final String jobLocation;
  final String duration;
  final String status;

  final String grossEarnings;
  final String platformCommission;
  final String netEarnings;
  final String referralRewards;

  _EarningJobItem({
    required this.employerName,
    required this.jobCategory,
    required this.grossAmount,
    required this.commissionDeducted,
    required this.amountEarned,
    required this.employerNotes,
    required this.jobDescription,
    required this.jobLocation,
    required this.duration,
    required this.status,
    required this.grossEarnings,
    required this.platformCommission,
    required this.netEarnings,
    required this.referralRewards,
  });
}

// ------------------------------ UI pieces ------------------------------

class _MetricBar extends StatelessWidget {
  final double w;
  final Color bg;
  final IconData leftIcon;
  final String leftText;
  final String rightText;
  final bool rightBold;

  const _MetricBar({
    required this.w,
    required this.bg,
    required this.leftIcon,
    required this.leftText,
    required this.rightText,
    this.rightBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.022),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(leftIcon, color: Colors.black, size: w * 0.055),
          SizedBox(width: w * 0.02),
          Expanded(
            child: Text(
              leftText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.032,
              ),
            ),
          ),
          SizedBox(width: w * 0.02),
          Text(
            rightText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Inter',
              fontWeight: rightBold ? FontWeight.w900 : FontWeight.w800,
              fontSize: w * 0.032,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningJobCard extends StatelessWidget {
  final _EarningJobItem job;
  final VoidCallback onMore;

  const _EarningJobCard({required this.job, required this.onMore});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return _WhiteCard(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.employerName,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.036,
                    ),
                  ),
                  SizedBox(height: w * 0.01),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.jobCategory,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.75),
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: w * 0.028,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          job.commissionDeducted,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.75),
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: w * 0.028,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: w * 0.004),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.grossAmount,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.75),
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.028,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          job.amountEarned,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.75),
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.028,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.02),
            GestureDetector(
              onTap: onMore,
              child: Icon(
                Icons.more_vert,
                color: Colors.black.withOpacity(0.85),
                size: w * 0.06,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w * 0.26,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? _WorkerEarningsScreenState._brandOrange
              : Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? Colors.black : Colors.black.withOpacity(0.8),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ------------------------------ Bottom sheet (Job Details) ------------------------------

class _JobEarningsDetailsSheet extends StatelessWidget {
  final _EarningJobItem job;
  final Color accent;
  final VoidCallback onDownload;

  const _JobEarningsDetailsSheet({
    required this.job,
    required this.accent,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.02, w * 0.06, h * 0.03),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              SizedBox(height: h * 0.014),
              Text(
                "Job Details",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'AbrilFatface',
                  fontSize: w * 0.055,
                ),
              ),
              SizedBox(height: h * 0.012),

              _detailRow(w, "Employer Name:", job.employerName),
              _detailRow(w, "Employer Special Notes:", job.employerNotes),
              _detailRow(w, "Job Description:", job.jobDescription),
              _detailRow(
                w,
                "Job Location:",
                job.jobLocation,
                valueColor: accent,
              ),
              _detailRow(w, "Job Category", job.jobCategory),
              _detailRow(w, "Job Duration:", job.duration),
              _detailRow(w, "Job Status", job.status),

              SizedBox(height: h * 0.01),
              Divider(color: Colors.black.withOpacity(0.15)),

              _detailRow(w, "Gross Earnings", job.grossEarnings),
              _detailRow(w, "Platform Commission (5%)", job.platformCommission),
              _detailRow(w, "Net Earnings", job.netEarnings),
              _detailRow(w, "Referral Rewards", job.referralRewards),

              SizedBox(height: h * 0.02),

              SizedBox(
                width: double.infinity,
                height: h * 0.065,
                child: ElevatedButton(
                  onPressed: onDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    "Download Payslip",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w900,
                      fontSize: w * 0.04,
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

  Widget _detailRow(double w, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.032,
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor ?? Colors.black.withOpacity(0.75),
                fontFamily: 'Inter',
                fontWeight: FontWeight.w900,
                fontSize: w * 0.032,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------ Top UI helpers ------------------------------

class _TopAvatar extends StatelessWidget {
  const _TopAvatar();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      width: w * 0.10,
      height: w * 0.10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white.withOpacity(0.35)),
        image: const DecorationImage(
          image: AssetImage('assets/images/person.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w * 0.10,
        height: w * 0.10,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: w * 0.06),
        ),
      ),
    );
  }
}

// ------------------------------ Glass pill ------------------------------

class _GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const _GlassPill({
    required this.child,
    required this.padding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.22),
                Colors.white.withOpacity(0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
