import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/data/cubit/Wishlist/wishlist_cubit.dart';
import 'package:classifieds/data/cubit/Wishlist/wishlist_states.dart';

import '../../Components/CustomSnackBar.dart';
import '../../Components/Shimmers.dart';
import '../../data/cubit/AddToWishlist/addToWishlistCubit.dart';
import '../../data/cubit/AddToWishlist/addToWishlistStates.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../utils/AppLogger.dart';
import '../../utils/media_query_helper.dart';
import '../../widgets/CommonLoader.dart';
import '../../widgets/ProductCard.dart';

class WishlistListScreen extends StatefulWidget {
  const WishlistListScreen({super.key});

  @override
  State<WishlistListScreen> createState() => _WishlistListScreenState();
}

class _WishlistListScreenState extends State<WishlistListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<WishlistCubit>().getWishlist();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<WishlistCubit>().getMoreWishlist();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final bgColor = ThemeHelper.backgroundColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Favourites List',
          style: AppTextStyles.headlineSmall(textColor),
        ),
        actions: [
          // GestureDetector(
          //   onTap: () {
          //     context.push('/filter');
          //   },
          //   child: Icon(Icons.tune, color: textColor),
          // ),
          // const SizedBox(width: 16),
        ],
      ),

      body: BlocListener<AddToWishlistCubit, AddToWishlistStates>(
        listener: (context, state) {
          if (state is AddToWishlistLoaded) {
            // API returned success → update ProductsCubit
            context.read<WishlistCubit>().updateWishlistStatus(
              state.product_id,
              state.addToWishlistModel.liked ?? false,
            );
          } else if (state is AddToWishlistFailure) {
            CustomSnackBar1.show(context, state.error);
          }
        },
        child: BlocBuilder<WishlistCubit, WishlistStates>(
          builder: (context, state) {
            if (state is WishlistLoading) {
              return const WishlistShimmer();
            }else if (state is WishlistFailure) {
              return Center(child: Text(state.error));
            } else if (state is WishlistLoaded ||
                state is WishlistLoadingMore) {
              final wishlistModel = (state as dynamic).wishlistModel;
              final products = wishlistModel.productslist ?? [];
              final hasNextPage = (state as dynamic).hasNextPage;

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/nodata/no_data.png',
                        width: SizeConfig.screenWidth * 0.22,
                        height: SizeConfig.screenHeight * 0.12,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Favorites Found!',
                        style: AppTextStyles.headlineSmall(textColor),
                      ),
                    ],
                  ),
                );
              }

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == products.length) {
                          // Loader at bottom for pagination
                          return hasNextPage
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final product = products[index];
                        AppLogger.info("${product.location}");
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ProductCard(
                            products: product,
                            onWishlistToggle: () {
                              if (product.id != null) {
                                context
                                    .read<AddToWishlistCubit>()
                                    .addToWishlist(product.id!);
                              }
                            },
                          ),
                        );
                      }, childCount: products.length + 1),
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
}

class WishlistShimmer extends StatelessWidget {
  const WishlistShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: WishlistProductCardShimmer(),
                );
              },
              childCount: 6, // number of shimmer items
            ),
          ),
        ),
      ],
    );
  }
}

class WishlistProductCardShimmer extends StatelessWidget {
  const WishlistProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final cardColor = ThemeHelper.isDarkMode(context)
        ? Colors.grey[900]
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// LEFT IMAGE SECTION
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [

                  /// Main image shimmer
                  shimmerRectangle(
                    width: 120,
                    height: 120,
                    context: context,
                    radius: 0,
                  ),

                  /// Featured tag placeholder
                  Positioned(
                    top: 0,
                    left: 0,
                    child: shimmerRectangle(
                      width: 80,
                      height: 24,
                      context: context,
                      radius: 0,
                    ),
                  ),

                  /// Wishlist icon placeholder
                  Positioned(
                    top: 8,
                    right: 8,
                    child: shimmerCircle(30, context),
                  ),
                ],
              ),
            ),
          ),

          /// RIGHT CONTENT SECTION
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// TITLE
                  shimmerText(
                    width: double.infinity,
                    height: 16,
                    context: context,
                  ),

                  const SizedBox(height: 6),

                  /// LOCATION ROW
                  Row(
                    children: [
                      shimmerCircle(15, context),
                      const SizedBox(width: 4),
                      Expanded(
                        child: shimmerText(
                          width: double.infinity,
                          height: 14,
                          context: context,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// PRICE
                  shimmerText(
                    width: 90,
                    height: 16,
                    context: context,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}