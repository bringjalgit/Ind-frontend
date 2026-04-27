import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/AppTextStyles.dart';
import '../../../theme/ThemeHelper.dart';

/// Modal bottom sheet for submitting an SWA offer.
///
/// Shown when the buyer taps the "Make an offer" pill on the chat rail.
/// Minimal by design — numeric-only input, a visible listed-price
/// reference, and one submit button. The sheet is purely a collector:
/// the WS send happens via the [onSubmit] callback after the sheet is
/// closed, so the caller owns both the cubit dependency and the
/// optimistic message emission.
///
/// Validation:
///   • non-empty, positive integer
///   • soft cap at 10× listed price to catch fat-finger typos before
///     the server has to reject them
///
/// Keyboard-aware via AnimatedPadding + MediaQuery.viewInsets so the
/// sheet slides up above the on-screen numeric keypad on both iOS and
/// Android.
class SwaOfferSheet extends StatefulWidget {
  final int? listingPrice;
  final void Function(int amount) onSubmit;

  const SwaOfferSheet({
    super.key,
    this.listingPrice,
    required this.onSubmit,
  });

  @override
  State<SwaOfferSheet> createState() => _SwaOfferSheetState();
}

class _SwaOfferSheetState extends State<SwaOfferSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmitPressed() {
    final raw = _controller.text.trim().replaceAll(',', '');
    final amt = int.tryParse(raw);

    if (amt == null || amt <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }

    // 10× listed is a generous fat-finger guardrail. The actual
    // server-side floor is never revealed here — the server will still
    // counter / decline per the pricing ladder. This only catches the
    // accidental extra-zero case client-side.
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
    final viewInsets = MediaQuery.of(context).viewInsets;

    return AnimatedPadding(
      padding: viewInsets,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Make an Offer',
              style: AppTextStyles.titleLarge(textColor).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.listingPrice != null &&
                widget.listingPrice! > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Listed at ₹${_formatInr(widget.listingPrice!)}',
                style: AppTextStyles.bodySmall(textColor.withOpacity(.7)),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              autofocus: true,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _onSubmitPressed(),
              style: AppTextStyles.bodyMedium(textColor).copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle:
                    AppTextStyles.bodyMedium(textColor).copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                hintText: 'Your offer',
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSubmitPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Submit offer',
                  style: AppTextStyles.bodyMedium(Colors.white).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Indian-locale grouping for display (matches ChatScreen._formatInr).
  /// Kept inline so the sheet is self-contained and doesn't import
  /// screen internals.
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
