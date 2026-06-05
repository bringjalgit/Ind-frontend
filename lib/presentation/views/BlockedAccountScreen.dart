import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';


class BlockedAccountScreen extends StatelessWidget {
  const BlockedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = ThemeHelper.backgroundColor(context);
    final text = ThemeHelper.textColor(context);
    final card = ThemeHelper.cardColor(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            // subtle decorative blobs (static)
            Positioned(
              top: -60,
              left: -40,
              child: _Blob(size: 180, opacity: 0.06, color: primary),
            ),
            Positioned(
              bottom: -80,
              right: -30,
              child: _Blob(size: 220, opacity: 0.05, color: primary),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: primary.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.report_rounded, size: 18, color: primary),
                            const SizedBox(width: 8),
                            Text(
                              "Account Blocked",
                              style: AppTextStyles.labelLarge(primary).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Cute lock avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: card,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(color: primary.withOpacity(0.10)),
                        ),
                        child: Icon(Icons.lock_rounded, size: 48, color: primary),
                      ),
                      const SizedBox(height: 18),

                      Text(
                        "We’ve Temporarily Restricted Access",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headlineLarge(text).copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        "For your safety, this account is currently blocked. "
                            "This can happen due to unusual activity or a policy concern. "
                            "You can review the details below and reach our team to get back in.",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium(text).copyWith(
                          color: text.withOpacity(0.80),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Info card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primary.withOpacity(0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RowIconText(
                              icon: Icons.shield_moon_rounded,
                              title: "Why this happened",
                              desc: "We noticed activity that might violate our safety or usage policies.",
                              text: text,
                              primary: primary,
                            ),
                            const SizedBox(height: 14),
                            _RowIconText(
                              icon: Icons.check_circle_rounded,
                              title: "How to fix it",
                              desc: "Verify ownership and submit a short appeal. Our team will quickly review it.",
                              text: text,
                              primary: primary,
                            ),
                            const SizedBox(height: 14),
                            _RowIconText(
                              icon: Icons.schedule_rounded,
                              title: "Typical review time",
                              desc: "Most reviews are completed within 24–48 hours on business days.",
                              text: text,
                              primary: primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: () {
                          context.go("/login");
                        },
                        child: Text(
                          "Back to Login",
                          style: AppTextStyles.bodyMedium(text).copyWith(
                            decoration: TextDecoration.underline,
                            color: text.withOpacity(0.9),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      // tiny footnote
                      Text(
                        "Note: If this was a mistake, our support team will help you restore access after a quick review.",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelMedium(text.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowIconText extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color text;
  final Color primary;

  const _RowIconText({
    required this.icon,
    required this.title,
    required this.desc,
    required this.text,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primary.withOpacity(0.18)),
          ),
          child: Icon(icon, size: 20, color: primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.titleMedium(text).copyWith(
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 4),
              Text(
                desc,
                style: AppTextStyles.bodyMedium(text).copyWith(
                  color: text.withOpacity(0.78),
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final double opacity;
  final Color color;

  const _Blob({required this.size, required this.opacity, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity),
              Colors.transparent,
            ],
            stops: const [0.0, 1.0],
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
