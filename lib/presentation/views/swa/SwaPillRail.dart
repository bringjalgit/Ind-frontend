import 'package:flutter/material.dart';

import 'pill_catalog.dart';

/// Horizontal strip of clickable Sell-with-AI quick-action pills shown
/// above the message composer on an SWA conversation.
///
/// Source of truth is the backend's `follow_up_pills` array on the most
/// recent AI/system message (see SWAConversationData.lastFollowUpPills
/// and Data.lastFollowUpPills on the chat-history model). The widget is
/// intentionally pure presentation — tap dispatch is handed to the
/// parent so the chat screen can translate it into the right action
/// (pill_tap WS message, offer sheet, etc.).
///
/// Behaviour:
/// - Unknown pill IDs (not in [PillCatalog]) are silently skipped
///   instead of rendering a ghost chip. Keeps the rail resilient to
///   future backend additions without forcing a Flutter release.
/// - Empty list → renders nothing (no divider, no padding).
/// - [enabled]=false → chips render dimmed and taps are ignored; use
///   this while a pill-tap round-trip is in flight to prevent
///   double-submission.
class SwaPillRail extends StatelessWidget {
  final List<String> pillIds;
  final void Function(String pillId) onTap;
  final bool enabled;

  const SwaPillRail({
    super.key,
    required this.pillIds,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Defensive filter: keep only buyer-initiable pill IDs, in the order
    // the backend sent them. System-response IDs that slipped through
    // are dropped.
    final specs = <PillSpec>[];
    for (final id in pillIds) {
      final spec = PillCatalog.specFor(id);
      if (spec != null) specs.add(spec);
    }
    if (specs.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Chip colour palette chosen to match the SWA accents used in the
    // seller dashboard (cyan-on-dark, subtle tint on light).
    final bgColor = isDark
        ? const Color(0xFF10272F) // deep teal on dark
        : const Color(0xFFE8F7FA); // very light teal on light
    final borderColor = isDark
        ? const Color(0xFF2A5560)
        : const Color(0xFFBEE4EC);
    final iconColor = isDark
        ? const Color(0xFF7DE3F0)
        : const Color(0xFF0E7C8D);
    final labelColor = isDark
        ? const Color(0xFFE6F6FA)
        : const Color(0xFF083945);

    // Each pill shares the same base style. Extracted into a local
    // builder so the row layout stays readable below.
    Widget buildPill(PillSpec spec) {
      return Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Material(
          // Transparent Material is required under InkWell so the ripple
          // animation renders on tap — without it, taps look dead.
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: enabled ? () => onTap(spec.id) : null,
            child: Container(
              // Slightly taller + wider than before so the pills feel
              // clickable and the icon + label breathe. Height ends up
              // at 40px with 20px icon — thumb-friendly.
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(color: borderColor, width: 1),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  // Subtle shadow so pills read as "buttons" rather
                  // than flat background colour. Lighter in dark mode
                  // to avoid washing out the bg tint.
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(spec.icon, size: 18, color: iconColor),
                  const SizedBox(width: 8),
                  Text(
                    spec.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Horizontal scroll — every pill always present, buyer swipes to
    // reveal more if screen is too narrow. Feels more like a native
    // "quick replies" strip than a stacked wrap. A fixed height keeps
    // the rail from stealing vertical space from the message list.
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: specs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          // Align children to the vertical centre of the rail so pills
          // with icons + labels sit consistently regardless of tiny
          // font-metric differences.
          itemBuilder: (_, i) => Center(child: buildPill(specs[i])),
        ),
      ),
    );
  }
}
