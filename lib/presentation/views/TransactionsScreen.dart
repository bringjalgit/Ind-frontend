import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/Components/CutomAppBar.dart';
import 'package:classifieds/data/cubit/Transections/transactions_cubit.dart';
import 'package:classifieds/data/cubit/Transections/transactions_states.dart';
import 'package:classifieds/model/TransectionHistoryModel.dart';
import '../../Components/Shimmers.dart';
import '../../theme/ThemeHelper.dart';
import '../../widgets/CommonLoader.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<TransactionCubit>().getTransactions();

    _scrollController.addListener(() {
      // Optionally use the scroll controller here if needed for any logic
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(context),
      appBar: CustomAppBar1(title: "Transaction History", actions: []),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          // Check if we've reached the bottom
          if (scrollNotification is ScrollEndNotification &&
              _scrollController.position.pixels ==
                  _scrollController.position.maxScrollExtent) {
            // Call the method to load more transactions
            context.read<TransactionCubit>().getMoreTransactions();
          }
          return false; // Return false so that other notifications can be processed
        },
        child: BlocBuilder<TransactionCubit, TransactionsStates>(
          builder: (context, state) {
            if (state is TransactionsLoading) {
              return transactionHistoryShimmer(context);
            } else if (state is TransactionsFailure) {
              return Center(child: Text(state.error));
            } else if (state is TransactionsLoaded ||
                state is TransactionsLoadingMore) {
              final model = (state as dynamic).transactionModel;
              final rows = model.data?.formattedRows ?? [];
              final hasNextPage = (state as dynamic).hasNextPage;

              if (rows.isEmpty) {
                return const Center(child: Text("No transactions found"));
              }

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == rows.length) {
                            return hasNextPage
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }
                          final FormattedRows tx = rows[index];
                          final bool isSuccess =
                              (tx.paymentStatus ?? "").toLowerCase() ==
                              "success";

                          return Card(
                            color: ThemeHelper.cardColor(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              title: Text(
                                // Only show planName if it's available and not for 'boost' type
                                tx.type != 'boost' && tx.planName != null
                                    ? tx.planName ?? "Unknown Plan"
                                    : "Boost Plan", // Use this for boost or handle empty cases
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ThemeHelper.textColor(context),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(
                                    "Amount: \₹${tx.amountPaid ?? 0}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: ThemeHelper.textColor(
                                        context,
                                      ).withOpacity(0.8),
                                    ),
                                  ),
                                  if (tx.paidOn != null)
                                    Text(
                                      "Paid on: ${tx.paidOn!.split("T").first}",
                                      style: TextStyle(
                                        color: ThemeHelper.textColor(
                                          context,
                                        ).withOpacity(0.6),
                                      ),
                                    ),
                                  if (tx.startDate != null &&
                                      tx.endDate != null)
                                    Text(
                                      "Valid: ${tx.startDate} → ${tx.endDate}",
                                      style: TextStyle(
                                        color: ThemeHelper.textColor(
                                          context,
                                        ).withOpacity(0.6),
                                      ),
                                    ),
                                  // Additional details based on type
                                  if (tx.type == 'boost')
                                    Text(
                                      "Boost Type: ${tx.listingTitle ?? 'N/A'}",
                                      style: TextStyle(
                                        color: ThemeHelper.textColor(
                                          context,
                                        ).withOpacity(0.6),
                                      ),
                                    ),
                                  if (tx.type == 'package')
                                    Text(
                                      "Package: ${tx.packageName ?? 'N/A'}",
                                      style: TextStyle(
                                        color: ThemeHelper.textColor(
                                          context,
                                        ).withOpacity(0.6),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSuccess
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  (tx.paymentStatus ?? "").toUpperCase(),
                                  style: TextStyle(
                                    color: isSuccess
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount:
                            rows.length + 1, // Add 1 for the loading indicator
                      ),
                    ),
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget transactionHistoryShimmer(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => transactionCardShimmer(context),
              childCount: 6, // number of shimmer cards
            ),
          ),
        ),
      ],
    );
  }

  /// ============================================================
  /// TRANSACTION HISTORY SHIMMER
  /// Matches your Transaction Card UI
  /// ============================================================

  Widget transactionCardShimmer(BuildContext context) {
    return Card(
      color: ThemeHelper.cardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LEFT CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  shimmerText(width: 180, height: 16, context: context),
                  const SizedBox(height: 10),

                  shimmerText(width: 120, height: 14, context: context),
                  const SizedBox(height: 6),

                  shimmerText(width: 150, height: 12, context: context),
                  const SizedBox(height: 6),

                  shimmerText(width: 200, height: 12, context: context),
                ],
              ),
            ),

            const SizedBox(width: 12),

            /// RIGHT STATUS BADGE
            shimmerRectangle(
              width: 80,
              height: 30,
              radius: 8,
              context: context,
            ),
          ],
        ),
      ),
    );
  }
}
