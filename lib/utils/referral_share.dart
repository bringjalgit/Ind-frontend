import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import 'package:classifieds/model/ReferralModels.dart';
import 'package:classifieds/presentation/views/ReferralShareCard.dart';
import 'package:classifieds/utils/AppLogger.dart';

/// Re-entrancy guard so a double-tap on Share can't spawn two share sheets.
bool _sharing = false;

/// Shares the referral invite as a branded image + message. Renders
/// [ReferralShareCard] to a PNG off-screen and attaches it alongside the
/// server-provided [ReferralInfo.shareText]. If image rendering fails for any
/// reason, it degrades gracefully to a plain text share — sharing must never
/// hard-fail for the user.
Future<void> shareReferralInvite({
  required BuildContext context,
  required ReferralInfo info,
}) async {
  if (_sharing) return;
  _sharing = true;

  final code = (info.code ?? '').trim();
  // Server owns the copy (editable without an app release). Fall back sensibly
  // if an older backend didn't send share_text.
  final message = (info.shareText != null && info.shareText!.trim().isNotEmpty)
      ? info.shareText!
      : (info.shareLink != null && info.shareLink!.trim().isNotEmpty)
          ? info.shareLink!
          : 'Join me on IND Classifieds with my code $code';

  try {
    // Decode the logo before the off-screen paint so it isn't blank.
    await precacheImage(
      const AssetImage('assets/images/applogonew.png'),
      context,
    );

    // No `context:` — the card is self-contained (Directionality + Material +
    // explicit styles) and the size is fixed via targetSize, so we avoid using
    // a BuildContext across the await above.
    final bytes = await ScreenshotController().captureFromWidget(
      ReferralShareCard(code: code.isEmpty ? '—' : code),
      pixelRatio: 3,
      targetSize: const Size(400, 500),
      delay: const Duration(milliseconds: 80),
    );

    final dir = await getTemporaryDirectory();
    final safeCode = code.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final file = File('${dir.path}/ind_invite_$safeCode.png');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: message,
        subject: 'Join me on IND Classifieds',
      ),
    );
  } catch (e) {
    AppLogger.error('referral image share failed, text-only fallback: $e');
    try {
      await SharePlus.instance.share(ShareParams(text: message));
    } catch (_) {}
  } finally {
    _sharing = false;
  }
}
