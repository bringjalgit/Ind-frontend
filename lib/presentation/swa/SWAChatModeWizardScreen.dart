import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/services/ApiClient.dart';
import 'package:classifieds/services/api_endpoint_urls.dart';
import 'package:classifieds/data/cubit/MyAds/my_ads_cubit.dart';
import 'widgets/wizard_theme.dart';
import 'widgets/SwaActivatedSheet.dart';

/// S4 — SWA Wizard Step 3: Chat Mode + Activate.
///
/// "A · Refined Dark" design, theme-adaptive via WizardTokens. Same
/// backend contract as before — the green "Activate" button calls
/// `POST /app/sell-with-ai/activate/{listing_id}`. All friendly-error
/// mapping is preserved from the original handler.
class SWAChatModeWizardScreen extends StatefulWidget {
  final String listingId;
  final String listingTitle;
  final int listedPrice;
  final int expectedPrice;
  final int floorPrice;
  final int availabilityWindow;
  final List<String> pickupSlots;
  // Phone-privacy choice carried forward from the Availability step.
  // True = hide seller's number from buyers (default); false = expose it.
  // Forwarded verbatim in the activate API payload.
  final bool hidePhoneFromBuyers;

  const SWAChatModeWizardScreen({
    super.key,
    required this.listingId,
    required this.listingTitle,
    required this.listedPrice,
    required this.expectedPrice,
    required this.floorPrice,
    required this.availabilityWindow,
    required this.pickupSlots,
    this.hidePhoneFromBuyers = true,
  });

  @override
  State<SWAChatModeWizardScreen> createState() =>
      _SWAChatModeWizardScreenState();
}

class _SWAChatModeWizardScreenState extends State<SWAChatModeWizardScreen> {
  String _selectedMode = 'disabled'; // disabled | human | keyword_chat
  // 2026-05-17 — terms must be opted INTO, not pre-checked. A
  // pre-checked consent box undermines the "I agreed" signal we
  // forward to the backend.
  bool _agreedToTerms = false;
  bool _isActivating = false;
  String? _errorMessage;

  // 2026-05-17 — Sole exposed mode is "Smart Assist" (Sell with AI).
  // Backend id remains `disabled` for wire compatibility with the
  // pricing pipeline; only the UI label + copy changes to reflect
  // the actual feature (AI negotiation, not just preset replies).
  // Direct Messages (`human`) and Smart Chat (`keyword_chat`) were
  // dropped from the option list per product call; the backend still
  // accepts those mode ids but sellers can't pick them here.
  static const _options = [
    _ChatMode(
      id: 'disabled',
      label: 'Smart Assist',
      subtitle: 'Sell with AI',
      desc:
          'AI replies on your behalf — qualifies buyers, negotiates within your price range, and only pings you when a real deal is on the table.',
      icon: Icons.auto_awesome_rounded,
      recommended: true,
      tags: ['AI-powered', '24/7', 'Negotiates'],
    ),
  ];

  /// Translates backend error codes to user-friendly copy. Kept
  /// character-for-character from the pre-redesign screen so every
  /// server-side error still gets its tailored message.
  String _friendlyError(String? code, String? raw, {String? matchedKeyword}) {
    switch (code) {
      case 'TOGGLE_RATE_LIMITED':
        return 'You\'ve made too many changes today. Please try again after 24 hours.';
      case 'ALREADY_ACTIVE':
        return 'Smart Assist is already active on this listing. Go to your dashboard to manage it.';
      case 'LISTING_NOT_APPROVED':
        return 'Your listing needs to be approved before you can enable Smart Assist.';
      case 'LISTING_SOLD':
        return 'This listing is marked as sold. Smart Assist can\'t be activated on sold items.';
      case 'EXPECTED_INVALID':
        return 'Your target price is not valid. It must be less than or equal to the listed price.';
      case 'FLOOR_INVALID':
        return 'Your minimum price is not valid. It must be less than or equal to the target price.';
      case 'SLOTS_INVALID':
        return 'Please select valid pickup time slots.';
      case 'WINDOW_INVALID':
        return 'Availability window must be between 3 and 30 days.';
      case 'CHAT_MODE_INVALID':
        return 'Please select a valid chat mode.';
      case 'CATEGORY_NOT_SUPPORTED':
        return 'Smart Assist is not available for this category. It works with physical items only.';
      case 'CATEGORY_NOT_ELIGIBLE':
        // 2026-05-20: explicit gate for Find Investor / Events / Films
        // / Community. These listings aren't tradable goods so SWA's
        // price-negotiation pipeline is meaningless. Surface a clear
        // tailored message instead of the generic
        // "Failed to activate" snackbar — sellers should know exactly
        // why the activation didn't take.
        return "Smart Assist isn't available for this category.";
      case 'PRICE_NOT_ELIGIBLE':
        return 'Smart Assist requires a listing price of at least ₹500.';
      case 'CONTRABAND_SUSPECTED':
        // Surface the specific keyword when the backend provides one
        // so the seller knows exactly what to edit. Falls back to the
        // generic copy when the response body omits matched_keyword
        // (older backend or keyword couldn't be pinpointed).
        if (matchedKeyword != null && matchedKeyword.isNotEmpty) {
          return 'Your listing text includes "$matchedKeyword" which '
              'can\'t be used with Smart Assist. Please edit your '
              'title or description and try again.';
        }
        return 'Your listing contains content that can\'t be used with Smart Assist. Please review your title and description.';
      case 'NOT_FOUND':
        return 'Listing not found. It may have been deleted.';
      case 'FORBIDDEN':
        return 'You can only activate Smart Assist on your own listings.';
      case 'ACTIVATION_CONFLICT':
        return 'Another request is processing. Please refresh and try again.';
      case 'TOKEN_MISSING':
      case 'TOKEN_EXPIRED':
        return 'Your session has expired. Please log in again.';
      case 'SERVER_ERROR':
        return 'Something went wrong on our end. Please try again in a moment.';
      default:
        return raw ?? 'Something went wrong. Please try again.';
    }
  }

