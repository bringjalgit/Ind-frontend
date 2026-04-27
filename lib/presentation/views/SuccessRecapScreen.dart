import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/cubit/MyAds/my_ads_cubit.dart';
import '../../theme/ThemeHelper.dart';

enum SuccessVariant { posted, updated, boost }

class SuccessRecapData {
  final SuccessVariant variant;

  // Listing fields (posted / updated)
  final String? listingTitle;
  final String? listingPrice;
  final String? listingCategory;
  final String? planName;
  final int? durationDays;
  final String? listingId;

  // Boost fields
  final String? boostAmount;
  final String? boostDescription;

  const SuccessRecapData({
    required this.variant,
    this.listingTitle,
    this.listingPrice,
    this.listingCategory,
    this.planName,
    this.durationDays,
    this.listingId,
    this.boostAmount,
    this.boostDescription,
  });

  const SuccessRecapData.posted({
    String? listingTitle,
    String? listingPrice,
    String? listingCategory,
    String? planName,
    int? durationDays,
    String? listingId,
  }) : this(
          variant: SuccessVariant.posted,
          listingTitle: listingTitle,
          listingPrice: listingPrice,
          listingCategory: listingCategory,
          planName: planName,
          durationDays: durationDays,
          listingId: listingId,
        );

  const SuccessRecapData.updated({
    String? listingTitle,
    String? listingCategory,
    String? listingId,
  }) : this(
          variant: SuccessVariant.updated,
          listingTitle: listingTitle,
          listingCategory: listingCategory,
          listingId: listingId,
        );

  const SuccessRecapData.boost({
    String? boostAmount,
    String? boostDescription,
    String? listingId,
    String? listingTitle,
  }) : this(
          variant: SuccessVariant.boost,
          boostAmount: boostAmount,
          boostDescription: boostDescription,
          listingId: listingId,
          listingTitle: listingTitle,
        );
}

class SuccessRecapScreen extends StatelessWidget {
  final SuccessRecapData data;
  const SuccessRecapScreen({super.key, required this.data});

  String _formatINR(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return raw;
    final n = int.tryParse(cleaned);
    if (n == null) return raw;
    final s = n.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final restFormatted = rest.replaceAllMapped(
      RegExp(r'(\d)(?=(\d\d)+$)'),
      (m) => '${m[1]},',
    );
    return '$restFormatted,$last3';
  }

