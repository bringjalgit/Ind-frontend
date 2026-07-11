import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/services/AuthService.dart';
import 'package:classifieds/utils/constants.dart';

/// Shared "please log in" bottom-sheet for guest gates.
///
/// Every guest-gated action (chat, contact, sell, view-seller, profile/ads/
/// chat tabs) calls [showLoginRequiredSheet] with a tailored [message]. The
/// sheet remembers the route the user is on so the auth flow can return them
/// there after a successful login (via [AuthService.pendingRedirect]).
///
/// Navigation contract: tapping "Login / Register" does `context.push('/login')`
/// so the origin screen stays beneath the auth stack — if the user backs out
/// of login they return to where they were; if they complete it, the OTP /
/// Register success handler consumes `pendingRedirect` and `go()`s back here.
Future<void> showLoginRequiredSheet(
  BuildContext context, {
  required String message,
  String? redirect,
}) {
  // Capture where the user is now, so we can bring them back post-login.
  String? returnTo = redirect;
  if (returnTo == null) {
    try {
      returnTo = GoRouterState.of(context).uri.toString();
    } catch (_) {
      returnTo = null; // fall back to dashboard if route can't be resolved
    }
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LoginRequiredSheet(message: message, returnTo: returnTo),
  );
}

class _LoginRequiredSheet extends StatelessWidget {
  const _LoginRequiredSheet({required this.message, required this.returnTo});

  final String message;
  final String? returnTo;

  static const Color _brandBlue = Color(0xFF1677FF);
  static const Color _brandBlueDeep = Color(0xFF0F5FCE);

  void _goToLogin(BuildContext context) {
    // Remember where to come back to, close the sheet, then open login.
    AuthService.pendingRedirect = returnTo;
    Navigator.of(context).pop(); // close the sheet
    // Navigate on the ROOT navigator: the sheet's own BuildContext is
    // defunct right after pop(), so context.push() on it silently no-ops.
    final rootCtx = navigatorKey.currentContext;
    if (rootCtx != null) rootCtx.push('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF12141A);
    final mute = isDark ? Colors.white70 : const Color(0xFF8A8F99);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: mute.withOpacity(0.4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _brandBlue.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: _brandBlue, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Login required',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 22),
            // Primary CTA — Login / Register
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () => _goToLogin(context),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [_brandBlue, _brandBlueDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Login / Register',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe later',
                style: TextStyle(
                  color: mute,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
