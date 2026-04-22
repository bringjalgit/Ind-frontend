import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/theme/ThemeHelper.dart';
import 'package:classifieds/theme/app_colors.dart';
import 'package:classifieds/Components/CutomAppBar.dart';
import 'package:classifieds/services/ApiClient.dart';
import 'package:classifieds/services/api_endpoint_urls.dart';

/// S5 — Seller Dashboard for a single SWA-enabled listing.
///
/// Fetches GET /app/sell-with-ai/dashboard/{listing_id} and renders:
///   • Listing header (title, price, active status, days left, pause)
///   • 3 metric tiles (inquiries, good buyers, highest offer)
///   • Tab-filtered buyer conversation list
///   • Deal-pending cards with confirm button
///
/// Route: /swa-dashboard/:listingId
class SWADashboardScreen extends StatefulWidget {
  final String listingId;

  const SWADashboardScreen({super.key, required this.listingId});

  @override
  State<SWADashboardScreen> createState() => _SWADashboardScreenState();
}

class _SWADashboardScreenState extends State<SWADashboardScreen> {
  bool _loading = true;
  String? _error;

  // API response data
  Map<String, dynamic> _listing = {};
  Map<String, dynamic> _summary = {};
  List<dynamic> _conversations = [];

  // Tab state
  int _selectedTab = 1; // 0=All, 1=Active, 2=Needs Attention, 3=Deals
  final List<String> _tabLabels = ['All', 'Active', 'Needs\nAttention', 'Deals'];

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final url = APIEndpointUrls.swaDashboard(widget.listingId);
      final response = await ApiClient.get('$url?status=all&limit=50');

