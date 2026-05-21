import 'package:flutter/material.dart';

import '../theme/AppTextStyles.dart';
import '../theme/app_colors.dart';

/// Single corner-ribbon decision point for paid-plan badges and the
/// ₹50 Boost "FEATURED" tag.
///
/// Priority — at most ONE ribbon ever renders in the top-left:
///   • Power Seller (`plan_tier == 'power'`) → gold ribbon
///   • Pro          (`plan_tier == 'pro'`)   → purple/blue ribbon
///   • Featured     (`isFeatured == true`)   → blue ribbon
///   • else                                   → SizedBox.shrink
///
/// Essential listings get no badge — Essential users who want the
/// FEATURED tag still buy the ₹50 Boost separately. Power Seller's
/// "Auto Boost" promise stamps `featured_status = true` on every
/// listing at creation, but the gold POWER SELLER ribbon suppresses
/// the FEATURED ribbon so the card stays visually clean (one corner
/// tag, not two).
///
/// Shape/position match the existing FEATURED ribbon: top-left
/// rounded rectangle, white bold text on a colored fill. Use this
/// widget anywhere a listing card needs to surface its tier.
class PlanTierBadge extends StatelessWidget {
  final String? tier;
  final bool isFeatured;
  const PlanTierBadge({super.key, this.tier, this.isFeatured = false});

  @override
  Widget build(BuildContext context) {
    final spec = _PlanRibbonSpec.resolve(tier: tier, isFeatured: isFeatured);
    if (spec == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: spec.solid,
        gradient: spec.gradient,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(12),
          topLeft: Radius.circular(12),
        ),
      ),
      child: Text(
        spec.label,
        style: AppTextStyles.bodySmall(Colors.white)
            .copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PlanRibbonSpec {
  final String label;
  final Color? solid;
  final Gradient? gradient;
  const _PlanRibbonSpec({required this.label, this.solid, this.gradient});

  static _PlanRibbonSpec? resolve({String? tier, bool isFeatured = false}) {
    switch (tier?.toLowerCase()) {
      case 'power':
        return const _PlanRibbonSpec(
          label: 'Power Seller',
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
        );
      case 'pro':
        return const _PlanRibbonSpec(
          label: 'Pro',
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C3AED),
              Color(0xFF4F46E5),
              Color(0xFF0EA5E9),
            ],
          ),
        );
      // Essential listings are intentionally NOT badged. They keep the
      // baseline experience (no ribbon); upgrading is what unlocks the
      // gold POWER SELLER tag.
      default:
        if (isFeatured) {
          return _PlanRibbonSpec(label: 'Featured', solid: AppColors.primary);
        }
        return null;
    }
  }
}
