import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:classifieds/theme/ThemeHelper.dart';
import 'package:classifieds/theme/app_colors.dart';
import 'package:classifieds/services/ApiClient.dart';
import 'package:classifieds/services/api_endpoint_urls.dart';

/// S6 — Seller Conversation Detail.
///
/// Shows the full AI-managed conversation between a buyer and the system,
/// from the seller's perspective. The seller can override with:
///   Accept / Counter / Decline / Message / Takeover
///
/// Uses the same bubble styling as the existing ChatScreen.
///
/// Route: /swa-conversation/:conversationId
class SWAConversationScreen extends StatefulWidget {
  final String conversationId;

  const SWAConversationScreen({super.key, required this.conversationId});

  @override
  State<SWAConversationScreen> createState() => _SWAConversationScreenState();
}

class _SWAConversationScreenState extends State<SWAConversationScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _conversation = {};
  Map<String, dynamic> _buyer = {};
  Map<String, dynamic> _listing = {};
  List<dynamic> _messages = [];
  String _status = '';

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchConversation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchConversation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final url = APIEndpointUrls.swaGetConversation(widget.conversationId);
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final data = response.data?['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _conversation = data;
          _buyer = data['buyer'] as Map<String, dynamic>? ?? {};
          _listing = data['listing'] as Map<String, dynamic>? ?? {};
          _messages = data['messages'] as List<dynamic>? ?? [];
          _status = data['status']?.toString() ?? '';
          _loading = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _error = 'Failed to load conversation';
          _loading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message']?.toString() ?? 'Connection error';
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Something went wrong';
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Override actions ─────────────────────────────────────────────────

  Future<void> _sendOverride(String action, {int? counterPrice, String? message}) async {
    try {
      final url = APIEndpointUrls.swaOverride(widget.conversationId);
      final body = <String, dynamic>{'action': action};
      if (counterPrice != null) body['counter_price'] = counterPrice;
      if (message != null) body['message'] = message;

      final response = await ApiClient.post(url, data: body);
      if (response.statusCode == 200 && mounted) {
        _fetchConversation();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data?['message']?.toString() ?? 'Action failed')),
      );
    }
  }

  Future<void> _confirmDeal() async {
    try {
      final url = APIEndpointUrls.swaConfirm(widget.conversationId);
      final response = await ApiClient.post(url);
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deal confirmed!')),
        );
        _fetchConversation();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data?['message']?.toString() ?? 'Failed to confirm')),
      );
    }
  }

  // ignore: unused_element  // preserved for revert — see action-bar comment
  void _showCounterDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = ThemeHelper.isDarkMode(ctx);
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text('Counter Offer', style: TextStyle(color: ThemeHelper.textColor(ctx))),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: ThemeHelper.textColor(ctx)),
            decoration: InputDecoration(
              hintText: 'Enter your price',
              prefixText: '\u20B9 ',
              hintStyle: TextStyle(color: ThemeHelper.textColor(ctx).withOpacity(0.4)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final price = int.tryParse(controller.text.trim());
                Navigator.pop(ctx);
                if (price != null && price > 0) {
                  _sendOverride('counter', counterPrice: price);
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  // ignore: unused_element  // preserved for revert — see action-bar comment
  void _showMessageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = ThemeHelper.isDarkMode(ctx);
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text('Send Message', style: TextStyle(color: ThemeHelper.textColor(ctx))),
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: TextStyle(color: ThemeHelper.textColor(ctx)),
            decoration: InputDecoration(
              hintText: 'Type your message to the buyer...',
              hintStyle: TextStyle(color: ThemeHelper.textColor(ctx).withOpacity(0.4)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final msg = controller.text.trim();
                Navigator.pop(ctx);
                if (msg.isNotEmpty) {
                  _sendOverride('message', message: msg);
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final textColor = ThemeHelper.textColor(context);
    final secondaryText = AppColors.unselect;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F5),
      appBar: _buildAppBar(isDark, textColor, secondaryText),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: secondaryText),
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(fontSize: 14, color: textColor)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _fetchConversation, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Listing context banner
                    _buildListingBanner(isDark, textColor, secondaryText),
                    // Messages
                    Expanded(child: _buildMessageList(isDark, textColor, secondaryText)),
                    // Action bar
                    _buildActionBar(isDark, textColor, secondaryText),
                  ],
                ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isDark, Color textColor, Color secondaryText) {
    final buyerName = _buyer['name']?.toString() ?? 'Buyer';
    final initial = buyerName.isNotEmpty ? buyerName[0].toUpperCase() : '?';
    final qualityScore = _conversation['quality_score'];
    final total = qualityScore is Map ? qualityScore['total'] : null;

    final avatarColors = [
      const Color(0xFF1677FF), const Color(0xFF22C55E),
      const Color(0xFFF59E0B), const Color(0xFF8B5CF6),
      const Color(0xFFEC4899), const Color(0xFF6366F1),
    ];
    final avatarColor = avatarColors[buyerName.hashCode.abs() % avatarColors.length];

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textColor),
        onPressed: () => context.pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: avatarColor,
            child: Text(initial, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  buyerName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
                if (total != null)
                  Row(
                    children: [
                      Icon(Icons.verified_outlined, size: 12, color: const Color(0xFF22C55E)),
                      const SizedBox(width: 3),
                      Text(
                        'quality: $total',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF86EFAC)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: textColor),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          onSelected: (value) {
            if (value == 'takeover') {
              _sendOverride('takeover');
            } else if (value == 'decline') {
              _sendOverride('decline');
            }
          },
          itemBuilder: (_) => [
            if (_status == 'active' || _status == 'pending_acceptance')
              PopupMenuItem(value: 'takeover', child: Text('Take Over Chat', style: TextStyle(color: textColor))),
            if (_status == 'active')
              const PopupMenuItem(value: 'decline', child: Text('Decline Buyer', style: TextStyle(color: Colors.redAccent))),
          ],
        ),
      ],
    );
  }

  // ── Listing banner ───────────────────────────────────────────────────

  Widget _buildListingBanner(bool isDark, Color textColor, Color secondaryText) {
    final title = _listing['title']?.toString() ?? 'Listing';
    final price = _listing['price']?.toString() ?? '0';

    return Container(
      color: isDark ? const Color(0xFF1E2A3E) : const Color(0xFFEBF4FF),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFD6E8FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.image_outlined, size: 16, color: secondaryText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor), overflow: TextOverflow.ellipsis),
                Text('\u20B9$price', style: TextStyle(fontSize: 11, color: secondaryText)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flash_on_rounded, size: 12, color: Colors.white),
                SizedBox(width: 2),
                Text('SMART', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Message list ─────────────────────────────────────────────────────

  Widget _buildMessageList(bool isDark, Color textColor, Color secondaryText) {
    if (_messages.isEmpty) {
      return Center(
        child: Text('No messages yet', style: TextStyle(fontSize: 14, color: secondaryText)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index] as Map<String, dynamic>? ?? {};
        return _buildBubble(msg, isDark, textColor, secondaryText);
      },
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isDark, Color textColor, Color secondaryText) {
    final sender = msg['sender']?.toString() ?? 'system';
    final content = msg['content']?.toString() ?? '';
    final type = msg['type']?.toString() ?? 'text';
    final createdAt = msg['created_at']?.toString() ?? '';
    final time = _formatTime(createdAt);
    final offerAmount = msg['offer_amount'];

    // Buyer messages align left, system/seller align left too (seller is viewing)
    // But buyer messages look different from system auto-replies
    final isBuyer = sender == 'buyer';
    final isSeller = sender == 'seller';

    // System event types get special styling
    final isOffer = type == 'offer' || offerAmount != null;
    final isDeal = type == 'system_event' && (msg['pill_id'] == 'agreement' || content.toLowerCase().contains('deal'));
    final isCounter = type == 'counter_offer';
    final isDecline = type == 'decline_reason';

    // Bubble colors matching existing ChatScreen
    final buyerBubbleColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]!;
    final systemBubbleColor = isDark ? const Color(0xFF234476) : Colors.blue[100]!;
    final sellerBubbleColor = isDark ? const Color(0xFF234476) : Colors.blue[100]!;

    Color bubbleColor;
    Alignment alignment;
    CrossAxisAlignment crossAlignment;
    double bottomLeftRadius = 16;
    double bottomRightRadius = 16;

    if (isBuyer) {
      bubbleColor = buyerBubbleColor;
      alignment = Alignment.centerLeft;
      crossAlignment = CrossAxisAlignment.start;
      bottomLeftRadius = 4;
    } else if (isSeller) {
      bubbleColor = sellerBubbleColor;
      alignment = Alignment.centerRight;
      crossAlignment = CrossAxisAlignment.end;
      bottomRightRadius = 4;
    } else {
      // System messages
      bubbleColor = systemBubbleColor;
      alignment = Alignment.centerLeft;
      crossAlignment = CrossAxisAlignment.start;
      bottomLeftRadius = 4;
    }

    // Special styling for specific message types
    if (isOffer && isBuyer) {
      bubbleColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    } else if (isDeal) {
      bubbleColor = isDark ? const Color(0xFF1A3A2A) : const Color(0xFFDCFCE7);
    } else if (isCounter) {
      bubbleColor = isDark ? const Color(0xFF3D3418) : const Color(0xFFFEF9C3);
    } else if (isDecline) {
      bubbleColor = isDark ? const Color(0xFF3A1F1F) : const Color(0xFFFEE2E2);
    }

    // Border for special types
    Border? border;
    if (isOffer && isBuyer) {
      border = Border.all(color: AppColors.primary, width: 1.5);
    } else if (isDeal) {
      border = Border.all(color: const Color(0xFF22C55E), width: 1);
    } else if (isCounter) {
      border = Border.all(color: const Color(0xFFFFD600), width: 1);
    } else if (isDecline) {
      border = Border.all(color: const Color(0xFFEF4444), width: 1);
    }

    // Sender label
    String senderLabel;
    if (isBuyer) {
      senderLabel = _buyer['name']?.toString() ?? 'Buyer';
    } else if (isSeller) {
      senderLabel = 'You';
    } else {
      senderLabel = 'Auto-reply';
    }

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: crossAlignment,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(bottomLeftRadius),
                    bottomRight: Radius.circular(bottomRightRadius),
                  ),
                  border: border,
                ),
                child: Column(
                  crossAxisAlignment: crossAlignment,
                  children: [
                    // Offer amount display
                    if (isOffer && isBuyer && offerAmount != null) ...[
                      Text('Offered', style: TextStyle(fontSize: 11, color: secondaryText)),
                      const SizedBox(height: 2),
                      Text(
                        '\u20B9${_formatIndian(offerAmount)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ] else ...[
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDeal
                              ? const Color(0xFF86EFAC)
                              : isDecline
                                  ? const Color(0xFFEF4444)
                                  : textColor,
                          fontWeight: isDeal ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$senderLabel \u2022 $time',
                  style: TextStyle(fontSize: 9, color: secondaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Action bar ───────────────────────────────────────────────────────

  Widget _buildActionBar(bool isDark, Color textColor, Color secondaryText) {
    final hasDealPending = _status == 'pending_acceptance';
    final isActive = _status == 'active';
    final isAccepted = _status == 'accepted';
    final agreedPrice = _conversation['agreed_price'] ?? _conversation['current_offer'] ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 2026-05-17 — Accept / Counter / Decline / Message action
          // row commented out. SWA's job is to surface a real buyer;
          // sellers now close deals via a normal chat (the Dashboard
          // routes taps to `/chat` and the seller's first typed
          // message triggers implicit takeover server-side).
          //
          // Code preserved (not deleted) so we can revive this flow
          // if product wants the structured-override path back. To
          // restore, un-comment the block below and the helpers
          // [_sendOverride], [_showCounterDialog], [_showMessageDialog]
          // earlier in this file.
          //
          // if (isActive)
          //   Row(
          //     children: [
          //       _actionButton('Accept', Icons.check_rounded, const Color(0xFF22C55E), isDark ? const Color(0xFF1A3A2A) : const Color(0xFFDCFCE7), () {
          //         _sendOverride('accept');
          //       }),
          //       const SizedBox(width: 8),
          //       _actionButton('Counter', Icons.swap_horiz_rounded, AppColors.primary, isDark ? const Color(0xFF1E2A3E) : const Color(0xFFEBF4FF), () {
          //         _showCounterDialog();
          //       }),
          //       const SizedBox(width: 8),
          //       _actionButton('Decline', Icons.close_rounded, const Color(0xFFEF4444), isDark ? const Color(0xFF3A1F1F) : const Color(0xFFFEE2E2), () {
          //         _sendOverride('decline');
          //       }),
          //       const SizedBox(width: 8),
          //       _actionButton('Message', Icons.chat_bubble_outline, AppColors.primary, isDark ? const Color(0xFF1E2A3E) : const Color(0xFFEBF4FF), () {
          //         _showMessageDialog();
          //       }),
          //     ],
          //   ),

          // Confirm deal button (when pending_acceptance)
          if (hasDealPending) ...[
            if (isActive) const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _confirmDeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  'Confirm Deal \u2022 \u20B9${_formatIndian(agreedPrice)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],

          // Accepted status
          if (isAccepted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A3A2A) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF22C55E)),
                  const SizedBox(width: 8),
                  Text(
                    'Deal Confirmed \u2022 \u20B9${_formatIndian(agreedPrice)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF22C55E)),
                  ),
                ],
              ),
            ),

          // Ended status
          if (_status == 'declined' || _status == 'expired' || _status == 'seller_takeover')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _status == 'seller_takeover'
                      ? 'You took over this conversation'
                      : 'This conversation has ended',
                  style: TextStyle(fontSize: 13, color: secondaryText),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ignore: unused_element  // preserved for revert — see action-bar comment
  Widget _actionButton(String label, IconData icon, Color color, Color bg, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Formatters ───────────────────────────────────────────────────────

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('h:mm a').format(dt.toLocal());
  }

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
}
