import 'package:flutter/material.dart';

/// Bottom-sheet confirmation shown after the seller saves Smart Assist
/// settings (chat mode + advanced toggles). Replaces the small grey
/// "Settings saved" snackbar that used to fire from `SWASettingsScreen`.
///
/// Mirrors the structure of `SwaActivatedSheet` so the seller's two
/// SWA "commit" moments — initial activation and post-activation
/// updates — feel like the same product surface:
///   • Hero check icon — confirms the action landed
///   • Title with a small lightning badge
///   • Settings recap card — Mode + 3 toggle states
///   • "What buyers see now" bullets — mode-specific guidance
///   • Primary CTA "Done"
class SwaModeUpdatedSheet extends StatelessWidget {
  /// Backend chat_mode value: 'disabled' | 'human' | 'keyword_chat'.
  final String chatMode;
  final bool autoNegotiate;
  final bool quickResponse;
  final bool deliveryAvailable;

  /// Tapped when the seller chooses "View My Ads". The sheet itself
  /// pops first; the callback runs after, so the parent can navigate
  /// without fighting the bottom-sheet route.
  final VoidCallback? onViewMyAds;

  /// Tapped when the seller chooses "Back to home". Same pop-first
  /// pattern as [onViewMyAds].
  final VoidCallback? onBackToHome;

  const SwaModeUpdatedSheet({
    super.key,
    required this.chatMode,
    required this.autoNegotiate,
    required this.quickResponse,
    required this.deliveryAvailable,
    this.onViewMyAds,
    this.onBackToHome,
  });

  static Future<void> show(
    BuildContext context, {
    required String chatMode,
    required bool autoNegotiate,
    required bool quickResponse,
    required bool deliveryAvailable,
    VoidCallback? onViewMyAds,
    VoidCallback? onBackToHome,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => SwaModeUpdatedSheet(
        chatMode: chatMode,
        autoNegotiate: autoNegotiate,
        quickResponse: quickResponse,
        deliveryAvailable: deliveryAvailable,
        onViewMyAds: onViewMyAds,
        onBackToHome: onBackToHome,
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  String _modeLabel() {
    switch (chatMode) {
      case 'disabled':
        return 'Pills Only';
      case 'human':
        return 'Direct Messages';
      case 'keyword_chat':
        return 'Smart Chat';
      default:
        return chatMode;
    }
  }

  String _subtitle() {
    switch (chatMode) {
      case 'disabled':
        return 'Buyers will only see preset pill options.';
      case 'human':
        return "Buyers can now type freely — you'll reply yourself.";
      case 'keyword_chat':
        return 'Smart Assist now replies to common questions for you.';
      default:
        return 'Buyer chat experience has been updated.';
    }
  }

  List<String> _bullets() {
    switch (chatMode) {
      case 'disabled':
        return [
          'No free-text — buyers tap pills only',
          quickResponse
              ? 'Quick replies fire instantly when tapped'
              : 'Replies wait for you to confirm',
          deliveryAvailable
              ? 'Delivery is offered in the chat'
              : 'Pickup-only — no delivery option shown',
        ];
      case 'keyword_chat':
        return [
          'AI answers questions about price, condition, availability',
          autoNegotiate
              ? 'AI counters and accepts offers automatically'
              : "Offers wait for your decision — AI won't auto-accept",
          deliveryAvailable
              ? 'Delivery option visible to buyers'
              : 'Pickup-only — no delivery shown',
        ];
      case 'human':
        return [
          'Buyers can type any message — you reply yourself',
          'AI no longer auto-replies in this chat',
          deliveryAvailable
              ? 'Delivery still offered to buyers'
              : 'Pickup-only — no delivery shown',
        ];
      default:
        return [
          'Buyer chat experience updated',
          'Existing chats keep their full history',
        ];
    }
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        ? const Color(0x147DE3F0)
        : const Color(0x0F0E7C8D);

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final bullets = _bullets();

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

          // Hero icon — green check, same celebratory beat as
          // SwaActivatedSheet so seller pattern-matches the moment.
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

          // Title row + lightning brand mark.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mode updated',
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

          // Subtitle — mode-specific so the seller knows exactly what
          // changed for the buyer.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _subtitle(),
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
                  icon: Icons.handshake_outlined,
                  label: 'Auto-negotiate',
                  value: autoNegotiate ? 'ON' : 'OFF',
                  iconColor: cyanFg,
                  labelColor: mutedColor,
                  valueColor: autoNegotiate ? greenFg : mutedColor,
                ),
                _RecapRow(
                  icon: Icons.bolt_outlined,
                  label: 'Quick response',
                  value: quickResponse ? 'ON' : 'OFF',
                  iconColor: cyanFg,
                  labelColor: mutedColor,
                  valueColor: quickResponse ? greenFg : mutedColor,
                ),
                _RecapRow(
                  icon: Icons.local_shipping_outlined,
                  label: 'Delivery',
                  value: deliveryAvailable ? 'ON' : 'OFF',
                  iconColor: cyanFg,
                  labelColor: mutedColor,
                  valueColor: deliveryAvailable ? greenFg : mutedColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // "What buyers see now" — sets expectations so seller knows
          // exactly how the buyer chat looks after this change.
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'What buyers see now',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final b in bullets)
            _Bullet(text: b, dotColor: cyanFg, textColor: mutedColor),
          const SizedBox(height: 18),

          // Primary CTA — pop sheet first, then run callback.
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onViewMyAds != null) onViewMyAds!();
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
              if (onBackToHome != null) onBackToHome!();
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
