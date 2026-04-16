import 'package:flutter/material.dart';

/// Small inline verified-identity badge. Rendered next to a user's
/// display name anywhere the UI needs to surface Aadhaar-approved
/// status. Color + icon are centralized here so a future style change
/// (e.g. swap to a custom SVG) is a one-file edit.
class VerifiedBadge extends StatelessWidget {
  final double size;
  final Color color;

  const VerifiedBadge({
    super.key,
    this.size = 16,
    this.color = const Color(0xFF1DA1F2), // Twitter-ish blue
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Identity verified',
      child: Icon(Icons.verified, size: size, color: color),
    );
  }
}
