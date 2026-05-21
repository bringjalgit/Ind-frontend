import 'package:flutter/material.dart';

import 'pill_catalog.dart';

/// Buyer-side SWA quick-action rail rendered above the message
/// composer (or on its own in pills_only mode where there is no
/// composer).
///
/// 2026-05-17 rewrite — visual parity with the P2P pill rail:
///
///   • TWO horizontal rows with coupled parallax scrolling. Drag the
///     top row right → bottom row glides left (and vice versa). One
///     gesture exposes new pills on both rows, doubling the visible
///     surface area without a stacked wrap.
///   • A Make-an-Offer HERO pill sits above the two rails when the
///     server includes `make_offer` in the pill list. It is the
///     highest-intent buyer action and gets dedicated chrome (blue
///     gradient pill, "Tap to offer" hint).
///   • The `make_offer` entry is filtered out of the rail rows when
///     it is surfaced as the hero, so it is never duplicated.
///
/// Source of truth is still the backend's `follow_up_pills` array on
/// the most recent AI/system message (see SWAConversationData
/// lastFollowUpPills / Data.lastFollowUpPills). The widget is purely
/// presentational — tap dispatch is handed up to ChatScreen so it can
/// translate it into the right action (pill_tap WS message, offer
/// sheet, etc.).
///
/// Behaviour:
/// - Unknown pill IDs (not in [PillCatalog]) are silently skipped
///   instead of rendering a ghost chip. Keeps the rail resilient to
///   future backend additions without forcing a Flutter release.
/// - Empty list → renders nothing (no divider, no padding).
/// - [enabled]=false → chips render dimmed and taps are ignored; use
///   this while a pill-tap round-trip is in flight to prevent
///   double-submission.
class SwaPillRail extends StatefulWidget {
  final List<String> pillIds;
  final void Function(String pillId) onTap;
  final bool enabled;

  /// Tapped when the hero `Make an Offer` pill is invoked. When null,
  /// the hero is hidden entirely (single-row legacy behaviour). When
  /// provided AND `make_offer` is in [pillIds], the hero shows and
  /// `make_offer` is removed from the rail rows.
  final VoidCallback? onMakeOffer;

  /// Optional one-line AI rec to show in the hero's trailing chip,
  /// e.g. "AI suggests ₹1,38,000". Null = no chip.
  final String? aiSuggestionLabel;

  const SwaPillRail({
    super.key,
    required this.pillIds,
    required this.onTap,
    this.enabled = true,
    this.onMakeOffer,
    this.aiSuggestionLabel,
  });

  @override
  State<SwaPillRail> createState() => _SwaPillRailState();
}

class _SwaPillRailState extends State<SwaPillRail> {
  /// Coupled-scroll controllers for the two pill rows. Same mirror
  /// logic as the P2P rail: top scrolls right → bottom slides left
  /// and vice versa. `_lock` short-circuits the reverse callback so
  /// the mirror set doesn't loop back through the dst's listener.
  late final ScrollController _topCtrl = ScrollController();
  late final ScrollController _botCtrl = ScrollController();
  bool _lock = false;
  bool _couplingAttached = false;

  @override
  void dispose() {
    _topCtrl.dispose();
    _botCtrl.dispose();
    super.dispose();
  }

