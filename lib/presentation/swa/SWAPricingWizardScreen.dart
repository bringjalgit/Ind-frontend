import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'widgets/wizard_theme.dart';

/// S2 — SWA Wizard Step 1: Pricing.
///
/// "A · Refined Dark" design — adaptive to light + dark themes via
/// WizardTokens. The seller sets `expected_price` (target) and
/// `floor_price` (minimum). `listed_price` is read-only from the
/// listing. A visual range bar renders the 3 tiers so the seller sees
/// the negotiation window at a glance.
///
/// Route: /swa-wizard-pricing?listingId=X&listedPrice=Y&listingTitle=Z
class SWAPricingWizardScreen extends StatefulWidget {
  final String listingId;
  final int listedPrice;
  final String listingTitle;
  // ISO timestamps for the listing's plan window. Forwarded to the next
  // step so it can compute plan-total validity (expires - created) and
  // cap the day picker by that. Both nullable for entry points that
  // don't supply them.
  final String? expiresListDate;
  final String? createdAt;

  const SWAPricingWizardScreen({
    super.key,
    required this.listingId,
    required this.listedPrice,
    required this.listingTitle,
    this.expiresListDate,
    this.createdAt,
  });

  @override
  State<SWAPricingWizardScreen> createState() => _SWAPricingWizardScreenState();
}

class _SWAPricingWizardScreenState extends State<SWAPricingWizardScreen> {
  final _expectedController = TextEditingController();
  final _floorController = TextEditingController();
  String? _expectedError;
  String? _floorError;

  @override
  void initState() {
    super.initState();
    // Default to 90% / 70% of listed. Matches the "90% of listed"
    // badge shown on the target row in the mock.
    _expectedController.text = (widget.listedPrice * 0.9).round().toString();
    _floorController.text = (widget.listedPrice * 0.7).round().toString();
  }

  @override
  void dispose() {
    _expectedController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  int get _expectedPrice =>
      int.tryParse(_expectedController.text.replaceAll(',', '')) ?? 0;
  int get _floorPrice =>
      int.tryParse(_floorController.text.replaceAll(',', '')) ?? 0;

  bool _validate() {
    bool ok = true;
    setState(() {
      _expectedError = null;
      _floorError = null;
      if (_expectedPrice <= 0) {
        _expectedError = 'Enter a valid target price';
        ok = false;
      } else if (_expectedPrice > widget.listedPrice) {
        _expectedError =
            'Cannot exceed listed price (₹${_fmt(widget.listedPrice)})';
        ok = false;
      }
      if (_floorPrice <= 0) {
        _floorError = 'Enter a valid minimum price';
        ok = false;
      } else if (_floorPrice > _expectedPrice) {
        _floorError = 'Minimum cannot exceed target price';
        ok = false;
      }
    });
    return ok;
  }

  void _onNext() {
    if (!_validate()) return;
    context.push(
      '/swa-wizard-availability',
      extra: {
        'listingId': widget.listingId,
        'listingTitle': widget.listingTitle,
        'listedPrice': widget.listedPrice,
        'expectedPrice': _expectedPrice,
        'floorPrice': _floorPrice,
        'expiresListDate': widget.expiresListDate,
        'createdAt': widget.createdAt,
      },
    );
  }

  /// Indian grouping: 18000 → "18,000", 180000 → "1,80,000".
  String _fmt(int n) {
    if (n <= 0) return '0';
    final s = n.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final grouped = rest.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (m) => ',',
    );
    return '$grouped,$last3';
  }

  /// Percentage of listed, rounded to an integer — powers the
  /// "90% of listed" badge next to TARGET.
  int get _targetPct =>
      widget.listedPrice > 0 ? ((_expectedPrice / widget.listedPrice) * 100).round() : 0;

