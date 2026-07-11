import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/cubit/Products/Product_cubit1.dart';
import '../data/cubit/Products/products_state1.dart';
import '../model/SubcategoryProductsModel.dart';
import '../theme/AppTextStyles.dart';
import '../theme/ThemeHelper.dart';
import '../utils/media_query_helper.dart';
import 'SimilarProductCard.dart';

class SimilarProductsSection extends StatefulWidget {
  final String subCategoryId;
  final String? excludeId;
  final void Function(Products product) onTap;

  const SimilarProductsSection({
    super.key,
    required this.subCategoryId,
    required this.excludeId,
    required this.onTap,
  });

  @override
  State<SimilarProductsSection> createState() => _SimilarProductsSectionState();
}

class _SimilarProductsSectionState extends State<SimilarProductsSection> {
  final _scrollCtrl = ScrollController();
  bool _attachedListener = false;

  ProductsCubit1 get _cubit => context.read<ProductsCubit1>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.getProducts(subCategoryId: widget.subCategoryId);
      _attachListenerIfNeeded();
    });
  }

  void _attachListenerIfNeeded() {
    if (_attachedListener) return;
    _attachedListener = true;

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        _cubit.getMoreProducts(widget.subCategoryId);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final borderColor = ThemeHelper.isDarkMode(context)
        ? Colors.white12
        : Colors.black12;

    return BlocBuilder<ProductsCubit1, ProductsStates1>(
      builder: (context, state) {
        SubcategoryProductsModel? model;
        bool hasNextPage = false;
        if (state is Products1Loaded) {
          model = state.productsModel;
          hasNextPage = state.hasNextPage;
        } else if (state is Products1LoadingMore) {
          model = state.productsModel;
          hasNextPage = state.hasNextPage;
        }
        if (state is Products1Loading || state is Products1Initially) {
          // skeletons
          return ListView.separated(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => _SimilarSkeletonCard(),
          );
        }

        if (state is Products1Failure) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.error, style: AppTextStyles.bodyMedium(textColor)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      _cubit.getProducts(subCategoryId: widget.subCategoryId),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                ),
              ],
            ),
          );
        }

        final items = (model?.products ?? const <Products>[])
            .where((p) => p.id != null && p.id != widget.excludeId)
            .toList();

        if (items.isEmpty) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Similar Items",
                style: AppTextStyles.headlineSmall(
                  textColor,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(
              height: 230,
              child: ListView.separated(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                scrollDirection: Axis.horizontal,
                itemCount: items.length + (hasNextPage ? 1 : 0),
                separatorBuilder: (_, __) => SizedBox(width: 12),
                itemBuilder: (_, index) {
                  if (index >= items.length) {
                    return SizedBox(
                      width: 180,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: textColor.withOpacity(.8),
                          ),
                        ),
                      ),
                    );
                  }

                  final p = items[index];
                  return SimilarProductCard(
                    title: (p.title ?? "—").trim(),
                    planTier: p.planTier,
                    isFeatured: p.featured_status ?? false,
                    price: "₹${_formatINR(p.price)}",
                    location: (p.location ?? "").trim(),
                    imageUrl: p.image,
                    isLiked: p.isFavorited ?? false,
                    onLikeToggle: () {
                      if (p.id != null) {
                        final newVal = !(p.isFavorited ?? false);
                        _cubit.updateWishlistStatus(p.id!, newVal);
                      }
                    },
                    onTap: () {
                      context.pushReplacement(
                        "/products_details?listingId=${p.id}&subcategory_id=${p.subCategory}",
                      );
                    },
                    borderColor: borderColor,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ===== Utility formatting =====

  String _formatINR(String? price) {
    final val = double.tryParse(price ?? "");
    if (val == null) return "0";
    final f = NumberFormat.currency(
      locale: 'en_IN',
      symbol: "",
      decimalDigits: 0,
    );
    return f.format(val);
  }
}

class _SimilarSkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final card = ThemeHelper.cardColor(context);
    final borderColor = ThemeHelper.isDarkMode(context)
        ? Colors.white12
        : Colors.black12;

    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(color: borderColor.withOpacity(.2)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                children: [
                  Container(height: 14, color: borderColor.withOpacity(.2)),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 80,
                    color: borderColor.withOpacity(.2),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        color: borderColor.withOpacity(.2),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 12,
                          color: borderColor.withOpacity(.2),
                        ),
                      ),
                    ],
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
