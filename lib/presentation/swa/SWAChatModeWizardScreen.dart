import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:classifieds/services/ApiClient.dart';
import 'package:classifieds/services/api_endpoint_urls.dart';
import 'widgets/wizard_theme.dart';

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

  const SWAChatModeWizardScreen({
    super.key,
    required this.listingId,
    required this.listingTitle,
    required this.listedPrice,
    required this.expectedPrice,
    required this.floorPrice,
    required this.availabilityWindow,
    required this.pickupSlots,
  });

  @override
  State<SWAChatModeWizardScreen> createState() =>
      _SWAChatModeWizardScreenState();
}

class _SWAChatModeWizardScreenState extends State<SWAChatModeWizardScreen> {
  String _selectedMode = 'disabled'; // disabled | human | keyword_chat
  bool _agreedToTerms = true;
  bool _isActivating = false;
  String? _errorMessage;

  static const _options = [
    _ChatMode(
      id: 'disabled',
      label: 'Quick Replies',
      desc: 'Buyers tap preset answers. Fastest, zero spam.',
      icon: Icons.flash_on_rounded,
      recommended: true,
      tags: ['Fastest', 'Low spam'],
    ),
    _ChatMode(
      id: 'human',
      label: 'Direct Messages',
      desc: 'Buyers message you after making an offer.',
      icon: Icons.chat_bubble_outline_rounded,
      tags: ['Personal'],
    ),
    _ChatMode(
      id: 'keyword_chat',
      label: 'Smart Chat',
      desc: 'AI answers listing questions using your details.',
      icon: Icons.auto_awesome_rounded,
      tags: ['Auto-reply'],
    ),
  ];

  /// Translates backend error codes to user-friendly copy. Kept
  /// character-for-character from the pre-redesign screen so every
  /// server-side error still gets its tailored message.
  String _friendlyError(String? code, String? raw) {
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
        return 'Availability window must be between 3 and 90 days.';
      case 'CHAT_MODE_INVALID':
        return 'Please select a valid chat mode.';
      case 'CATEGORY_NOT_SUPPORTED':
        return 'Smart Assist is not available for this category. It works with physical items only.';
      case 'PRICE_NOT_ELIGIBLE':
        return 'Smart Assist requires a listing price of at least ₹500.';
      case 'CONTRABAND_SUSPECTED':
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
      };
      final url = APIEndpointUrls.swaActivate(widget.listingId);
      debugPrint('🔵 SWA Activate → $url');
      debugPrint('🔵 body → $body');
      final res = await ApiClient.post(url, data: body);
      debugPrint('🟢 ${res.statusCode} ${res.data}');
      if (!mounted) return;
      if (res.statusCode == 200 && res.data?['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Smart Assist activated! 🎉'),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMessage = _friendlyError(
            res.data?['code'],
            res.data?['message'],
          );
        });
      }
    } on DioException catch (e) {
      debugPrint('🔴 DioError ${e.type} status=${e.response?.statusCode}');
      if (!mounted) return;
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _errorMessage =
              _friendlyError(data['code']?.toString(), data['message']?.toString());
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
              const SizedBox(height: 4),
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
              const SizedBox(height: 14),
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
  Widget _buildOptionCard(WizardTokens t, _ChatMode o) {
    final selected = _selectedMode == o.id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedMode = o.id;
        _errorMessage = null;
      }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? t.accent.withOpacity(0.06) : t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? t.accent : t.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading icon tile — filled when selected.
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? t.accent : t.surfaceHi,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                o.icon,
                size: 18,
                color: selected ? t.onAccent : t.text,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        o.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: t.text,
                        ),
                      ),
                      if (o.recommended) _badge(t, 'PICK', t.success, t.onAccent),
                      _badge(t, 'FREE', t.warn.withOpacity(0.15), t.warn),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    o.desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: t.dim,
                      height: 1.45,
                    ),
                  ),
                  if (o.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: o.tags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: t.surfaceHi,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
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
            const SizedBox(width: 8),
            // Radio dot — filled when selected.
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
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
                        width: 7,
                        height: 7,
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
  final String desc;
  final IconData icon;
  final bool recommended;
  final List<String> tags;

  const _ChatMode({
    required this.id,
    required this.label,
    required this.desc,
    required this.icon,
    this.recommended = false,
    this.tags = const [],
  });
}
