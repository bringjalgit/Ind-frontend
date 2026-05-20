import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/OfferRecommendationModel.dart';
import '../theme/AppTextStyles.dart';
import '../theme/ThemeHelper.dart';

/// Display mode for [P2POfferSheet].
///
///   * [buyerOffer] — buyer sending an initial offer. AI recommendation
///     card is the hero. Quick-pick chips frame the recommendation
///     band. Custom-amount input is the escape hatch.
///   * [sellerCounter] — seller responding to a buyer's offer with a
///     counter. The AI's suggested counter is the hero number. Quick
///     chips bracket the counter so the seller can nudge up or down
///     without typing. The buyer's incoming offer is shown as the
///     reference (replacing the "Listed at" line).
enum OfferSheetMode { buyerOffer, sellerCounter }

/// Modal bottom sheet for the P2P "Make an Offer" flow.
///
/// Distinct from SwaOfferSheet (used by SWA conversations) — that one
/// is left untouched per the SWA-isolation policy. This widget is the
/// new home for the P2P offer flow with three improvements over the
/// legacy sheet:
///
///   1. AI recommendation card with a one-tap "Use AI suggestion"
///      action. Sourced from /app/get-offer-recommendation/:id; on
///      fetch failure the card hides and the sheet still works with
///      chips + custom input.
///   2. Three quick-pick chips around the recommended band so the
///      buyer can pick a number without typing.
///   3. Custom-amount input retained as the escape hatch with the same
///      ≤10× listed price guardrail SwaOfferSheet has.
///
/// Validation matches the legacy sheet — positive integer, soft 10×
/// cap to catch fat-finger typos client-side. Server still has the
/// final word on whether the number lands.
class P2POfferSheet extends StatefulWidget {
  /// Listed price reference, used for the chip band when [recommendation]
  /// is null (fallback heuristic) and for the 10× soft cap.
  final int? listingPrice;

  /// Server-fetched recommendation. Null when the fetch failed or is
  /// still in-flight; the sheet then uses a category-agnostic fallback
  /// of 95% / 92% / 89% of [listingPrice]. The sheet works either way.
  final OfferRecommendation? recommendation;

  /// In [OfferSheetMode.sellerCounter] this is the buyer's current
  /// offer the seller is countering. Drives the reference card and
  /// the chip band (counters cluster between buyer offer and list).
  final int? buyerOffer;

  /// Display mode — buyer (offer) or seller (counter). See enum docs.
  final OfferSheetMode mode;

  /// Fired when the user submits. The caller owns sending the message
  /// over the WebSocket; the sheet closes itself just before this fires.
  final void Function(int amount) onSubmit;

  const P2POfferSheet({
    super.key,
    this.listingPrice,
    this.recommendation,
    this.buyerOffer,
    this.mode = OfferSheetMode.buyerOffer,
    required this.onSubmit,
  });

  @override
  State<P2POfferSheet> createState() => _P2POfferSheetState();
}

class _P2POfferSheetState extends State<P2POfferSheet> {
  static const Color _brandBlue = Color(0xFF1677FF);
  static const Color _aiViolet = Color(0xFF7C5CFF);
  static const Color _success = Color(0xFF2E7D32);
  static const Color _lineSoft = Color(0xFFE5E8EE);

  final _controller = TextEditingController();
  String? _error;

  /// Index of the currently selected quick chip, or -1 when the buyer
  /// has typed a custom amount (custom input overrides any chip).
  int _selectedChip = -1;

  /// True when the buyer has hand-edited the custom input. We then stop
  /// auto-syncing the input with chip selection.
  bool _customEdited = false;

