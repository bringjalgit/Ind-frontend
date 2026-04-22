import 'package:flutter/material.dart';
import '../../swa/widgets/wizard_theme.dart';

/// "A · Refined Dark" style KYC status card — one widget, two states.
///
/// Theme-adaptive via [WizardTokens] (inverts surface / text tokens for
/// light mode while keeping the same cyan/amber/lime design language
/// shared with the SWA wizard screens).
///
/// Used in [AadhaarVerificationScreen] to render:
///   • review   — admin is reviewing the submission (amber, clock icon,
///                active timeline step, ~partial progress)
///   • verified — admin approved (lime/green, checkmark, all timeline
///                steps done, 100% progress)
enum KycCardState { review, verified }

class KycStatusCard extends StatelessWidget {
  final KycCardState state;

  /// ISO timestamp of when the user submitted (for progress calc).
  /// Used only when [state] == review. Null-safe.
  final String? submittedAtIso;

  /// Optional explicit progress override (0.0-1.0). If null, the card
  /// auto-computes from submittedAtIso against a 48h review window.
  final double? progressOverride;

  const KycStatusCard({
    super.key,
    required this.state,
    this.submittedAtIso,
    this.progressOverride,
  });

  @override
  Widget build(BuildContext context) {
    final t = WizardTokens.of(context);
    final isReview = state == KycCardState.review;

    // Pick the accent color from our token palette so light + dark
    // automatically get the right contrast: amber for review, lime
    // success for verified.
    final accent = isReview ? t.warn : t.success;
    final progress = progressOverride ?? _computeProgress();

    return Container(
      width: double.infinity,
      color: t.bg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status badge at the very top — pulsing dot + uppercase label.
              _StatusBadge(
                t: t,
                accent: accent,
                label: isReview ? 'IN REVIEW' : 'VERIFIED',
              ),
              const SizedBox(height: 28),

              // Centered ring illustration with clock / check in the middle.
              _RingIllustration(
                t: t,
                accent: accent,
                icon: isReview
                    ? Icons.access_time_rounded
                    : Icons.check_rounded,
              ),
              const SizedBox(height: 24),

              // Large editorial title
              Text(
                isReview ? 'Hang tight.' : "You're verified.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle — "48 hours" bolded in review, "identity confirmed" in verified
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: t.dim,
                      height: 1.5,
                    ),
                    children: isReview
                        ? [
                            const TextSpan(
                              text:
                                  "We're reviewing your KYC documents. This usually takes up to ",
                            ),
                            TextSpan(
                              text: '48 hours',
                              style: TextStyle(
                                color: t.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ]
                        : const [
                            TextSpan(
                              text:
                                  'Your identity is confirmed and your verified badge is live on your profile.',
                            ),
                          ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3-step timeline. Done / active / pending states depend on
              // the card's state — verified = all three done; review =
              // first done, second active, third pending.
              _Timeline(
                t: t,
                accentActive: accent,
                isReview: isReview,
                submittedAtIso: submittedAtIso,
              ),
              const SizedBox(height: 18),

              // Progress bar with mono label above
              _ProgressBar(
                t: t,
                accent: accent,
                progress: progress,
                isReview: isReview,
              ),
              const SizedBox(height: 18),

              // Footer info strip — mail icon in review, badge in verified
              WizardTipChip(
                t: t,
                icon: isReview
                    ? Icons.mail_outline_rounded
                    : Icons.verified_rounded,
                iconColor: isReview ? t.dim : accent,
                body: Text(
                  isReview
                      ? "We'll ping you the moment it's done."
                      : 'Verified badge added to your profile.',
                  style: TextStyle(
                    fontSize: 12,
                    color: t.dim,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Auto-compute progress based on time elapsed vs the 48h review SLA.
  /// Verified always = 1.0; review starts at 0.15 (acknowledgement) and
  /// grows to 0.95 by the 48h mark.
  double _computeProgress() {
    if (state == KycCardState.verified) return 1.0;
    if (submittedAtIso == null) return 0.15;
    final dt = DateTime.tryParse(submittedAtIso!);
    if (dt == null) return 0.15;
    final elapsed = DateTime.now().difference(dt.toLocal());
    final fraction = (elapsed.inMinutes / (48 * 60)).clamp(0.0, 1.0);
    return (0.15 + fraction * 0.80).clamp(0.15, 0.95);
  }
}

// ─────────────────────────────────────────────────────────────────────
// _StatusBadge — pulsing dot + uppercase label. Amber in review, lime
// in verified. Uses TweenAnimationBuilder for the pulse to avoid
// requiring a TickerProvider on the parent.
// ─────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final WizardTokens t;
  final Color accent;
  final String label;

  const _StatusBadge({
    required this.t,
    required this.accent,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(color: accent, size: 6),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulsingDot({required this.color, required this.size});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        // 0..1 curve mapped to 0.35..1 so the dot never fully disappears
        opacity: 0.35 + 0.65 * _c.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// _RingIllustration — concentric rings + soft radial glow + centred
// icon. Only cosmetic; all colors are tinted from the state accent.
// ─────────────────────────────────────────────────────────────────────
class _RingIllustration extends StatelessWidget {
  final WizardTokens t;
  final Color accent;
  final IconData icon;

  const _RingIllustration({
    required this.t,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 3 concentric rings, fading as they get closer to centre.
          for (int i = 1; i <= 3; i++)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(i * 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withOpacity(0.18 - i * 0.04),
                    ),
                  ),
                ),
              ),
            ),
          // Radial glow core
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withOpacity(0.22),
                  accent.withOpacity(0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
                center: const Alignment(0, -0.3),
              ),
            ),
            child: Center(
              child: Icon(icon, size: 54, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// _Timeline — 3 rows, each a circle-state + vertical connector + text.
// ─────────────────────────────────────────────────────────────────────
class _Timeline extends StatelessWidget {
  final WizardTokens t;
  final Color accentActive;
  final bool isReview;
  final String? submittedAtIso;

  const _Timeline({
    required this.t,
    required this.accentActive,
    required this.isReview,
    required this.submittedAtIso,
  });

  @override
  Widget build(BuildContext context) {
    final submittedDisplay = _formatSubmitted(submittedAtIso);
    final etaDisplay = _formatEta(submittedAtIso);

    final rows = isReview
        ? [
            _TimelineRow(
              title: 'Documents received',
              subtitle: submittedDisplay,
              state: _StepState.done,
            ),
            _TimelineRow(
              title: 'Under manual review',
              subtitle: 'In progress',
              state: _StepState.active,
            ),
            _TimelineRow(
              title: 'Verification complete',
              subtitle: etaDisplay != null ? 'Est. by $etaDisplay' : 'Pending',
              state: _StepState.pending,
            ),
          ]
        : [
            _TimelineRow(
              title: 'Documents received',
              subtitle: submittedDisplay,
              state: _StepState.done,
            ),
            _TimelineRow(
              title: 'Review completed',
              subtitle: 'Approved',
              state: _StepState.done,
            ),
            _TimelineRow(
              title: 'Verification complete',
              subtitle: 'Badge live',
              state: _StepState.done,
            ),
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < rows.length; i++)
            _TimelineEntry(
              t: t,
              row: rows[i],
              isLast: i == rows.length - 1,
              doneColor: t.success,
              activeColor: accentActive,
            ),
        ],
      ),
    );
  }

  String _formatSubmitted(String? iso) {
    if (iso == null) return 'Today';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Today';
    final local = dt.toLocal();
    final now = DateTime.now();
    final isToday = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final isYesterday = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day - 1;
    final hh = local.hour;
    final mm = local.minute.toString().padLeft(2, '0');
    final ampm = hh >= 12 ? 'PM' : 'AM';
    final h12 = hh == 0 ? 12 : (hh > 12 ? hh - 12 : hh);
    final time = '$h12:$mm $ampm';
    if (isToday) return 'Today, $time';
    if (isYesterday) return 'Yesterday, $time';
    return '${local.day}/${local.month}, $time';
  }

  String? _formatEta(String? iso) {
    if (iso == null) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    final eta = dt.toLocal().add(const Duration(hours: 48));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[eta.month - 1]} ${eta.day}';
  }
}

enum _StepState { done, active, pending }

class _TimelineRow {
  final String title;
  final String subtitle;
  final _StepState state;
  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.state,
  });
}

class _TimelineEntry extends StatelessWidget {
  final WizardTokens t;
  final _TimelineRow row;
  final bool isLast;
  final Color doneColor;
  final Color activeColor;

  const _TimelineEntry({
    required this.t,
    required this.row,
    required this.isLast,
    required this.doneColor,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circle + vertical connector column.
          Column(
            children: [
              _buildDot(),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.only(top: 2),
                    color: t.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Text column. Bottom padding on non-last rows matches the
          // design mock's rhythm between entries.
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: row.state == _StepState.pending ? t.dim : t.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.subtitle,
                    style: TextStyle(fontSize: 11, color: t.dim2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    switch (row.state) {
      case _StepState.done:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: doneColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 13,
            color: t.onAccent,
          ),
        );
      case _StepState.active:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: activeColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: t.onAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case _StepState.pending:
        return Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: t.lineHi, width: 1.5),
          ),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// _ProgressBar — amber→cyan gradient while reviewing, full-green when
// verified. Monospace label above shows percentage + ETA.
// ─────────────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final WizardTokens t;
  final Color accent;
  final double progress;
  final bool isReview;

  const _ProgressBar({
    required this.t,
    required this.accent,
    required this.progress,
    required this.isReview,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    final hoursLeft = isReview ? ((48 * (1 - progress)).round()) : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isReview ? '$pct% reviewed' : '100% complete',
              style: wizardMonoStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: t.dim2,
                letterSpacing: 0,
              ),
            ),
            Text(
              isReview
                  ? '~${hoursLeft}h left'
                  : 'Verified',
              style: wizardMonoStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: t.dim2,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: t.line,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isReview
                      ? [t.warn, t.accent]
                      : [t.success, t.success],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
