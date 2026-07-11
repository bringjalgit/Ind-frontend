import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:classifieds/theme/app_colors.dart';

import '../theme/AppTextStyles.dart';
import '../theme/ThemeHelper.dart';
import 'PlanTierBadge.dart';

class SimilarProductCard extends StatelessWidget {
  final String title;
  final String price;
  final String location;
  final String? imageUrl;
  final bool isLiked;
  final bool isFeatured;
  final VoidCallback onLikeToggle;
  final VoidCallback onTap;
  final Color borderColor;
  /// Plan tier of the seller's active subscription stamped on this
  /// listing (`"essential"` / `"power"` / `"pro"`). Null on free posts.
  /// Renders [PlanTierBadge] over the image's bottom-left corner.
  final String? planTier;

  const SimilarProductCard({
    super.key,
    required this.title,
    required this.price,
    required this.location,
    required this.imageUrl,
    required this.isLiked,
    required this.isFeatured,
    required this.onLikeToggle,
    required this.onTap,
    required this.borderColor,
    this.planTier,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final cardColor = ThemeHelper.cardColor(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image + like
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: (imageUrl == null || imageUrl!.isEmpty)
                      ? Container(
                          color: borderColor.withOpacity(.2),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: textColor.withOpacity(.6),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) => Container(
                              color: borderColor.withOpacity(.2),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: borderColor.withOpacity(.2),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey.withOpacity(.6),
                              ),
                            ),
                          ),
                        ),
                ),
                // Top-left corner ribbon. PlanTierBadge picks the
                // single tag based on priority: Power Seller → Pro →
                // Featured → none. Power Seller suppresses Featured
                // so the card shows the gold tag only.
                Positioned(
                  top: 0,
                  left: 0,
                  child: PlanTierBadge(
                    tier: planTier,
                    isFeatured: isFeatured,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: onLikeToggle,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isLiked ? Colors.redAccent : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium(
                  textColor,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Text(
                price,
                style: AppTextStyles.bodyMedium(
                  Colors.blue,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Row(
                children: [
                  Icon(Icons.place, size: 14, color: textColor.withOpacity(.6)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location.isEmpty ? "—" : location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(textColor.withOpacity(.7)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