      if (response.statusCode == 200) {
        final body = response.data is Map<String, dynamic>
            ? response.data
            : <String, dynamic>{};
        setState(() {
          _listing = body['listing'] as Map<String, dynamic>? ?? {};
          _summary = body['summary'] as Map<String, dynamic>? ?? {};
          _conversations = body['data'] as List<dynamic>? ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load dashboard';
          _loading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message']?.toString() ?? 'Connection error';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong';
        _loading = false;
      });
    }
  }

  Future<void> _deactivateSWA() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeHelper.isDarkMode(ctx) ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text('Pause Smart Assist?', style: TextStyle(color: ThemeHelper.textColor(ctx))),
        content: Text(
          'AI will stop handling buyer queries for this listing. You can re-enable it anytime.',
          style: TextStyle(color: ThemeHelper.textColor(ctx).withOpacity(0.7)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pause', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final url = APIEndpointUrls.swaDeactivate(widget.listingId);
      final response = await ApiClient.post(url);
      if (response.statusCode == 200 && mounted) {
        context.pop();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data?['message']?.toString() ?? 'Failed to pause')),
      );
    }
  }

  Future<void> _confirmDeal(String conversationId) async {
    try {
      final url = APIEndpointUrls.swaConfirm(conversationId);
      final response = await ApiClient.post(url);
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deal confirmed!')),
        );
        _fetchDashboard();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data?['message']?.toString() ?? 'Failed to confirm')),
      );
    }
  }

  List<dynamic> get _filteredConversations {
    switch (_selectedTab) {
      case 0: // All
        return _conversations;
      case 1: // Active
        return _conversations.where((c) => c['status'] == 'active').toList();
      case 2: // Needs Attention
        return _conversations.where((c) =>
            c['needs_seller_attention'] == true ||
            c['status'] == 'pending_acceptance').toList();
      case 3: // Deals
        return _conversations.where((c) =>
            c['status'] == 'pending_acceptance' ||
            c['status'] == 'accepted').toList();
      default:
        return _conversations;
    }
  }

  int get _needsAttentionCount {
    return _conversations.where((c) =>
        c['needs_seller_attention'] == true ||
        c['status'] == 'pending_acceptance').length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final textColor = ThemeHelper.textColor(context);
    final secondaryText = AppColors.unselect;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F5),
      appBar: CustomAppBar1(
        title: 'Smart Assist Dashboard',
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textColor, size: 22),
            onPressed: () {
              final config = _listing['config'] as Map<String, dynamic>? ?? {};
              context.push(
                '/swa-settings/${widget.listingId}',
                extra: config,
              ).then((result) {
                if (result == true) _fetchDashboard();
              });
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(textColor, secondaryText)
              : RefreshIndicator(
                  onRefresh: _fetchDashboard,
                  child: CustomScrollView(
                    slivers: [
                      // ── Listing header ────────────────────────────
                      SliverToBoxAdapter(
                        child: _buildListingHeader(isDark, textColor, secondaryText, cardBg, dividerColor),
                      ),

                      // ── Metrics row ───────────────────────────────
                      SliverToBoxAdapter(
                        child: _buildMetricsRow(isDark, textColor, secondaryText),
                      ),

                      // ── Tab bar ───────────────────────────────────
                      SliverToBoxAdapter(
                        child: _buildTabBar(isDark, textColor, secondaryText, cardBg, dividerColor),
                      ),

                      // ── Conversation list ─────────────────────────
                      _filteredConversations.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 60),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.inbox_outlined, size: 48, color: secondaryText),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No conversations yet',
                                        style: TextStyle(fontSize: 14, color: secondaryText),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final conv = _filteredConversations[index] as Map<String, dynamic>;
                                    if (conv['status'] == 'pending_acceptance') {
                                      return _buildDealPendingCard(conv, isDark, textColor, secondaryText);
                                    }
                                    return _buildBuyerCard(conv, isDark, textColor, secondaryText);
                                  },
                                  childCount: _filteredConversations.length,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────────
  Widget _buildErrorState(Color textColor, Color secondaryText) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: secondaryText),
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(fontSize: 14, color: textColor)),
          const SizedBox(height: 16),
          TextButton(onPressed: _fetchDashboard, child: const Text('Retry')),
        ],
      ),
    );
  }

  // ── Listing header ───────────────────────────────────────────────────
  Widget _buildListingHeader(bool isDark, Color textColor, Color secondaryText, Color cardBg, Color dividerColor) {
    final title = _listing['title']?.toString() ?? 'Listing';
    final price = _listing['price']?.toString() ?? '0';
    final isActive = _listing['is_active'] == true;
    final expiresAt = DateTime.tryParse(_listing['expires_at']?.toString() ?? '');
    final daysLeft = expiresAt != null ? expiresAt.difference(DateTime.now()).inDays : 0;

    return Container(
      color: cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Listing thumbnail placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.image_outlined, size: 20, color: secondaryText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '\u20B9$price',
                      style: TextStyle(fontSize: 12, color: secondaryText),
                    ),
                    Text(' \u2022 ', style: TextStyle(fontSize: 12, color: secondaryText)),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? const Color(0xFF22C55E) : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'Active \u2022 ${daysLeft}d left' : 'Paused',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? const Color(0xFF22C55E) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Pause button
          if (isActive)
            GestureDetector(
              onTap: _deactivateSWA,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDark ? const Color(0xFF666666) : const Color(0xFFD1D5DB)),
                ),
                child: Text(
                  'Pause',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: secondaryText),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Metrics row ──────────────────────────────────────────────────────
  Widget _buildMetricsRow(bool isDark, Color textColor, Color secondaryText) {
    final inquiries = _summary['total_inquiries'] ?? 0;
    final goodBuyers = _summary['good_buyers'] ?? 0;
    final highestOffer = _summary['highest_offer'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          _metricTile(
            icon: Icons.people_outline,
            iconColor: AppColors.primary,
            value: '$inquiries',
            label: inquiries == 1 ? 'inquiry' : 'inquiries',
            isDark: isDark,
            textColor: textColor,
            secondaryText: secondaryText,
          ),
          const SizedBox(width: 8),
          _metricTile(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFF22C55E),
            value: '$goodBuyers',
            valueColor: const Color(0xFF22C55E),
            label: goodBuyers == 1 ? 'good buyer' : 'good buyers',
            isDark: isDark,
            textColor: textColor,
            secondaryText: secondaryText,
          ),
          const SizedBox(width: 8),
          _metricTile(
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.primary,
            value: highestOffer > 0 ? '\u20B9${_formatIndian(highestOffer)}' : '--',
            label: 'highest offer',
            isDark: isDark,
            textColor: textColor,
            secondaryText: secondaryText,
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    Color? valueColor,
    required String label,
    required bool isDark,
    required Color textColor,
    required Color secondaryText,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: value.length > 7 ? 16 : 22,
                fontWeight: FontWeight.w700,
                color: valueColor ?? textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: secondaryText)),
          ],
        ),
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────────────────────
  Widget _buildTabBar(bool isDark, Color textColor, Color secondaryText, Color cardBg, Color dividerColor) {
    final attentionCount = _needsAttentionCount;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: Row(
          children: List.generate(_tabLabels.length, (i) {
            final isSelected = _selectedTab == i;
            final isAttention = i == 2;
            return Expanded(
              child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _tabLabels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : secondaryText,
                        height: 1.2,
                      ),
                    ),
                    if (isAttention && attentionCount > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$attentionCount',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            );
          }),
        ),
    );
  }

  // ── Deal pending card ────────────────────────────────────────────────
  Widget _buildDealPendingCard(Map<String, dynamic> conv, bool isDark, Color textColor, Color secondaryText) {
    final buyer = conv['buyer'] as Map<String, dynamic>? ?? {};
    final buyerName = buyer['name']?.toString() ?? 'Buyer';
    final initial = buyerName.isNotEmpty ? buyerName[0].toUpperCase() : '?';
    final offer = conv['current_offer'] ?? conv['agreed_price'] ?? 0;
    final counterOffer = conv['counter_offer'];
    final expiresAt = DateTime.tryParse(conv['pending_acceptance_expires_at']?.toString() ?? '');
    final minsLeft = expiresAt != null ? expiresAt.difference(DateTime.now()).inMinutes : 0;
    final timeAgo = _relativeTime(conv['last_message_at']?.toString());

    // Build offer history line
    String offerHistory = '';
    if (counterOffer != null && counterOffer > 0) {
      offerHistory = 'Offered \u20B9${_formatIndian(conv['current_offer'] ?? 0)} \u2022 Countered \u20B9${_formatIndian(counterOffer)} \u2022 Agreed';
    } else {
      offerHistory = 'Offered \u20B9${_formatIndian(offer)}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          final convId = conv['_id']?.toString() ?? '';
          if (convId.isNotEmpty) context.push('/swa-conversation/$convId');
        },
        child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + name + chip + time
            Row(
              children: [
                _avatarCircle(initial, const Color(0xFFEF4444), 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          buyerName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _chip('DEAL PENDING', const Color(0xFFEF4444), isDark ? const Color(0xFF3A1F1F) : const Color(0xFFFEE2E2)),
                    ],
                  ),
                ),
                Text(timeAgo, style: TextStyle(fontSize: 10, color: secondaryText)),
              ],
            ),
            const SizedBox(height: 8),
            // Confirm line with timer
            Text(
              'Confirm within ${minsLeft > 0 ? minsLeft : 0} min \u2022 \u20B9${_formatIndian(offer)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 4),
            // Offer history
            Text(
              offerHistory,
              style: TextStyle(fontSize: 11, color: secondaryText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Confirm button
            Row(
              children: [
                GestureDetector(
                  onTap: () => _confirmDeal(conv['_id']?.toString() ?? ''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _cancelDeal(conv['_id']?.toString() ?? ''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isDark ? const Color(0xFF666666) : const Color(0xFFD1D5DB)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: secondaryText),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _cancelDeal(String conversationId) async {
    try {
      final url = APIEndpointUrls.swaCancelAcceptance(conversationId);
      final response = await ApiClient.post(url);
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deal cancelled')),
        );
        _fetchDashboard();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data?['message']?.toString() ?? 'Failed to cancel')),
      );
    }
  }

  // ── Regular buyer card ───────────────────────────────────────────────
  Widget _buildBuyerCard(Map<String, dynamic> conv, bool isDark, Color textColor, Color secondaryText) {
    final buyer = conv['buyer'] as Map<String, dynamic>? ?? {};
    final buyerName = buyer['name']?.toString() ?? 'Buyer';
    final initial = buyerName.isNotEmpty ? buyerName[0].toUpperCase() : '?';
    final classification = conv['classification']?.toString() ?? '';
    final offer = conv['current_offer'];
    final counterOffer = conv['counter_offer'];
    final lastMsg = conv['last_message']?.toString() ?? '';
    final timeAgo = _relativeTime(conv['last_message_at']?.toString());
    final status = conv['status']?.toString() ?? '';

    // Classification colors
    Color chipColor;
    Color chipBg;
    String chipLabel;
    switch (classification) {
      case 'hot':
        chipColor = const Color(0xFFEF4444);
        chipBg = isDark ? const Color(0xFF3A1F1F) : const Color(0xFFFEE2E2);
        chipLabel = 'HOT';
        break;
      case 'good':
        chipColor = const Color(0xFF86EFAC);
        chipBg = isDark ? const Color(0xFF1A3A2A) : const Color(0xFFDCFCE7);
        chipLabel = 'GOOD';
        break;
      case 'maybe':
        chipColor = const Color(0xFFFFD600);
        chipBg = isDark ? const Color(0xFF3D3418) : const Color(0xFFFEF9C3);
        chipLabel = 'MAYBE';
        break;
      default:
        chipColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
        chipBg = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3F4F6);
        chipLabel = 'LOW';
    }

    // Avatar color based on name hash
    final avatarColors = [
      const Color(0xFF1677FF),
      const Color(0xFF22C55E),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF6366F1),
    ];
    final avatarColor = avatarColors[buyerName.hashCode.abs() % avatarColors.length];

    // Build offer line
    String offerLine = '';
    if (status == 'accepted') {
      offerLine = 'Deal accepted \u2022 \u20B9${_formatIndian(conv['agreed_price'] ?? offer ?? 0)}';
    } else if (offer != null && offer > 0) {
      offerLine = 'Offered \u20B9${_formatIndian(offer)}';
      if (counterOffer != null && counterOffer > 0) {
        offerLine += ' \u2022 Counter \u20B9${_formatIndian(counterOffer)}';
      }
    } else {
      offerLine = 'No offer yet';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          final convId = conv['_id']?.toString() ?? '';
          if (convId.isNotEmpty) context.push('/swa-conversation/$convId');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatarCircle(initial, avatarColor, 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + chip + time
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            buyerName,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _chip(chipLabel, chipColor, chipBg),
                        const Spacer(),
                        Text(timeAgo, style: TextStyle(fontSize: 10, color: secondaryText)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Offer line
                    Text(
                      offerLine,
                      style: TextStyle(fontSize: 12, color: secondaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lastMsg.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '"$lastMsg"',
                        style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared widgets ───────────────────────────────────────────────────

  Widget _avatarCircle(String initial, Color color, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.9,
          fontWeight: FontWeight.w700,
          color: _isLightColor(color) ? const Color(0xFF1E1E1E) : Colors.white,
        ),
      ),
    );
  }

  bool _isLightColor(Color c) {
    return (0.299 * c.red + 0.587 * c.green + 0.114 * c.blue) > 160;
  }

  Widget _chip(String label, Color textColor, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }

  // ── Formatters ───────────────────────────────────────────────────────

  String _formatIndian(dynamic num) {
    if (num == null) return '0';
    final n = num is int ? num : int.tryParse(num.toString()) ?? 0;
    if (n < 1000) return n.toString();
    final s = n.toString();
    final len = s.length;
    if (len <= 3) return s;
    String result = s.substring(len - 3);
    String remaining = s.substring(0, len - 3);
    while (remaining.length > 2) {
      result = '${remaining.substring(remaining.length - 2)},$result';
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) result = '$remaining,$result';
    return result;
  }

  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }
}