  @override
  void initState() {
    super.initState();
    // Pre-select the AI recommendation by default so a "tap, send" path
    // is one step shorter. Seeds the input field so the Send button
    // shows the value immediately.
    final initial = _recommendedAmount;
    if (initial != null) {
      _controller.text = initial.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _recommendedAmount {
    if (widget.recommendation != null && widget.recommendation!.recommended > 0) {
      return widget.recommendation!.recommended;
    }
    // Fallback when the backend rec didn't load — 5% off list for
    // buyer mode, midpoint between buyer offer and list for seller
    // counter mode. Keeps the sheet usable offline.
    if (widget.mode == OfferSheetMode.sellerCounter) {
      final list = widget.listingPrice ?? 0;
      final buyer = widget.buyerOffer ?? 0;
      if (list > 0 && buyer > 0 && list > buyer) {
        return ((list + buyer) ~/ 2);
      }
    }
    final list = widget.listingPrice ?? 0;
    if (list <= 0) return null;
    return (list * 0.95).round();
  }

  /// The three quick-pick amounts shown as chips. Buyer mode uses the
  /// rec band when available, else a list-relative −3/−7/−10% scale.
  /// Seller counter mode brackets between buyer offer and list.
  List<_ChipSpec> get _chips {
    if (widget.mode == OfferSheetMode.sellerCounter) {
      final list = widget.listingPrice ?? 0;
      final buyer = widget.buyerOffer ?? 0;
      final rec = _recommendedAmount ?? 0;
      if (list <= 0 || buyer <= 0 || rec <= 0) return const [];
      // Three rungs: closer-to-buyer / midpoint / closer-to-list.
      // We rebuild relative to the actual rec so the chips never
      // contradict the AI card.
      final span = (list - buyer).abs();
      final lower = (buyer + span * 0.35).round();
      final mid = rec;
      final upper = (buyer + span * 0.75).round();
      return [
        _ChipSpec(label: 'Lean buyer', amount: lower),
        _ChipSpec(label: 'AI midpoint', amount: mid),
        _ChipSpec(label: 'Lean list', amount: upper),
      ];
    }

    // Buyer mode
    final rec = widget.recommendation;
    final list = widget.listingPrice ?? 0;
    if (rec != null && list > 0) {
      // Three points around the rec band: low, recommended, high.
      // Always rounded values from the backend's `roundClean`.
      final discounts = <_ChipSpec>[];
      if (rec.lowBound > 0) {
        final pct = ((1 - rec.lowBound / list) * 100).round();
        discounts.add(_ChipSpec(label: '−$pct%', amount: rec.lowBound));
      }
      if (rec.recommended > 0) {
        final pct = ((1 - rec.recommended / list) * 100).round();
        discounts.add(_ChipSpec(label: '−$pct%', amount: rec.recommended));
      }
      if (rec.highBound > 0) {
        final pct = ((1 - rec.highBound / list) * 100).round();
        discounts.add(_ChipSpec(label: '−$pct%', amount: rec.highBound));
      }
      // De-dupe in case low/rec/high collapse to the same number after
      // rounding on tiny listings.
      final seen = <int>{};
      return discounts.where((c) => seen.add(c.amount)).toList(growable: false);
    }

    if (list <= 0) return const [];
    // Final fallback: fixed −3 / −7 / −10 band rounded to nearest 50.
    int round50(double v) => ((v / 50).round()) * 50;
    return [
      _ChipSpec(label: '−3%', amount: round50(list * 0.97)),
      _ChipSpec(label: '−7%', amount: round50(list * 0.93)),
      _ChipSpec(label: '−10%', amount: round50(list * 0.90)),
    ];
  }

  void _selectChip(int i, int amount) {
    setState(() {
      _selectedChip = i;
      _customEdited = false;
      _controller.text = amount.toString();
      _error = null;
    });
  }

  void _useAiSuggestion() {
    final amt = _recommendedAmount;
    if (amt == null || amt <= 0) return;
    // Find matching chip if any so the chip row also reflects selection.
    final chips = _chips;
    final idx = chips.indexWhere((c) => c.amount == amt);
    setState(() {
      _selectedChip = idx;
      _customEdited = false;
      _controller.text = amt.toString();
      _error = null;
    });
  }

  void _onSubmitPressed() {
    final raw = _controller.text.trim().replaceAll(',', '');
    final amt = int.tryParse(raw);

    if (amt == null || amt <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    final priceRef = widget.listingPrice;
    if (priceRef != null && priceRef > 0 && amt > priceRef * 10) {
      setState(() => _error = 'That amount looks unusually high');
      return;
    }

    Navigator.of(context).pop();
    widget.onSubmit(amt);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final bg = ThemeHelper.backgroundColor(context);
    final isDark = ThemeHelper.isDarkMode(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isCounter = widget.mode == OfferSheetMode.sellerCounter;

    return AnimatedPadding(
      padding: viewInsets,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(.18),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isCounter ? 'Send Counter Offer' : 'Make an Offer',
                style: AppTextStyles.titleLarge(textColor).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isCounter
                    ? "Pick a chip, tap the AI midpoint, or type your own."
                    : 'Tap the AI suggestion, pick a quick price, or enter your own.',
                style: AppTextStyles.bodySmall(textColor.withOpacity(.7)),
              ),
              const SizedBox(height: 14),

              _buildReferenceCard(textColor, isDark),
              const SizedBox(height: 14),

              if (_recommendedAmount != null)
                _buildAiCard(textColor, isDark, isCounter: isCounter),

              if (_chips.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  isCounter ? 'Or pick a counter' : 'Or pick a quick price',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                _buildChipsRow(textColor, isDark),
              ],

              const SizedBox(height: 16),
              Text(
                'Or enter a custom amount',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) {
                  // Always rebuild so the "Send Offer · ₹X" suffix on
                  // the submit button reflects the freshly-typed amount.
                  // Earlier only the first edit (and the error-clear)
                  // triggered setState, so subsequent keystrokes left
                  // the button label stale until some other interaction
                  // (e.g. dragging the sheet) forced a rebuild.
                  setState(() {
                    if (!_customEdited) {
                      _customEdited = true;
                      _selectedChip = -1;
                    }
                    if (_error != null) _error = null;
                  });
                },
                onSubmitted: (_) => _onSubmitPressed(),
                style: AppTextStyles.bodyMedium(textColor).copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: AppTextStyles.bodyMedium(textColor).copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  hintText: 'Your amount',
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onSubmitPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isCounter
                            ? 'Send Counter${_amountSuffixForButton()}'
                            : 'Send Offer${_amountSuffixForButton()}',
                        style: AppTextStyles.bodyMedium(Colors.white).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isCounter
                    ? 'The buyer can accept, counter again, or decline.'
                    : "Once sent, the seller has 48 hours to respond.\nYou can keep chatting in the meantime.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: textColor.withOpacity(.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _amountSuffixForButton() {
    final raw = _controller.text.trim().replaceAll(',', '');
    final amt = int.tryParse(raw);
    if (amt == null || amt <= 0) return '';
    return ' · ₹${_formatInr(amt)}';
  }

  // ── Reference card (listed price OR buyer's incoming offer) ───────
  //
  // Dark mode: chrome flips to a subtle surface lift over the sheet's
  // own bg so the card still reads as a distinct block without being
  // a white island on a dark sheet. `0xFF1B2233` is the same soft
  // surface used by the neutral P2P pill chips elsewhere in the app.
  Widget _buildReferenceCard(Color textColor, bool isDark) {
    final list = widget.listingPrice ?? 0;
    final buyer = widget.buyerOffer ?? 0;
    final isCounter = widget.mode == OfferSheetMode.sellerCounter;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2233) : const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : _lineSoft,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCounter ? 'Buyer offered' : 'Listed at',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: textColor.withOpacity(.55),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '₹${_formatInr(isCounter ? buyer : list)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _brandBlue,
                  ),
                ),
              ],
            ),
          ),
          if (isCounter && list > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Listed',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: textColor.withOpacity(.55),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '₹${_formatInr(list)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor.withOpacity(.7),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── AI Recommendation card ────────────────────────────────────────
  //
  // Dark-mode chrome: the lavender gradient flips to a deep-violet
  // tint so the card still reads as the AI surface (same hue, lower
  // luminance). The inset "AI RECOMMENDS" pill keeps a card-coloured
  // surface so the violet icon + label pop against a neutral chip.
  // Success chips (MOST LIKELY / −X% off list) use a translucent
  // success colour so the green reads on either background without a
  // jarring pastel block.
  Widget _buildAiCard(Color textColor, bool isDark, {required bool isCounter}) {
    final amt = _recommendedAmount;
    final rec = widget.recommendation;
    final list = widget.listingPrice ?? 0;
    final reason = rec?.reasonShort.isNotEmpty == true
        ? rec!.reasonShort
        : (isCounter
            ? "Buyers usually accept a counter near the midpoint of their offer and your list price."
            : "Listings like this one typically close a few percent below the asking price.");

    String deltaLabel = '';
    if (amt != null && list > 0) {
      final pct = ((1 - amt / list) * 100).round();
      if (pct > 0) deltaLabel = '−$pct% off list';
    }

    final gradientColors = isDark
        ? const [Color(0xFF2A2150), Color(0xFF1F1A3E)]
        : const [Color(0xFFF5F1FF), Color(0xFFFAF7FF)];
    final borderColor = isDark
        ? const Color(0xFF4B3F8C)
        : const Color(0xFFE2D8FF);
    final aiChipSurface =
        isDark ? const Color(0xFF1B1530) : Colors.white;
    final successBg = _success.withOpacity(isDark ? 0.22 : 0.12);
    final successText = isDark ? const Color(0xFF85DC9C) : _success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: aiChipSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: _aiViolet),
                    const SizedBox(width: 4),
                    Text(
                      isCounter ? 'AI COUNTER' : 'AI RECOMMENDS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: _aiViolet,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: successBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'MOST LIKELY TO LAND',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: successText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amt != null ? '₹${_formatInr(amt)}' : '—',
                style: TextStyle(
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 10),
              if (deltaLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: successBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    deltaLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: successText,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: textColor.withOpacity(.75),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _useAiSuggestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: _aiViolet,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text(
                'Use AI suggestion',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick-price chip row ──────────────────────────────────────────
  //
  // Dark mode: the unselected chip is the standard P2P-pill neutral
  // surface, and the selected chip uses a translucent brand-blue
  // wash so the highlight stays legible without flipping to a white
  // block on a dark sheet.
  Widget _buildChipsRow(Color textColor, bool isDark) {
    final chips = _chips;
    final chipBg = isDark ? const Color(0xFF1B2233) : Colors.white;
    final chipSelectedBg = isDark
        ? _brandBlue.withOpacity(0.18)
        : const Color(0xFFF4F9FF);
    final chipBorder =
        isDark ? Colors.white.withOpacity(0.08) : _lineSoft;
    return Row(
      children: List.generate(chips.length, (i) {
        final c = chips[i];
        final selected = i == _selectedChip;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == chips.length - 1 ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _selectChip(i, c.amount),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: selected ? chipSelectedBg : chipBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? _brandBlue : chipBorder,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: selected ? _brandBlue : textColor.withOpacity(.55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${_formatInr(c.amount)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Indian-locale grouping for display. Matches the formatter in
  /// SwaOfferSheet and ChatScreen so the same number is rendered
  /// identically across the app.
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

class _ChipSpec {
  final String label;
  final int amount;
  const _ChipSpec({required this.label, required this.amount});
}
