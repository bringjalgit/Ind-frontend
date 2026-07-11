import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:classifieds/Components/CutomAppBar.dart';
import 'package:classifieds/theme/app_colors.dart';
import 'package:intl/intl.dart';

import '../../Components/Shimmers.dart';
import '../../data/cubit/UserActivePlans/user_active_plans_cubit.dart';
import '../../data/cubit/UserActivePlans/user_active_plans_states.dart';
import '../../model/UserActivePlansModel.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';

class ActivePlansScreen extends StatefulWidget {
  const ActivePlansScreen({Key? key}) : super(key: key);

  @override
  State<ActivePlansScreen> createState() => _ActivePlansScreenState();
}

class _ActivePlansScreenState extends State<ActivePlansScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserActivePlanCubit>().getUserActivePlansData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeHelper.backgroundColor(context),
      appBar: CustomAppBar1(title: 'Active Plans', actions: []),
      body: BlocBuilder<UserActivePlanCubit, UserActivePlanStates>(
        builder: (context, state) {
          if (state is UserActivePlanLoading) {
            return activePlansShimmer(context);
          } else if (state is UserActivePlanLoaded) {
            final plans = state.userActivePlansModel.plans ?? [];
            if (plans.isEmpty) {
              return Center(
                child: Text(
                  'No active plans found',
                  style: AppTextStyles.bodyLarge(
                    ThemeHelper.textColor(context),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return PlanCard(plan: plan);
              },
            );
          } else if (state is UserActivePlanFailure) {
            return Center(
              child: Text(
                'Error: ${state.error}',
                style: AppTextStyles.bodyLarge(Colors.red),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget activePlansShimmer(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4, // number of shimmer cards
      itemBuilder: (context, index) {
        return activePlanCardShimmer(context);
      },
    );
  }

  /// ============================================================
  /// ACTIVE PLAN CARD SHIMMER
  /// Matches PlanCard UI exactly
  /// ============================================================

  Widget activePlanCardShimmer(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.grey[900]!, Colors.grey[850]!]
                : [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP ROW (Icon + Title + Badge)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      shimmerCircle(24, context),
                      const SizedBox(width: 10),
                      shimmerText(width: 160, height: 18, context: context),
                    ],
                  ),

                  shimmerRectangle(
                    width: 80,
                    height: 28,
                    radius: 12,
                    context: context,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// Remaining Row
              Row(
                children: [
                  shimmerCircle(20, context),
                  const SizedBox(width: 10),
                  shimmerText(width: 200, context: context),
                ],
              ),

              const SizedBox(height: 12),

              /// Start Date
              Row(
                children: [
                  shimmerCircle(18, context),
                  const SizedBox(width: 10),
                  shimmerText(width: 180, context: context),
                ],
              ),

              const SizedBox(height: 8),

              /// End Date
              Row(
                children: [
                  shimmerCircle(18, context),
                  const SizedBox(width: 10),
                  shimmerText(width: 180, context: context),
                ],
              ),

              const SizedBox(height: 18),

              /// Progress Bar
              shimmerRectangle(
                width: double.infinity,
                height: 8,
                radius: 8,
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  final Plans plan;

  const PlanCard({Key? key, required this.plan}) : super(key: key);

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.grey[900]!, Colors.grey[850]!]
                : [Colors.white, Colors.blue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Icon(
                          Icons.subscriptions,
                          color: isDark ? Colors.blue[300] : Colors.blue[700],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            plan.planName ?? 'Unknown Plan',
                            style: AppTextStyles.titleLarge(
                              ThemeHelper.textColor(context),
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blue[900] : Colors.blue[200],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      plan.packageName ?? 'N/A',
                      style: AppTextStyles.labelMedium(
                        isDark ? Colors.white : Colors.blue[900]!,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.numbers,
                    color: ThemeHelper.textColor(context).withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remaining: ${plan.remaining ?? 0}',
                    style: AppTextStyles.bodyMedium(
                      ThemeHelper.textColor(context),
                    ).copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: ThemeHelper.textColor(context).withOpacity(0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Start: ${_formatDate(plan.startDate)}',
                    style: AppTextStyles.bodySmall(
                      ThemeHelper.textColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.event_busy,
                    color: ThemeHelper.textColor(context).withOpacity(0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'End: ${_formatDate(plan.endDate)}',
                    style: AppTextStyles.bodySmall(
                      ThemeHelper.textColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder(
                tween: Tween<double>(
                  begin: 0,
                  end: plan.remaining != null && plan.remaining! > 0
                      ? 1.0
                      : 0,
                ),
                duration: const Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? Colors.grey[700]
                          : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.blue[400]! : Colors.blue[600]!,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
