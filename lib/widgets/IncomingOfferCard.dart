import 'package:flutter/material.dart';

import '../theme/ThemeHelper.dart';

/// Seller-side hero card rendered above the response pill rail when
/// the most-recent buyer message carries an offer (P2P chat). Pulls
/// the buyer's offered amount, the listing's listed price for delta
/// computation, and the AI's suggested counter — and gives the seller
/// a one-glance read on the situation.
///
/// Pure UI; tap handlers are owned by ChatScreen. Lives alongside the
/// response pill row (Accept / Counter / Decline) which renders
/// immediately below. The card itself doesn't fire anything.
class IncomingOfferCard extends StatelessWidget {
  /// The buyer's offer in rupees. Required — the card has no other
  /// reason to render than this number.
  final int buyerOffer;

  /// Listed price for percentage-delta computation. Null suppresses
  /// the "−X% off list" chip cleanly.
  final int? listedPrice;

  /// AI-suggested counter from the recommendation endpoint. Drives
  /// both the AI read line and the suggested counter chip in the
  /// response row (seller-side, not in this card). Null = no AI line.
  final int? aiSuggestedCounter;

  /// Optional one-line buyer read from the AI ("Buyer rated Hot ·
  /// viewed your listing 4 times, replied within 9 min..."). When
  /// null, the card falls back to a generic line keyed off the delta.
  final String? aiBuyerReadShort;

  const IncomingOfferCard({
    super.key,
    required this.buyerOffer,
    this.listedPrice,
    this.aiSuggestedCounter,
    this.aiBuyerReadShort,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final isDark = ThemeHelper.isDarkMode(context);

    final delta = _deltaPct;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF2A2410), Color(0xFF332C13)]
              : const [Color(0xFFFFFCEC), Color(0xFFFFF6CE)],
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF5B4F1F) : const Color(0xFFF2E2A0),
        ),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: const Color(0xFFB48C00).withOpacity(.12),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _PulseDot(),
                    SizedBox(width: 6),
                    Text(
                      'BUYER OFFERED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: Color(0xFFFFD600),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (listedPrice != null && listedPrice! > 0)
                Text(
                  'on listed ₹${_formatInr(listedPrice!)}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: textColor.withOpacity(.6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_formatInr(buyerOffer)}',
                style: TextStyle(
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 10),
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    delta,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: textColor.withOpacity(.75),
                    ),
                  ),
                ),
            ],
          ),
          if (aiSuggestedCounter != null && aiSuggestedCounter! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B1A14) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF4C411F)
                      : const Color(0xFFECE3B6),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      // Dark mode: the lavender pastel reads as a
                      // washed-out blob on a dark inner card. Drop the
                      // fill to a translucent violet wash so the icon
                      // + label do the work.
                      color: isDark
                          ? const Color(0xFF7C5CFF).withOpacity(0.18)
                          : const Color(0xFFEEEAFF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome,
                            size: 11, color: Color(0xFF7C5CFF)),
                        SizedBox(width: 4),
                        Text(
                          'AI READ',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            color: Color(0xFF7C5CFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _aiReadLine(),
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: textColor.withOpacity(.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? get _deltaPct {
    final list = listedPrice;
    if (list == null || list <= 0 || buyerOffer <= 0) return null;
    final pct = ((1 - buyerOffer / list) * 100);
    if (pct <= 0) return null;
    // 1 decimal place if under 10% to show closeness, integer otherwise.
    final s = pct < 10 ? pct.toStringAsFixed(1) : pct.round().toString();
    return '−$s% off list';
  }

  String _aiReadLine() {
    if (aiBuyerReadShort != null && aiBuyerReadShort!.trim().isNotEmpty) {
      return aiBuyerReadShort!;
    }
    if (aiSuggestedCounter == null) {
      return 'A counter near ₹${_formatInr(buyerOffer)} usually lands when the buyer is engaged.';
    }
    return 'Listings like yours usually close after a counter near ₹${_formatInr(aiSuggestedCounter!)}.';
  }

  String _formatInr(int n) {
    final s = n.abs().toString();
    if (s.length <= 3) return n < 0 ? '-$s' : s;
    final last3 = s.substring(s.length - 3);
    final head = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    int cursor = head.length;
    while (cursor > 2) {
      buf.write(',');
      buf.write(head.substring(cursor - 2, cursor));
      cursor -= 2;
    }
    final prefix = head.substring(0, cursor) + buf.toString();
    return (n < 0 ? '-' : '') + prefix + ',' + last3;
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFFFFD600),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