  void _ensureCouplingAttached() {
    if (_couplingAttached) return;
    void mirror(ScrollController src, ScrollController dst) {
      if (_lock) return;
      if (!src.hasClients || !dst.hasClients) return;
      final srcMax = src.position.maxScrollExtent;
      final dstMax = dst.position.maxScrollExtent;
      if (srcMax <= 0 || dstMax <= 0) return;
      final ratio = (src.offset / srcMax).clamp(0.0, 1.0);
      final target = dstMax * (1 - ratio);
      _lock = true;
      dst.jumpTo(target);
      WidgetsBinding.instance.addPostFrameCallback((_) => _lock = false);
    }

    _topCtrl.addListener(() => mirror(_topCtrl, _botCtrl));
    _botCtrl.addListener(() => mirror(_botCtrl, _topCtrl));
    // First frame: pre-scroll the bottom row to its rightmost end so
    // the parallax is immediately visible on the first drag.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_botCtrl.hasClients) {
        final max = _botCtrl.position.maxScrollExtent;
        if (max > 0) _botCtrl.jumpTo(max);
      }
    });
    _couplingAttached = true;
  }

  @override
  Widget build(BuildContext context) {
    // Defensive filter: keep only buyer-initiable pill IDs the local
    // catalog knows about, in the order the backend sent them. System
    // response IDs that slipped through are dropped.
    final allSpecs = <PillSpec>[];
    for (final id in widget.pillIds) {
      final spec = PillCatalog.specFor(id);
      if (spec != null) allSpecs.add(spec);
    }

    // Hero handling: when `onMakeOffer` is wired AND `make_offer` is
    // in the rail's pill list, surface it as a hero pill above the
    // two rows and strip it from the rail-row specs.
    final bool heroVisible = widget.onMakeOffer != null &&
        widget.pillIds.contains('make_offer');
    final railSpecs = heroVisible
        ? allSpecs.where((s) => s.id != 'make_offer').toList()
        : allSpecs;

    if (!heroVisible && railSpecs.isEmpty) return const SizedBox.shrink();

    // Split rail specs into two roughly-equal rows. The top row gets
    // the ceiling so a 3-pill case is rendered as 2 + 1 (busier top,
    // lighter bottom) rather than 1 + 2.
    final int half = (railSpecs.length / 2).ceil();
    final topSpecs = railSpecs.take(half).toList(growable: false);
    final botSpecs = railSpecs.skip(half).toList(growable: false);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _ensureCouplingAttached();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (heroVisible) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: _buildHeroOfferPill(isDark),
            ),
            const SizedBox(height: 10),
          ],
          if (topSpecs.isNotEmpty)
            _buildRailRow(topSpecs, _topCtrl, isDark),
          if (botSpecs.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildRailRow(botSpecs, _botCtrl, isDark),
          ],
        ],
      ),
    );
  }

  /// Hero "Make an Offer" pill — full-width, brand-blue gradient.
  /// Optional trailing AI-suggestion chip on the right when the
  /// caller has a recommendation to surface.
  Widget _buildHeroOfferPill(bool isDark) {
    const blue = Color(0xFF1677FF);
    const blueDeep = Color(0xFF0F5FCE);
    return Material(
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.enabled ? widget.onMakeOffer : null,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [blue, blueDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: blue.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.currency_rupee_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Make an Offer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if ((widget.aiSuggestionLabel ?? '').isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD600),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFFD600),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.aiSuggestionLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Tap to offer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Single horizontal rail row with the given specs + controller.
  Widget _buildRailRow(
    List<PillSpec> specs,
    ScrollController controller,
    bool isDark,
  ) {
    if (specs.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: specs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: _buildPill(specs[i], isDark)),
      ),
    );
  }

  /// Individual pill chip. Tap dispatches to the parent.
  Widget _buildPill(PillSpec spec, bool isDark) {
    final bgColor = isDark
        ? const Color(0xFF10272F)
        : const Color(0xFFE8F7FA);
    final borderColor =
        isDark ? const Color(0xFF2A5560) : const Color(0xFFBEE4EC);
    final iconColor =
        isDark ? const Color(0xFF7DE3F0) : const Color(0xFF0E7C8D);
    final labelColor =
        isDark ? const Color(0xFFE6F6FA) : const Color(0xFF083945);

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.enabled ? () => widget.onTap(spec.id) : null,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
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
                Icon(spec.icon, size: 16, color: iconColor),
                const SizedBox(width: 7),
                Text(
                  spec.label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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
}
