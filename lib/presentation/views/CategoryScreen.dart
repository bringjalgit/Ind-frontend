import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/data/cubit/Categories/categories_states.dart';
import '../../data/cubit/Categories/categories_cubit.dart';
import '../../data/cubit/PostCategories/categories_cubit.dart';
import '../../data/cubit/PostCategories/categories_states.dart';
import '../../Components/Shimmers.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../utils/spinkittsLoader.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PostCategoriesCubit>().getPostCategories();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final bgColor = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);
    final cardColor = isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9);
    final mutedColor =
        isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What are you posting?',
              style: AppTextStyles.headlineMedium(textColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a category to continue',
              style: AppTextStyles.bodyMedium(Colors.grey),
            ),
            const SizedBox(height: 20),
            BlocBuilder<PostCategoriesCubit, PostCategoriesStates>(
              builder: (context, state) {
                if (state is PostCategoriesLoading) {
                  return _CategoryListSkeleton(
                    cardColor: cardColor,
                    borderColor: borderColor,
                  );
                } else if (state is PostCategoriesLoaded) {
                  final categories = state.categoryModel.categoriesList;
                  if (categories == null || categories.isEmpty) {
                    return const Expanded(
                      child: Center(child: Text('No categories available')),
                    );
                  }
                  return Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 3.0,
                      ),
                      itemBuilder: (context, index) {
                        final categoryItem = categories[index];
                        return _CategoryCard(
                          imageUrl: categoryItem.image ?? '',
                          name: categoryItem.name ?? 'Unknown',
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          mutedColor: mutedColor,
                          onTap: () {
                            context.push(
                              '/select_sub_categories?categoryId=${categoryItem.categoryId ?? ""}&categoryName=${categoryItem.name ?? ""}',
                            );
                          },
                        );
                      },
                    ),
                  );
                } else if (state is PostCategoriesFailure) {
                  return Expanded(
                    child: Center(child: Text(state.error ?? '')),
                  );
                }
                return const Expanded(
                  child: Center(child: Text('No Data')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 2-col grid card — icon top-left, name below. Mirrors the Option D
/// mockup. Subtitle is omitted because the backend doesn't return one.
class _CategoryCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.imageUrl,
    required this.name,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isEmpty
                    ? Icon(Icons.category_outlined, color: mutedColor, size: 22)
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => Center(
                          child: spinkits.getSpinningLinespinkit(),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.broken_image_outlined,
                          color: mutedColor,
                          size: 22,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading skeleton — same 2-col grid shape as `_CategoryCard` so the
/// page doesn't visually jump when data arrives.
class _CategoryListSkeleton extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;
  const _CategoryListSkeleton({
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: 8,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3.0,
        ),
        itemBuilder: (_, __) => shimmerRectangle(
          width: double.infinity,
          height: double.infinity,
          context: context,
          radius: 14,
        ),
      ),
    );
  }
}
