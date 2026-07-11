import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Decides what happens when a link inside a bundled legal WebView document
/// (Terms / Privacy / Payment) is tapped.
///
/// The documents are loaded from Flutter assets, i.e. from a
/// `file:///android_asset/flutter_assets/...` URL. Any *other* navigation
/// target is an `<a href>` the user tapped inside the document. Left to the
/// WebView these fail — `mailto:` throws `ERR_UNKNOWN_URL_SCHEME`, and an
/// in-page `href="/privacy"` resolves against the file:// base to
/// `file:///privacy` → `ERR_ACCESS_DENIED` (the "Webpage not available"
/// screens). So we intercept every navigation:
///   • the bundled document itself (and about:blank) loads in the WebView
///   • mailto:/tel:/sms:/http(s) are handed to the OS (mail app, dialer, browser)
///   • in-app cross-links (/privacy, /terms, /payment-policy) route via GoRouter
///   • anything else is swallowed so the WebView never shows an error page
Future<NavigationDecision> handleLegalLinkTap(
  NavigationRequest request,
  BuildContext context,
) async {
  final url = request.url;

  // Let the bundled document (and blank pages) load in the WebView as normal.
  if (url.startsWith('file:///android_asset') || url.startsWith('about:')) {
    return NavigationDecision.navigate;
  }

  final uri = Uri.tryParse(url);
  if (uri == null) return NavigationDecision.prevent;

  // In-app cross-references. A `/privacy` href resolves against the file://
  // base to `file:///privacy`, so match on the trailing path segment.
  final path = uri.path;
  final inAppRoute = path.endsWith('/privacy')
      ? '/privacy'
      : path.endsWith('/terms')
          ? '/terms'
          : path.endsWith('/payment-policy')
              ? '/payment-policy'
              : null;
  if (inAppRoute != null) {
    if (context.mounted) context.push(inAppRoute);
    return NavigationDecision.prevent;
  }

  // External schemes → open in the OS handler instead of the WebView.
  if (uri.scheme == 'mailto' ||
      uri.scheme == 'tel' ||
      uri.scheme == 'sms' ||
      uri.scheme == 'http' ||
      uri.scheme == 'https') {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // No handler app installed — ignore rather than crash.
    }
    return NavigationDecision.prevent;
  }

  // Unknown/unsupported target — never let the WebView render an error page.
  return NavigationDecision.prevent;
}