  Future<void> _onActivate() async {
    if (!_agreedToTerms) {
      setState(() =>
          _errorMessage = 'Please agree to the terms to continue');
      return;
    }
    setState(() {
      _isActivating = true;
      _errorMessage = null;
    });
    try {
      final body = {
        'expected_price': widget.expectedPrice,
        'floor_price': widget.floorPrice,
        'pickup_slots': widget.pickupSlots,
        'availability_window': widget.availabilityWindow,
        'chat_mode': _selectedMode,
        'delivery_available': false,
        // Phone-privacy preference picked in the Availability step.
        // Backend persists this on sell_with_ai_config.hide_phone_from_buyers
        // and uses it when stripping `friend.mobile` from the buyer-side
        // chat history response.
        'hide_phone_from_buyers': widget.hidePhoneFromBuyers,
      };
      final url = APIEndpointUrls.swaActivate(widget.listingId);
      debugPrint('🔵 SWA Activate → $url');
      debugPrint('🔵 body → $body');
      final res = await ApiClient.post(url, data: body);
      debugPrint('🟢 ${res.statusCode} ${res.data}');
      if (!mounted) return;
      if (res.statusCode == 200 && res.data?['success'] == true) {
        // Show the production-grade success sheet (Option B from the
        // design picker) instead of the small floating snackbar.
        // Both CTAs pop the wizard's three nested routes back to the
        // listing detail screen — this preserves the legacy navigation
        // behaviour. A future change can route "View Dashboard" to the
        // SWA dashboard directly.
        await SwaActivatedSheet.show(
          context,
          listingTitle: widget.listingTitle,
          chatMode: _selectedMode,
          expectedPrice: widget.expectedPrice,
          floorPrice: widget.floorPrice,
          availabilityWindow: widget.availabilityWindow,
          onViewDashboard: () {
            if (!mounted) return;
            // Refresh approved listings so the newly-SWA-activated
            // listing reflects its new state on the My Ads tab.
            try {
              context.read<MyAdsCubit>().getMyAds('approved');
            } catch (_) {
              // Cubit not in scope — non-fatal; AdsScreen fetches on
              // its own when the tab is opened.
            }
            // Dashboard tab 1 = AdsScreen (My Ads).
            context.go('/dashboard?tab=1');
          },
          onBackToListing: () {
            if (!mounted) return;
            // Dashboard tab 0 = HoliHomeScreen (Home).
            context.go('/dashboard?tab=0');
          },
        );
      } else {
        setState(() {
          _errorMessage = _friendlyError(
            res.data?['code'],
            res.data?['message'],
            matchedKeyword: res.data?['matched_keyword']?.toString(),
          );
        });
      }
    } on DioException catch (e) {
      debugPrint('🔴 DioError ${e.type} status=${e.response?.statusCode}');
      if (!mounted) return;
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _errorMessage = _friendlyError(
            data['code']?.toString(),
            data['message']?.toString(),
            matchedKeyword: data['matched_keyword']?.toString(),
          );
        });
      } else {
        setState(() {
          _errorMessage =
              'Unable to connect. Please check your internet and try again.';
        });
      }
    } catch (e) {
      debugPrint('🔴 unknown: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isActivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = WizardTokens.of(context);

    return Scaffold(
      backgroundColor: t.bg,
      appBar: _buildTopBar(t, 'Chat Mode'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WizardStepHeader(
                t: t,
                step: 3,
                totalSteps: 3,
                eyebrow: '03 · REPLIES',
                title: 'How should buyers\nreach you?',
              ),
              const SizedBox(height: 22),
              ..._options.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildOptionCard(t, o),
                ),
              ),
              // 2026-05-17 — extra breathing room between the (now
              // bigger) Smart Assist card and the lock disclaimer /
              // terms checkbox below it so the consent block reads
              // as its own section, not a card footer.
              const SizedBox(height: 22),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 13, color: t.dim2),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your number stays hidden until you accept.',
                      style: TextStyle(fontSize: 11, color: t.dim2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTermsRow(t),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: t.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 18, color: t.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: t.danger,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(t),
    );
  }

  /// Single-option card. Selected state = cyan hairline border + cyan
  /// accent tint. Recommended option gets a green "PICK" badge,
  /// every option gets the amber "FREE" badge.
  ///
  /// 2026-05-17 — sizes bumped now that this is the only option on
  /// the screen (Direct Messages + Smart Chat removed). Bigger icon
  /// tile, bigger title, more padding so it carries the visual
  /// weight a single feature card needs.
  Widget _buildOptionCard(WizardTokens t, _ChatMode o) {
    final selected = _selectedMode == o.id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedMode = o.id;
        _errorMessage = null;
      }),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? t.accent.withOpacity(0.06) : t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? t.accent : t.line,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: t.accent.withOpacity(0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: big icon tile + title block + radio.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: selected ? t.accent : t.surfaceHi,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    o.icon,
                    size: 28,
                    color: selected ? t.onAccent : t.text,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.label,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: t.text,
                        ),
                      ),
                      if (o.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          o.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: t.accent,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (o.recommended)
                            _badge(t, 'PICK', t.success, t.onAccent),
                          _badge(
                              t, 'FREE', t.warn.withOpacity(0.15), t.warn),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: selected ? t.accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: selected
                        ? null
                        : Border.all(color: t.lineHi, width: 1.5),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: t.onAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Description — full-width below the icon row so it has
            // room to breathe on a single-card screen.
            Text(
              o.desc,
              style: TextStyle(
                fontSize: 13.5,
                color: t.dim,
                height: 1.5,
              ),
            ),
            if (o.tags.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: o.tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: t.surfaceHi,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: t.dim,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(WizardTokens t, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildTermsRow(WizardTokens t) {
    return GestureDetector(
      onTap: () => setState(() {
        _agreedToTerms = !_agreedToTerms;
        _errorMessage = null;
      }),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: _agreedToTerms ? t.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: _agreedToTerms
                  ? null
                  : Border.all(color: t.lineHi, width: 1.5),
            ),
            child: _agreedToTerms
                ? Icon(Icons.check_rounded, size: 12, color: t.onAccent)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11.5,
                  color: t.dim,
                  height: 1.45,
                ),
                children: [
                  const TextSpan(text: 'I agree to '),
                  TextSpan(
                    text: 'Smart Assist Terms',
                    style: TextStyle(
                      color: t.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text:
                        '. AI may negotiate within my price range.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(WizardTokens t, String title) {
    return AppBar(
      backgroundColor: t.bg,
      surfaceTintColor: t.bg,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: t.text,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: t.text),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: t.line),
      ),
    );
  }

  /// Final-step CTA uses the lime success color + bolt icon — matches
  /// the mock's "Activate Smart Assist" button treatment.
  Widget _buildBottomBar(WizardTokens t) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: WizardPrimaryButton(
          t: t,
          label: 'Activate Smart Assist',
          icon: Icons.flash_on_rounded,
          background: t.success,
          loading: _isActivating,
          onPressed: _onActivate,
        ),
      ),
    );
  }
}

class _ChatMode {
  final String id;
  final String label;
  /// Optional sub-brand line under the title (e.g. "Sell with AI"
  /// below "Smart Assist"). Renders in the accent colour when set.
  final String? subtitle;
  final String desc;
  final IconData icon;
  final bool recommended;
  final List<String> tags;

  const _ChatMode({
    required this.id,
    required this.label,
    this.subtitle,
    required this.desc,
    required this.icon,
    this.recommended = false,
    this.tags = const [],
  });
}