  @override
  Widget build(BuildContext context) {
    final t = WizardTokens.of(context);

    return Scaffold(
      backgroundColor: t.bg,
      appBar: _buildTopBar(t, 'Price Range'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WizardStepHeader(
                t: t,
                step: 1,
                totalSteps: 3,
                eyebrow: '01 · PRICING',
                title: "What's your\nwalk-away price?",
                subtitle: 'Smart Assist negotiates within this window.',
              ),
              const SizedBox(height: 24),
              _buildRangeCard(t),
              const SizedBox(height: 14),
              WizardTipChip(
                t: t,
                icon: Icons.lightbulb_outline_rounded,
                iconColor: t.accent,
                bg: t.accent.withOpacity(0.06),
                border: t.accent.withOpacity(0.18),
                body: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 11.5,
                      color: t.dim,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Offers at or above '),
                      TextSpan(
                        text: '₹${_fmt(_expectedPrice)}',
                        style: TextStyle(
                          color: t.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' auto-accept. Below your minimum? We never reply.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(t),
    );
  }

  /// Mock's editorial card containing: LISTED (locked) → TARGET →
  /// MINIMUM → range bar. Replaces the previous 3-section form.
  Widget _buildRangeCard(WizardTokens t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LISTED (read-only).
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LISTED',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: t.dim2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${_fmt(widget.listedPrice)}',
                      style: wizardMonoStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: t.dim,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 12, color: t.dim2),
                  const SizedBox(width: 4),
                  Text(
                    'locked',
                    style: TextStyle(fontSize: 11, color: t.dim2),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _dashedDivider(t),
          const SizedBox(height: 16),
          // TARGET — cyan dot + "ideal" tag + "% of listed" badge.
          _priceRow(
            t: t,
            label: 'TARGET',
            dotColor: t.accent,
            hint: 'ideal',
            trailing: Text(
              '$_targetPct% of listed',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: t.accent,
              ),
            ),
            controller: _expectedController,
            error: _expectedError,
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: t.line),
          const SizedBox(height: 18),
          // MINIMUM — lime dot + "hidden" tag + private eye icon.
          _priceRow(
            t: t,
            label: 'MINIMUM',
            dotColor: t.success,
            hint: 'hidden',
            trailing: Row(
              children: [
                Icon(Icons.visibility_outlined, size: 11, color: t.dim2),
                const SizedBox(width: 4),
                Text(
                  'private',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: t.dim2,
                  ),
                ),
              ],
            ),
            controller: _floorController,
            error: _floorError,
          ),
          const SizedBox(height: 22),
          _buildRangeBar(t),
        ],
      ),
    );
  }

  Widget _priceRow({
    required WizardTokens t,
    required String label,
    required Color dotColor,
    required String hint,
    required Widget trailing,
    required TextEditingController controller,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              hint,
              style: TextStyle(fontSize: 10, color: t.dim2),
            ),
            const Spacer(),
            trailing,
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹',
              style: wizardMonoStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: t.dim,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {
                  _expectedError = null;
                  _floorError = null;
                }),
                style: wizardMonoStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                  letterSpacing: -1.2,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error,
            style: TextStyle(fontSize: 11, color: t.danger),
          ),
        ],
      ],
    );
  }

  /// Horizontal range bar: grey baseline + filled segment from MIN→LISTED,
  /// three handles (lime = minimum, cyan = target, hollow = listed).
  ///
  /// 2026-05-17 fix — the bar's tick labels span 70%-100% of listed
  /// (see [_buildRangeTicks]: ticks at 0.7, 0.8, 0.9, 1.0 of base).
  /// The previous position math used `price / listed` which placed
  /// the lime handle at 70% of the bar width when the floor was at
  /// 70% of listed — visually wrong because the bar's left edge
  /// represents 70%, not 0%. Now we remap prices into the
  /// [0.7×listed, listed] window so the handles align with the
  /// tick labels exactly.
  Widget _buildRangeBar(WizardTokens t) {
    final listed = widget.listedPrice.toDouble();
    final expected = _expectedPrice.toDouble();
    final floor = _floorPrice.toDouble();

    const double barStart = 0.7; // bar left edge = 70% of listed
    const double barSpan = 1.0 - barStart; // 0.3
    double mapToBar(double price) {
      if (listed <= 0) return 0.0;
      final ratio = price / listed;
      return ((ratio - barStart) / barSpan).clamp(0.0, 1.0);
    }

    final minPos = mapToBar(floor);
    final targetPos = mapToBar(expected);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const handle = 16.0;
        return Column(
          children: [
            SizedBox(
              height: 34,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Base track
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: t.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Active gradient segment from MIN → LISTED
                  Positioned(
                    top: 14,
                    left: w * minPos,
                    width: (w * (1 - minPos)).clamp(0.0, w),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [t.success, t.accent],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // MIN handle (lime)
                  Positioned(
                    top: 8,
                    left: (w * minPos) - handle / 2,
                    child: _handle(color: t.success, size: handle),
                  ),
                  // TARGET handle (cyan)
                  Positioned(
                    top: 8,
                    left: (w * targetPos) - handle / 2,
                    child: _handle(color: t.accent, size: handle),
                  ),
                  // LISTED handle (hollow, outlined)
                  Positioned(
                    top: 10,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: t.bg,
                        shape: BoxShape.circle,
                        border: Border.all(color: t.dim, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Numeric tick labels — ¼ steps across the bar.
            _buildRangeTicks(t),
          ],
        );
      },
    );
  }

  Widget _handle({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 0,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildRangeTicks(WizardTokens t) {
    // Four equally-spaced ticks: 0, 1/3, 2/3, full listed.
    final base = widget.listedPrice;
    final ticks = [
      (base * 0.7).round(),
      (base * 0.8).round(),
      (base * 0.9).round(),
      base,
    ];
    String compact(int n) {
      if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
      return n.toString();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ticks
          .map(
            (v) => Text(
              compact(v),
              style: wizardMonoStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: t.dim2,
                letterSpacing: 0,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _dashedDivider(WizardTokens t) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, c) {
          const dashW = 4.0;
          final count = (c.maxWidth / (dashW * 2)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => SizedBox(
                width: dashW,
                height: 1,
                child: DecoratedBox(decoration: BoxDecoration(color: t.line)),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(WizardTokens t, String title) {
    return AppBar(
      backgroundColor: t.bg,
      surfaceTintColor: t.bg,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: t.text,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: t.text),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: t.line),
      ),
    );
  }

  Widget _buildBottomBar(WizardTokens t) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: WizardPrimaryButton(
          t: t,
          label: 'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: _onNext,
        ),
      ),
    );
  }
}
