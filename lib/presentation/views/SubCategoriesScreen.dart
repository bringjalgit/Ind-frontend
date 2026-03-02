import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/data/cubit/subCategory/sub_category_state.dart';
import 'package:classifieds/model/CategoryModel.dart';
import '../../Components/Shimmers.dart';
import '../../data/cubit/subCategory/sub_category_cubit.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../utils/spinkittsLoader.dart';
import '../../widgets/CommonLoader.dart';

class SubCategoriesScreen extends StatefulWidget {
  final CategoriesList? categoriesList;
  const SubCategoriesScreen({super.key, required this.categoriesList});

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SubCategoryCubit>().getSubCategory(
      widget.categoriesList?.categoryId.toString() ?? "",
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);
    final bgColor = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          "${widget.categoriesList?.name ?? ""} Subcategories",
          style: AppTextStyles.headlineSmall(textColor),
        ),
      ),
      body: BlocBuilder<SubCategoryCubit, SubCategoryStates>(
        builder: (context, state) {
          if (state is SubCategoryLoading) {
            return const SubCategoryShimmer();
          } else if (state is SubCategoryLoaded) {
            final subcategories = state.subCategoryModel.subcategories;
            return CustomScrollView(
              slivers: [
                // ----- Banner -----
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: state.subCategoryModel.sub_category_banner != null
                        ? SizedBox(
                            height: 160,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl:
                                    state
                                        .subCategoryModel
                                        .sub_category_banner ??
                                    "",
                                fit: BoxFit.fill,
                                // placeholder: (context, url) => Center(
                                //   child: spinkits.getSpinningLinespinkit(),
                                // ),
                                errorWidget: (context, url, error) => Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SizedBox.shrink(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = subcategories?[index];
                      return InkWell(
                        onTap: () {
                          context.push(
                            "/products_list?subCategoryname=${item?.name ?? ""}&sub_categoryId=${item?.subCategoryId ?? ""}",
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Card(
                          color: ThemeHelper.cardColor(context),
                          margin: const EdgeInsets.all(
                            0,
                          ), // small margin for spacing
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          clipBehavior:
                              Clip.antiAlias, // ensures smooth rounded clipping
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Image / Top Section
                              Expanded(
                                flex: 2,
                                child: Container(
                                  color: ThemeHelper.isDarkMode(context)
                                      ? const Color(0xFF2A2A2A) // dark mode bg
                                      : const Color(
                                          0xFFEDF3FD,
                                        ), // light mode bg
                                  padding: EdgeInsets.all(12),
                                  child: CachedNetworkImage(
                                    imageUrl: item?.image ?? "",
                                    fit: BoxFit.contain,
                                    // placeholder: (context, url) => Center(
                                    //   child: spinkits.getSpinningLinespinkit(),
                                    // ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                  ),
                                ),
                              ),
                              // Text / Bottom Section
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                child: Text(
                                  "${item?.name}",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppTextStyles.bodyMedium(
                                        ThemeHelper.textColor(context),
                                      ).copyWith(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: subcategories?.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                  ),
                ),

                // ----- Bottom Spacing -----
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          } else {
            return Center(child: Text("No data Found"));
          }
        },
      ),
    );
  }


}

class SubCategoryShimmer extends StatelessWidget {
  const SubCategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = ThemeHelper.backgroundColor(context);

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [

        /// ----- Banner Shimmer -----
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: shimmerRectangle(
              width: double.infinity,
              height: 160,
              context: context,
              radius: 4,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        /// ----- Grid Shimmer -----
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return const SubCategoryCardShimmer();
              },
              childCount: 6, // number of shimmer items
            ),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

class SubCategoryCardShimmer extends StatelessWidget {
  const SubCategoryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);

    return Card(
      color: ThemeHelper.cardColor(context),
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          /// IMAGE SECTION (Flex 2 look)
          Expanded(
            flex: 2,
            child: Container(
              color: isDark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFEDF3FD),
              padding: const EdgeInsets.all(12),
              child: Center(
                child: shimmerRectangle(
                  width: 70,
                  height: 70,
                  context: context,
                  radius: 12,
                ),
              ),
            ),
          ),

          /// TEXT SECTION
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            child: Column(
              children: [
                shimmerText(
                  width: double.infinity,
                  height: 14,
                  context: context,
                ),
                const SizedBox(height: 6),
                shimmerText(
                  width: 80,
                  height: 14,
                  context: context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
