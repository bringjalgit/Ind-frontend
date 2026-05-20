import 'package:flutter/material.dart';

/// Color tokens + shared widgets for the SWA activation wizard
/// (Set Price Range → Availability → Chat Mode).
///
/// Implements the "A · Refined Dark" design direction adapted so each
/// token resolves differently in light vs dark mode:
///   • dark: warm-black base (#0B0B0F), electric cyan accent (#6CE3FF),
///           lime success (#A8F57A), Inter + monospace for numerics
///   • light: ivory base, deeper cyan accent for contrast, same lime/amber
///
/// Callers pass `isDark` once and pull tokens from the returned
/// WizardTokens record. All widgets below take a WizardTokens instance
/// so they don't re-resolve on every rebuild.
class WizardTokens {
  final Color bg;
  final Color surface;
  final Color surfaceHi;
  final Color line;
  final Color lineHi;
  final Color text;
  final Color dim;   // 62% text
  final Color dim2;  // 42% text
  final Color accent;
  final Color success;
  final Color warn;
  final Color danger;
  final Color onAccent; // text colour that sits on top of `accent`

  const WizardTokens({
    required this.bg,
    required this.surface,
    required this.surfaceHi,
    required this.line,
    required this.lineHi,
    required this.text,
    required this.dim,
    required this.dim2,
    required this.accent,
    required this.success,
    required this.warn,
    required this.danger,
    required this.onAccent,
  });

  factory WizardTokens.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const WizardTokens(
        bg: Color(0xFF0B0B0F),
        surface: Color(0xFF15151B),
        surfaceHi: Color(0xFF1D1D25),
        line: Color(0x14FFFFFF),    // rgba(255,255,255,0.08)
        lineHi: Color(0x24FFFFFF),  // rgba(255,255,255,0.14)
        text: Color(0xFFF4F3F0),
        dim: Color(0x9EF4F3F0),     // 62%
        dim2: Color(0x6BF4F3F0),    // 42%
        accent: Color(0xFF6CE3FF),
        success: Color(0xFFA8F57A),
        warn: Color(0xFFFFB26C),
        danger: Color(0xFFFF7E7E),
        onAccent: Color(0xFF0B0B0F),
      );
    }
    // Light variant — same design language, invert surfaces, deepen the
    // accent so it reads cleanly on ivory. Success/warn/danger stay warm
    // but get darker so they hit AA contrast on white.
    return const WizardTokens(
      bg: Color(0xFFFBFAF6),
      surface: Color(0xFFFFFFFF),
      surfaceHi: Color(0xFFF3F1EC),
      line: Color(0x14000000),
      lineHi: Color(0x24000000),
      text: Color(0xFF0F1014),
      dim: Color(0x9E0F1014),
      dim2: Color(0x6B0F1014),
      accent: Color(0xFF0096B8),   // deeper cyan for contrast on ivory
      success: Color(0xFF3F9A1B),  // deeper lime
      warn: Color(0xFFC6751A),
      danger: Color(0xFFB32424),
      onAccent: Color(0xFFFFFFFF),
    );
  }
}

/// Step progress bar + mini-header ("02 · AVAILABILITY   02 / 03")
/// + big editorial title with optional subtitle. Reused on all 3
/// wizard steps so the visual beat stays identical step-to-step.
class WizardStepHeader extends StatelessWidget {
  final WizardTokens t;
  final int step; // 1-based: 1, 2, 3
  final int totalSteps;
  final String eyebrow; // "01 · PRICING"
  final String title; // editorial — may include "\n" for line break
  final String? subtitle;

  const WizardStepHeader({
    super.key,
    required this.t,
    required this.step,
    required this.totalSteps,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3-bar progress indicator — filled bars use the accent.
        Row(
          children: List.generate(totalSteps, (i) {
            final isActive = i < step;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
                height: 3,
                decoration: BoxDecoration(
                  color: isActive ? t.accent : t.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              eyebrow,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: t.accent,
              ),
            ),
            const Spacer(),
            Text(
              '${step.toString().padLeft(2, '0')} / ${totalSteps.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 11, color: t.dim2),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 1.15,
            color: t.text,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 13, color: t.dim, height: 1.5),
          ),
        ],
      ],
    );
  }
}

/// Primary accent-filled CTA button. Matches the APrimary component
/// from the design mock — full-width, pill-free (14px radius), with
/// optional leading icon.
class WizardPrimaryButton extends StatelessWidget {
  final WizardTokens t;
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? background;

  const WizardPrimaryButton({
    super.key,
    required this.t,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? t.accent;
    final fg = t.onAccent;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withOpacity(0.5),
          elevation: 0,
          // 2026-05-17 — pill shape (radius 28 = half of 56 height) so
          // the wizard CTAs match the rounded primary-button language
          // used on Login + OTP + Register.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          shadowColor: Colors.transparent,
        ),
        child: loading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    // 2026-05-17 v2 — bumped to 19/w900 + tiny positive
                    // tracking so the CTA reads bold on light cyan /
                    // lime backgrounds (low-contrast surfaces need more
                    // weight to feel substantial). 17/w800 was getting
                    // visually swallowed by the bg colour.
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                      color: fg,
                      height: 1.0,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 10),
                    Icon(icon, size: 22, color: fg),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Small info strip at the bottom of each wizard step — bulb icon +
/// soft-tinted bg + subtle border. Used for "Offers ≥ target auto-
/// accept" / "More slots = faster deals" / etc.
class WizardTipChip extends StatelessWidget {
  final WizardTokens t;
  final IconData icon;
  final Color iconColor;
  final Widget body;
  final Color? bg;
  final Color? border;

  const WizardTipChip({
    super.key,
    required this.t,
    required this.icon,
    required this.iconColor,
    required this.body,
    this.bg,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg ?? t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border ?? t.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Monospace text style used for numerals (prices, day counts, ranges).
/// Falls back to the platform's native monospace if RobotoMono isn't
/// bundled — consistent with how iOS and Android render numeric data.
TextStyle wizardMonoStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w700,
  Color? color,
  double letterSpacing = -0.4,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    color: color,
    fontFamily: 'monospace',
    fontFamilyFallback: const ['RobotoMono', 'Menlo', 'Courier New'],
  );
}
