import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:classifieds/services/AppConfigService.dart';
import 'package:classifieds/theme/ThemeHelper.dart';

class AnnouncementDialog {
  /// Show announcement popup if active and not dismissed
  static Future<void> showIfNeeded(BuildContext context) async {
    final announcement = AppConfigService.announcement;
    if (!announcement.isActive) return;
    if (announcement.title == null && announcement.message == null) return;

    final dismissed = await AppConfigService.isAnnouncementDismissed();
    if (dismissed) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final textColor = ThemeHelper.textColor(ctx);
        final bgColor = ThemeHelper.cardColor(ctx);

        return Dialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      AppConfigService.dismissAnnouncement();
                      Navigator.pop(ctx);
                    },
                    child: Icon(Icons.close, color: textColor.withOpacity(0.5), size: 22),
                  ),
                ),
                // Image
                if (announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: announcement.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Title
                if (announcement.title != null)
                  Text(
                    announcement.title!,
                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                if (announcement.message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    announcement.message!,
                    style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                // Action button
                if (announcement.actionUrl != null && announcement.actionUrl!.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        AppConfigService.dismissAnnouncement();
                        Navigator.pop(ctx);
                        context.push(announcement.actionUrl!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Learn More', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
