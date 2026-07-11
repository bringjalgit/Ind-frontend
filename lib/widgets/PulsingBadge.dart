import 'package:flutter/material.dart';

/// A red unread-count badge that **gently pulses** (soft scale + glow) to draw
/// the eye without a harsh on/off flash. Self-animating — drop it anywhere.
/// Renders nothing when [count] <= 0, so it's safe to place unconditionally.
///
/// Used for unread chat conversations (chat list) and the chat-tab badge so
/// the seller notices new/unread messages from any screen.
class PulsingBadge extends StatefulWidget {
  final int count;
  final double minSize;
  final double fontSize;
  const PulsingBadge({
    super.key,
    required this.count,
    this.minSize = 22,
    this.fontSize = 11,
  });

  @override
  State<PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<PulsingBadge>
    with SingleTickerProviderStateMixin {
  static const Color _red = Color(0xFFEF4444);
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 1.0, end: 1.14).animate(curve);
    _glow = Tween<double>(begin: 0.15, end: 0.5).animate(curve);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            constraints:
                BoxConstraints(minWidth: widget.minSize, minHeight: widget.minSize),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.circular(widget.minSize / 2),
              boxShadow: [
                BoxShadow(
                  color: _red.withValues(alpha: _glow.value),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.count > 99 ? '99+' : '${widget.count}',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