  String _expiryDate(int? days) {
    if (days == null || days <= 0) return '';
    final d = DateTime.now().add(Duration(days: days));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = ThemeHelper.backgroundColor(context);
    final text = ThemeHelper.textColor(context);
    final card = isDark ? const Color(0xFF1A2332) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final muted = text.withOpacity(0.6);
    const cyan = Color(0xFF06B6D4);
    const green = Color(0xFF22C55E);

    final isBoost = data.variant == SuccessVariant.boost;
    final isUpdated = data.variant == SuccessVariant.updated;

    final heroColor = isBoost ? cyan : green;
    final heroIcon = isBoost ? Icons.flash_on_rounded : Icons.check_rounded;

    final title = isBoost
        ? 'Boost activated!'
        : isUpdated
            ? 'Add updated'
            : 'Your Add is live!';

    final subtitle = isBoost  
        ? 'Your listing now appears at the top of search'
        : isUpdated
            ? (data.listingTitle?.isNotEmpty == true
                ? data.listingTitle!
                : 'Changes are now live')
            : (data.listingTitle?.isNotEmpty == true
                ? data.listingTitle!
                : 'It is now visible to buyers');

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(child: _ScalePop(child: _Hero(color: heroColor, icon: heroIcon))),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: muted, height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RecapCard(
                        data: data,
                        cardColor: card,
                        borderColor: border,
                        textColor: text,
                        mutedColor: muted,
                        formatINR: _formatINR,
                        expiryDate: _expiryDate,
                      ),
                      const SizedBox(height: 16),
                      _NextSection(
                        variant: data.variant,
                        cyan: cyan,
                        textColor: text,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Actions(
                data: data,
                cyan: cyan,
                textColor: text,
                borderColor: border,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _Hero({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 44),
    );
  }
}

class _ScalePop extends StatefulWidget {
  final Widget child;
  const _ScalePop({required this.child});

  @override
  State<_ScalePop> createState() => _ScalePopState();
}

class _ScalePopState extends State<_ScalePop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

class _RecapCard extends StatelessWidget {
  final SuccessRecapData data;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final String Function(String?) formatINR;
  final String Function(int?) expiryDate;

  const _RecapCard({
    required this.data,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.formatINR,
    required this.expiryDate,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <_Row>[];

    if (data.variant == SuccessVariant.boost) {
      if (data.boostAmount != null && data.boostAmount!.isNotEmpty) {
        rows.add(_Row(
          'Amount paid',
          '₹${formatINR(data.boostAmount)}',
          highlight: true,
        ));
      }
      if (data.boostDescription != null && data.boostDescription!.isNotEmpty) {
        rows.add(_Row('Plan', data.boostDescription!));
      }
      rows.add(const _Row('Status', 'Active', highlight: true));
    } else {
      if (data.listingTitle != null && data.listingTitle!.isNotEmpty) {
        rows.add(_Row('Listing', data.listingTitle!));
      }
      if (data.listingPrice != null && data.listingPrice!.isNotEmpty) {
        rows.add(_Row(
          'Price',
          '₹${formatINR(data.listingPrice)}',
          highlight: true,
        ));
      }
      if (data.listingCategory != null && data.listingCategory!.isNotEmpty) {
        rows.add(_Row('Category', data.listingCategory!));
      }
      if (data.variant == SuccessVariant.posted) {
        if (data.planName != null && data.planName!.isNotEmpty) {
          rows.add(_Row('Plan', data.planName!));
        }
        final exp = expiryDate(data.durationDays);
        if (exp.isNotEmpty) {
          rows.add(_Row('Expires', exp));
        }
      } else {
        rows.add(const _Row('Updated', 'Just now'));
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 16, color: borderColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    rows[i].label,
                    style: TextStyle(fontSize: 13, color: mutedColor),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    rows[i].value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: rows[i].highlight
                          ? const Color(0xFF16A34A)
                          : textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;
  final bool highlight;
  const _Row(this.label, this.value, {this.highlight = false});
}

class _NextSection extends StatelessWidget {
  final SuccessVariant variant;
  final Color cyan;
  final Color textColor;
  final bool isDark;

  const _NextSection({
    required this.variant,
    required this.cyan,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> bullets;
    final String title;
    switch (variant) {
      case SuccessVariant.posted:
        title = 'What happens next';
        bullets = [
          'Your ad shows on the home feed instantly',
          'Buyers can chat or call you directly',
          'Boost to top of search for more visibility',
        ];
        break;
      case SuccessVariant.updated:
        title = "What's changed";
        bullets = [
          'Buyers see the updated details right away',
          'Existing chats keep their full history',
          'Old offers remain valid until you decide',
        ];
        break;
      case SuccessVariant.boost:
        title = 'What happens next';
        bullets = [
          'Your listing pinned at the top of search',
          'More views, faster replies from buyers',
          'Track impressions in My Ads → Analytics',
        ];
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: cyan.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: cyan, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: cyan,
            ),
          ),
          const SizedBox(height: 8),
          for (final b in bullets) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 8),
                    child: Icon(Icons.arrow_forward_rounded, size: 14, color: cyan),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: textColor.withOpacity(0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final SuccessRecapData data;
  final Color cyan;
  final Color textColor;
  final Color borderColor;

  const _Actions({
    required this.data,
    required this.cyan,
    required this.textColor,
    required this.borderColor,
  });

  void _share(BuildContext context) {
    final title = data.listingTitle ?? 'my listing';
    final price = data.listingPrice ?? '';
    final priceStr = price.isNotEmpty ? ' for ₹$price' : '';
    Share.share('Check out $title$priceStr on IndClassifieds');
  }

  void _goHome(BuildContext context) {
    // Dashboard tab 0 = HoliHomeScreen (Home).
    context.go('/dashboard?tab=0');
  }

  void _goMyAds(BuildContext context) {
    // Refresh approved listings before showing the My Ads tab so the
    // newly-posted / updated / boosted listing is visible immediately.
    try {
      context.read<MyAdsCubit>().getMyAds('approved');
    } catch (_) {
      // Cubit isn't in scope — non-fatal; AdsScreen also fetches on
      // its own when the tab is opened.
    }
    // Dashboard tab 1 = AdsScreen (My Ads).
    context.go('/dashboard?tab=1');
  }

  @override
  Widget build(BuildContext context) {
    final isBoost = data.variant == SuccessVariant.boost;
    final isUpdated = data.variant == SuccessVariant.updated;

    final primaryLabel = isBoost
        ? 'View My Ads'
        : isUpdated
            ? 'View My Ads'
            : 'View My Ads';
    final primaryAction = () => _goMyAds(context);

    final secondaryLabel = isBoost
        ? 'Back to home'
        : isUpdated
            ? 'Back to home'
            : 'Share';
    final secondaryAction = () {
      if (isBoost || isUpdated) {
        _goHome(context);
      } else {
        _share(context);
      }
    };

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: primaryAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: cyan,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              primaryLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: secondaryAction,
            icon: Icon(
              isBoost || isUpdated ? Icons.home_outlined : Icons.share_outlined,
              size: 18,
              color: textColor.withOpacity(0.8),
            ),
            label: Text(
              secondaryLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.8),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
