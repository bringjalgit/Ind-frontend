import 'dart:async';
import 'package:flutter/material.dart';

/// Mixin that drives a rate-limit countdown from a [DateTime] end-time.
///
/// Used by onboarding screens (LoginScreen / EmailLoginscreen / OTPScreen) to
/// display "Try again in N min Ss" and keep primary action buttons disabled
/// for the entire window returned by the backend's 429 RATE_LIMITED response.
///
/// Pattern:
///   - On 429, call [startRateLimit] with the number of seconds from the
///     backend's `retry_after_sec` field.
///   - While `rateLimitRemaining > 0`, the screen shows [rateLimitMessage]
///     and disables its CTA (wrap the button's onPressed with `if
///     (rateLimitRemaining > 0) return;` or use `rateLimitRemaining > 0`
///     as the isLoading/disabled hint).
///   - When it hits zero, the timer cancels and the screen re-enables.
mixin RateLimitCountdownMixin<T extends StatefulWidget> on State<T> {
  Timer? _rateLimitTicker;
  int _rateLimitRemaining = 0;

  int get rateLimitRemaining => _rateLimitRemaining;
  bool get isRateLimited => _rateLimitRemaining > 0;

  /// Format the remaining seconds as "2m 30s" for display. Returns empty
  /// string when not rate-limited.
  String get rateLimitMessage {
    if (_rateLimitRemaining <= 0) return '';
    final m = _rateLimitRemaining ~/ 60;
    final s = _rateLimitRemaining % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  /// Start / restart the countdown. Pass the raw seconds from the backend's
  /// `retry_after_sec`. Safe to call repeatedly — resets the timer cleanly.
  void startRateLimit(int seconds) {
    _rateLimitTicker?.cancel();
    if (seconds <= 0) {
      setState(() => _rateLimitRemaining = 0);
      return;
    }
    setState(() => _rateLimitRemaining = seconds);
    _rateLimitTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = _rateLimitRemaining - 1;
      if (next <= 0) {
        timer.cancel();
        setState(() => _rateLimitRemaining = 0);
      } else {
        setState(() => _rateLimitRemaining = next);
      }
    });
  }

  /// Clear the countdown (e.g. on successful resend).
  void clearRateLimit() {
    _rateLimitTicker?.cancel();
    if (mounted) setState(() => _rateLimitRemaining = 0);
  }

  @override
  void dispose() {
    _rateLimitTicker?.cancel();
    super.dispose();
  }
}
