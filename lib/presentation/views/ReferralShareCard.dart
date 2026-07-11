import 'package:flutter/material.dart';

/// The branded referral image that gets rendered to a PNG and attached to the
/// share sheet (WhatsApp, etc.). Fixed 400×500 canvas so the exported image is
/// always the same crisp size regardless of the device. Self-contained
/// (Directionality + Material + explicit text styles) so it renders correctly
/// when captured off-screen via `ScreenshotController.captureFromWidget`.
class ReferralShareCard extends StatelessWidget {
  final String code;
  const ReferralShareCard({super.key, required this.code});

  // Brand palette (kept literal — this is a fixed-look export, not theme-aware).
  static const _ink = Color(0xFF191A22);
  static const _muted = Color(0xFF6A6B76);
  static const _orange = Color(0xFFC9530F);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: 400,
          height: 500,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF6F0), Color(0xFFFFFFFF), Color(0xFFF1F7FF)],
                stops: [0.0, 0.46, 1.0],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEFE7DE)),
            ),
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/applogonew.png', height: 40),
                const SizedBox(height: 20),
                const Text(
                  "YOU'RE INVITED",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.6,
                    color: _orange,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Buy. Sell. Earn.',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "India's local Buy • Sell • Marketplace",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _muted, height: 1.35),
                ),
                const SizedBox(height: 20),
                _ticket(),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _chip('+5 points for you',
                        fg: const Color(0xFF1F7A45),
                        bg: const Color(0xFFF2FBF5),
                        border: const Color(0xFFBFE6CD)),
                    const SizedBox(width: 8),
                    _chip('Free listings',
                        fg: const Color(0xFF3F4048),
                        bg: Colors.white,
                        border: const Color(0xFFE6DDD4)),
                  ],
                ),
                const SizedBox(height: 20),
                _storeBadges(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ticket() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0894F), width: 1.6),
      ),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      child: Column(
        children: [
          const Text(
            'YOUR REFERRAL CODE',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
              color: _orange,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label,
      {required Color fg, required Color bg, required Color border}) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  /// Two official-style store badges side by side (real Apple + Google Play
  /// logos) — the standard "available on both stores" presentation.
  Widget _storeBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _badge(
          logo: const Icon(Icons.apple, color: Colors.white, size: 21),
          line1: 'Download on the',
          line2: 'App Store',
        ),
        const SizedBox(width: 10),
        _badge(
          logo: const _PlayStoreLogo(size: 18),
          line1: 'GET IT ON',
          line2: 'Google Play',
        ),
      ],
    );
  }

  Widget _badge({
    required Widget logo,
    required String line1,
    required String line2,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFA6A6A6), width: 0.8),
      ),
      padding: const EdgeInsets.fromLTRB(11, 7, 13, 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          logo,
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                line2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The Google Play triangle mark, drawn as four coloured facets (Material
/// icons don't include the multi-colour Play logo). Sized square.
class _PlayStoreLogo extends StatelessWidget {
  final double size;
  const _PlayStoreLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _PlayLogoPainter());
  }
}

class _PlayLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final a = Offset(s * 0.14, s * 0.08); // top-left
    final b = Offset(s * 0.14, s * 0.92); // bottom-left
    final lc = Offset(s * 0.14, s * 0.50); // left-centre
    final f = Offset(s * 0.54, s * 0.50); // fold (on the mid-line)
    final t = Offset(s * 0.92, s * 0.50); // right tip

    void tri(Offset p1, Offset p2, Offset p3, Color c) {
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = c..isAntiAlias = true);
    }

    tri(a, lc, f, const Color(0xFF00A1FF)); // blue   — top-left
    tri(b, lc, f, const Color(0xFFFF3A44)); // red    — bottom-left
    tri(a, f, t, const Color(0xFFFFC500)); // yellow — top tip
    tri(b, f, t, const Color(0xFF00C853)); // green  — bottom tip
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
