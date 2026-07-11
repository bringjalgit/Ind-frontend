import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/Components/CustomAppButton.dart';
import 'package:classifieds/Components/CustomSnackBar.dart';

import '../../data/cubit/ReportAd/ReportAdCubit.dart';
import '../../data/cubit/ReportAd/ReportAdStates.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';

/// ====== LISTING REASONS ======
enum ListingReportReason {
  offensiveContent,
  fraud,
  duplicateAd,
  productAlreadySold,
  other,
}

extension ListingReportReasonX on ListingReportReason {
  String get label => switch (this) {
    ListingReportReason.offensiveContent => 'Offensive content',
    ListingReportReason.fraud => 'Fraud',
    ListingReportReason.duplicateAd => 'Duplicate ad',
    ListingReportReason.productAlreadySold => 'Product already sold',
    ListingReportReason.other => 'Other',
  };

  String get apiValue => switch (this) {
    ListingReportReason.offensiveContent => 'offensive',
    ListingReportReason.fraud => 'fraud',
    ListingReportReason.duplicateAd => 'duplicate',
    ListingReportReason.productAlreadySold => 'sold',
    ListingReportReason.other => 'other',
  };
}

/// ====== CHAT REASONS ======
enum ChatReportReason { spam, offensiveContent, harassment, fraud, other }

extension ChatReportReasonX on ChatReportReason {
  String get label => switch (this) {
    ChatReportReason.spam => 'Spam',
    ChatReportReason.offensiveContent => 'Offensive content',
    ChatReportReason.harassment => 'Harassment or abuse',
    ChatReportReason.fraud => 'Fraud / Scam',
    ChatReportReason.other => 'Other',
  };

  String get apiValue => switch (this) {
    ChatReportReason.spam => 'spam',
    ChatReportReason.offensiveContent => 'offensive',
    ChatReportReason.harassment => 'harassment',
    ChatReportReason.fraud => 'fraud',
    ChatReportReason.other => 'other',
  };
}

/// ====== CONTEXT ======
enum ReportContextType { listing, chat }

class ReportBottomSheet extends StatefulWidget {
  const ReportBottomSheet.listing({super.key, required this.listingId})
    : contextType = ReportContextType.listing,
      userId = null;

  const ReportBottomSheet.chat({super.key, required this.userId})
    : contextType = ReportContextType.chat,
      listingId = null;

  final ReportContextType contextType;
  final String? listingId;
  final String? userId;

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// We’ll hold the selected reason as `Object` so it can be either enum.
  Object? _selected;
  static const int _maxLen = 500;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isChat => widget.contextType == ReportContextType.chat;

  /// Helpers to read label/apiValue from either enum
  String _labelOf(Object r) {
    if (r is ListingReportReason) return r.label;
    return (r as ChatReportReason).label;
  }

  String _apiOf(Object r) {
    if (r is ListingReportReason) return r.apiValue;
    return (r as ChatReportReason).apiValue;
  }

  /// Active list of reasons for the current context
  List<Object> get _activeReasons =>
      _isChat ? ChatReportReason.values : ListingReportReason.values;

  bool get _canSubmit =>
      _selected != null && _controller.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) {
      CustomSnackBar1.show(
        context,
        "Please select a reason and add a description",
      );
      return;
    }
    final reason = _selected!;
    final description = _controller.text.trim();
    final api = _apiOf(reason);

    final Map<String, dynamic> payload = _isChat
        ? {
            "user_id": widget.userId,
            "description": description,
            "type": "chat",
            "report_type": api,
          }
        : {
            "listing_id": widget.listingId,
            "description": description,
            "type": "listing",
            "report_type": api,
          };

    context.read<ReportAdCubit>().reportAd(payload);
  }

  @override
  Widget build(BuildContext context) {
    final bg = ThemeHelper.backgroundColor(context);
    final text = ThemeHelper.textColor(context);
    final card = ThemeHelper.cardColor(context);

    final hintStyle = AppTextStyles.bodyMedium(text.withOpacity(0.6));

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: BlocConsumer<ReportAdCubit, ReportAdStates>(
            listener: (context, state) {
              if (state is ReportAdSuccess) {
                CustomSnackBar1.show(
                  context,
                  state.result.message ?? 'Reported',
                );
                Navigator.of(context).maybePop();
              } else if (state is ReportAdFailure) {
                CustomSnackBar1.show(context, state.error);
              }
            },
            builder: (context, state) {
              final isLoading = state is ReportAdLoading;
              return AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with close
                      SizedBox(
                        height: 48,
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            Center(
                              child: Text(
                                'Report',
                                style: AppTextStyles.titleLarge(
                                  text,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                icon: Icon(Icons.close, color: text),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Reasons (context-aware: Listing vs Chat)
                      Container(
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black.withOpacity(
                              ThemeHelper.isDarkMode(context) ? 0.2 : 0.06,
                            ),
                          ),
                        ),
                        child: Column(
                          children: _activeReasons.map((r) {
                            return RadioListTile<Object>(
                              value: r,
                              groupValue: _selected,
                              dense: true,
                              onChanged: isLoading
                                  ? null
                                  : (v) => setState(() => _selected = v),
                              activeColor: const Color(0xFF0A5FD7),
                              title: Text(
                                _labelOf(r), // works for both enums
                                style: AppTextStyles.bodyMedium(text),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Text area with counter
                      Container(
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black.withOpacity(
                              ThemeHelper.isDarkMode(context) ? 0.2 : 0.06,
                            ),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              enabled: !isLoading,
                              maxLines: 6,
                              minLines: 4,
                              maxLength: _maxLen,
                              style: AppTextStyles.bodyMedium(text),
                              decoration: InputDecoration(
                                counterText: "",
                                hintText: 'Enter Description',
                                hintStyle: hintStyle,
                                contentPadding: const EdgeInsets.all(12),
                                border: InputBorder.none,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 10,
                                bottom: 8,
                              ),
                              child: Text(
                                '${_controller.text.length} / $_maxLen',
                                style: AppTextStyles.labelSmall(
                                  text.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: CustomAppButton1(
                          text: "Send complaint",
                          isLoading: isLoading,
                          onPlusTap: isLoading || !_canSubmit ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
