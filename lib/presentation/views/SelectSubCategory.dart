import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/Components/CutomAppBar.dart';
import 'package:classifieds/data/cubit/subCategory/sub_category_state.dart';
import 'package:classifieds/services/AuthService.dart';
import 'package:classifieds/widgets/CommonBackground.dart';

import '../../data/cubit/subCategory/sub_category_cubit.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../widgets/CommonLoader.dart';

class SelectSubCategory extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  const SelectSubCategory({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<SelectSubCategory> createState() => _SelectSubCategoryState();
}

class _SelectSubCategoryState extends State<SelectSubCategory> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubCategoryCubit>().getSubCategory(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);
    return FutureBuilder(
      future: AuthService.isGuest,
      builder: (context, asyncSnapshot) {
        final isGuest = asyncSnapshot.data ?? false;
        return Scaffold(
          backgroundColor: bgColor,
          appBar: CustomAppBar1(
            title: "${widget.categoryName ?? ""}",
            actions: [],
          ),
          body: Background1(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: BlocBuilder<SubCategoryCubit, SubCategoryStates>(
                builder: (context, state) {
                  if (state is SubCategoryLoading) {
                    return Center(child: DottedProgressWithLogo());
                  } else if (state is SubCategoryLoaded) {
                    final subcategories =
                        state.subCategoryModel.subcategories ?? [];

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Text(
                            'Select Subcategory',
                            style: AppTextStyles.headlineSmall(textColor),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 25)),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = subcategories[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  item.name ?? "",
                                  style: AppTextStyles.bodyLarge(textColor),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onTap: isGuest
                                    ? () {
                                        context.push("/login");
                                      }
                                    : () {
                                        if (item.description != null) {
                                          showSafetyDialog(
                                            context,
                                            message: item.description ?? "",
                                            id:
                                                item.subCategoryId.toString() ??
                                                "",
                                            name: item.name ?? "",
                                            path: item.path ?? "",
                                            category_id:
                                                widget.categoryId ?? "",
                                            category_name:
                                                widget.categoryName ?? "",
                                          );
                                        } else {
                                          context.push(
                                            '/${item.path}?catId=${widget.categoryId}&CatName=${widget.categoryName}&subCatId=${item.subCategoryId}&SubCatName=${item.name ?? ""}&editId=""',
                                          );
                                        }
                                      },
                              ),
                            );
                          }, childCount: subcategories.length),
                        ),
                      ],
                    );
                  } else if (state is SubCategoryFailure) {
                    return Center(
                      child: Text(
                        "Failed to load subcategories",
                        style: AppTextStyles.bodyMedium(textColor),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Call this to show it
  Future<void> showSafetyDialog(
    BuildContext context, {
    String message =
        "Showcase your local business and\nconnect with nearby partners for new\nopportunities!",
    String? name,
    String? id,
    String? path,
    String? category_id,
    String? category_name,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'dismiss',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            child: _SafetyDialog(
              message: message,
              id: id ?? "",
              name: name ?? "",
              path: path ?? "",
              category_id: category_id ?? "",
              category_name: category_name ?? "",
            ),
          ),
        );
      },
    );
  }
}

class _SafetyDialog extends StatelessWidget {
  final String message;
  final String name;
  final String id;
  final String path;
  final String category_id;
  final String category_name;

  const _SafetyDialog({
    super.key,
    required this.message,
    required this.name,
    required this.id,
    required this.path,
    required this.category_id,
    required this.category_name,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final cardBg = isDark ? const Color(0xFF2A2E35) : Colors.white;
    final textColor = ThemeHelper.textColor(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320, // ~like your screenshot
          padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Close (X)
              Positioned(
                right: 4,
                top: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    context.push(
                      '/${path}?catId=${category_id}&CatName=${category_name}&subCatId=${id}&SubCatName=${name ?? ""}&editId=""',
                    );
                    context.pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ),
              ),

              // Content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  _DocAlertIcon(color: textColor.withOpacity(0.55)),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMedium(
                      textColor,
                    ).copyWith(fontWeight: FontWeight.w600, height: 1.35),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon that mimics the “document + exclamation” look from your mock
class _DocAlertIcon extends StatelessWidget {
  final Color color;
  const _DocAlertIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: 56,
      child: Image.asset("assets/images/notetext.png"),
      // Stack(
      //   alignment: Alignment.center,
      //   children: [
      //     Icon(Icons.description_outlined, size: 44, color: color),
      //     Positioned(
      //       right: 6,
      //       bottom: 6,
      //       child: Container(
      //         width: 22,
      //         height: 22,
      //         decoration: BoxDecoration(
      //           color: color.withOpacity(0.10),
      //           shape: BoxShape.circle,
      //         ),
      //         alignment: Alignment.center,
      //         child: Icon(Icons.error_outline, size: 16, color: color),
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}
