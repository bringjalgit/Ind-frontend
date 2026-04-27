import 'package:flutter/material.dart';

/// Bottom-sheet success confirmation shown after the seller activates
/// Smart Assist on a listing. Replaces the small floating green
/// snackbar that used to fire from `SWAChatModeWizardScreen`.
///
/// The sheet is intentionally rich:
///   • Hero check icon — celebrates the moment
///   • Title with a small lightning badge — reinforces the SWA brand
///   • Settings recap card — seller sees what they configured
///   • "What happens now" bullets — sets expectations for next steps
///   • Primary CTA "View Dashboard" + secondary "Back to listing"
///
/// Pure Material — no extra Flutter dependencies. Theme-adaptive (light
/// + dark). Use the static [show] helper for the standard modal
/// presentation; the widget is exposed publicly so a future inline
/// preview / onboarding tour can mount it without the modal chrome.
class SwaActivatedSheet extends StatelessWidget {
  final String listingTitle;

  /// Backend chat_mode value: 'disabled' | 'human' | 'keyword_chat'.
  /// Translated to a user-facing label inside the sheet.
  final String chatMode;

  final int expectedPrice;
  final int floorPrice;
  final int availabilityWindow;

  /// Tapped when the buyer chooses "View Dashboard". The sheet itself
  /// pops first; the callback runs after, so the parent can navigate
  /// without fighting the bottom-sheet route.
  final VoidCallback? onViewDashboard;

  /// Tapped when the buyer chooses "Back to listing". Same pop-first
  /// pattern as [onViewDashboard].
  final VoidCallback? onBackToListing;

  const SwaActivatedSheet({
    super.key,
    required this.listingTitle,
    required this.chatMode,
    required this.expectedPrice,
    required this.floorPrice,
    required this.availabilityWindow,
    this.onViewDashboard,
    this.onBackToListing,
  });

  /// Standard presentation: modal bottom sheet, scroll-controlled,
  /// transparent route background so the rounded top corners aren't
  /// clipped by a default white box.
  static Future<void> show(
    BuildContext context, {
    required String listingTitle,
    required String chatMode,
    required int expectedPrice,
    required int floorPrice,
    required int availabilityWindow,
    VoidCallback? onViewDashboard,
    VoidCallback? onBackToListing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => SwaActivatedSheet(
        listingTitle: listingTitle,
        chatMode: chatMode,
        expectedPrice: expectedPrice,
        floorPrice: floorPrice,
        availabilityWindow: availabilityWindow,
        onViewDashboard: onViewDashboard,
        onBackToListing: onBackToListing,
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  String _modeLabel() {
    switch (chatMode) {
      case 'disabled':
        return 'Quick Replies';
      case 'human':
        return 'Direct Messages';
      case 'keyword_chat':
        return 'Smart Chat';
      default:
        return chatMode;
    }
  }

  /// Indian-locale grouped integer: 52000 → "52,000", 100000 → "1,00,000".
  /// Inline because adding `intl`'s NumberFormat just for this would
  /// pull a heavyweight dependency for a single use site.
  static String _formatInr(int n) {
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

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Palette — kept in sync with SwaPillRail / pill_catalog so the
    // success sheet feels like the same product surface.
    final cardBg = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final cyanBg = isDark ? const Color(0xFF10272F) : const Color(0xFFE8F7FA);
    final cyanFg = isDark ? const Color(0xFF7DE3F0) : const Color(0xFF0E7C8D);
    final greenBg = isDark ? const Color(0xFF1A3A2A) : const Color(0xFFDCFCE7);
    const greenFg = Color(0xFF22C55E);
    final textColor = isDark ? Colors.white : const Color(0xFF0A1628);
    final mutedColor = isDark
        ? Colors.white.withOpacity(0.65)
        : const Color(0xFF6B7280);
    final tintBg = isDark
        ? const Color(0x147DE3F0) // ~8% cyan
        : const Color(0x0F0E7C8D);

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag-grabber
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Hero icon — green check, intentionally not the lightning so
          // the celebratory beat is visually distinct from the brand
          // mark.
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: greenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: greenFg,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title row: "You're all set!" + small inline cyan lightning
          // badge that signals "Smart Assist is the thing that's now
          // running" without needing a 🎉 emoji.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You're all set!",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: cyanBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flash_on_rounded,
                  color: cyanFg,
                  size: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Subtitle — quotes the listing title so the seller sees
          // exactly which item Smart Assist is now handling.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Smart Assist is now negotiating on your behalf for "$listingTitle".',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: mutedColor,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Settings recap card.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: tintBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _RecapRow(
                  icon: Icons.flash_on_rounded,
                  label: 'Mode',
                  value: _modeLabel(),
                  iconColor: cyanFg,
                  labelColor: mutedColor,
                  valueColor: textColor,
                ),
                _RecapRow(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Target',
                  value: '₹${_formatInr(expectedPrice)}',
                  iconColor: cyanFg,
                  labelColor: mutedColor,
                  valueColor: textColor,
                ),
                _RecapRow(
                  icon: Icons.shield_outlined,
                  label: 'Floor',
                  value: '₹${_formatInr(floorPrice)}',
                  iconColor: cyanFg,
                  labelColor: mutedColor,
                  valueColor: textColor,
                ),
                _RecapRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Active for',
                  value:
                      '$availabilityWindow ${availabilityWindow == 1 ? 'day' : 'days'}',
                  iconColor: cyanFg,
                  labelColor: mutedColor,
                  valueColor: textColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // "What happens now" — sets expectations so the seller knows
          // Smart Assist is actively running, not just configured.
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'What happens now',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Bullet(
            text: 'Buyers see a guided chat experience',
            dotColor: cyanFg,
            textColor: mutedColor,
          ),
          _Bullet(
            text: "You'll get a push when someone makes an offer",
            dotColor: cyanFg,
            textColor: mutedColor,
          ),
          _Bullet(
            text: 'Manage everything from your dashboard',
            dotColor: cyanFg,
            textColor: mutedColor,
          ),
          const SizedBox(height: 18),

          // Primary CTA — pop the sheet first then run the callback so
          // navigation doesn't fight the bottom-sheet route.
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onViewDashboard != null) onViewDashboard!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cyanFg,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'View My Ads',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Text-only secondary action.
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onBackToListing != null) onBackToListing!();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 9),
            ),
            child: Text(
              'Back to home',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: cyanFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Internal sub-widgets ────────────────────────────────────────────────

class _RecapRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color labelColor;
  final Color valueColor;

  const _RecapRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 11.5, color: labelColor),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final Color dotColor;
  final Color textColor;

  const _Bullet({
    required this.text,
    required this.dotColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 7, right: 8),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                color: textColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
