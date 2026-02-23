import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/Components/CustomSnackBar.dart';
import 'package:classifieds/services/AuthService.dart';
import '../../Components/CustomAppButton.dart';
import '../../data/cubit/AddToWishlist/addToWishlistCubit.dart';
import '../../data/cubit/AddToWishlist/addToWishlistStates.dart';
import '../../data/cubit/Categories/categories_cubit.dart';
import '../../data/cubit/Categories/categories_states.dart';
import '../../data/cubit/City/city_cubit.dart';
import '../../data/cubit/City/city_state.dart';
import '../../data/cubit/Products/Product_cubit2.dart';
import '../../data/cubit/Products/products_state2.dart';
import '../../data/cubit/States/states_cubit.dart';
import '../../data/cubit/States/states_state.dart';
import '../../services/MetaEventTracker.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../widgets/CommonLoader.dart';
import '../../widgets/ProductCard.dart';

class ProductsListScreen extends StatefulWidget {
  final String subCategoryId;
  final String subCategoryname;
  const ProductsListScreen({
    super.key,
    required this.subCategoryId,
    required this.subCategoryname,
  });

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final ScrollController _scrollController = ScrollController();

  // ⬇️ Filter state lives here now
  final ValueNotifier<int> _currentFilterTab = ValueNotifier(0);
  final ValueNotifier<RangeValues> _selectedRange = ValueNotifier(
    const RangeValues(100, 10000000),
  );
  final ValueNotifier<List<String>> _selectedCategories = ValueNotifier([]);
  final ValueNotifier<String?> _selectedSort = ValueNotifier(null);
  final ValueNotifier<int?> _selectedStateId = ValueNotifier(null);
  final ValueNotifier<int?> _selectedCityId = ValueNotifier(null);
  final minPriceController = TextEditingController();
  final maxPriceController = TextEditingController();
  final citySearchController = TextEditingController();
  final stateSearchController = TextEditingController();
  final double _minPrice = 100;
  final double _maxPrice = 10000000;
  Timer? _debounce;

  final List<String> _tabs = ["Category", "Price", "Sort By", "States", "City"];

  @override
  void initState() {
    super.initState();

    // prime lists needed in filters so sheet is instant
    context.read<CategoriesCubit>().getCategories();
    context.read<SelectStatesCubit>().getSelectStates("");

    context.read<ProductsCubit2>().getProducts(
      subCategoryId: widget.subCategoryId,
    );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<ProductsCubit2>().getMoreProducts();
      }
    });

    citySearchController.addListener(() => setState(() {}));
    stateSearchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _currentFilterTab.dispose();
    _selectedRange.dispose();
    _selectedCategories.dispose();
    _selectedSort.dispose();
    _selectedStateId.dispose();
    _selectedCityId.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    citySearchController.dispose();
    stateSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _openFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeHelper.backgroundColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final textColor = ThemeHelper.textColor(context);
        final bg = ThemeHelper.backgroundColor(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Filters",
                    style: AppTextStyles.headlineSmall(textColor),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      children: [
                        // Tabs (left)
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.38,
                          child: ValueListenableBuilder<int>(
                            valueListenable: _currentFilterTab,
                            builder: (context, selectedIndex, _) {
                              return ValueListenableBuilder<int?>(
                                valueListenable: _selectedStateId,
                                builder: (context, stateId, __) {
                                  // Hide "City" until state is selected
                                  final visibleTabs = _tabs.where((t) {
                                    if (t == "City" && stateId == null)
                                      return false;
                                    return true;
                                  }).toList();

                                  return ListView.builder(
                                    controller: scrollController,
                                    itemCount: visibleTabs.length,
                                    itemBuilder: (context, i) {
                                      final tab = visibleTabs[i];
                                      final isSelected =
                                          visibleTabs.indexOf(tab) ==
                                          selectedIndex;
                                      return ListTile(
                                        selected: isSelected,
                                        selectedTileColor: Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.12),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(10),
                                            bottomRight: Radius.circular(10),
                                          ),
                                        ),
                                        title: Text(
                                          tab,
                                          style: AppTextStyles.bodyMedium(
                                            textColor,
                                          ),
                                        ),
                                        onTap: () => _currentFilterTab.value =
                                            visibleTabs.indexOf(tab),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // Divider
                        Container(
                          width: 1,
                          color: Colors.grey.withOpacity(0.2),
                        ),

                        // Content (right)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: ValueListenableBuilder<int>(
                              valueListenable: _currentFilterTab,
                              builder: (context, selectedIndex, _) {
                                // Map selectedIndex to actual tab in case "City" is hidden
                                final effectiveTabs =
                                    _selectedStateId.value == null
                                    ? _tabs.where((t) => t != "City").toList()
                                    : _tabs;
                                final tab = effectiveTabs[selectedIndex];

                                switch (tab) {
                                  case "Category":
                                    return _buildCategoryWidget();
                                  case "Price":
                                    return _buildPriceWidget();
                                  case "Sort By":
                                    return _buildSortByWidget();
                                  case "States":
                                    return _buildStatesWidget();
                                  case "City":
                                    return _buildCityWidget();
                                  default:
                                    return const SizedBox.shrink();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomAppButton(
                            text: "Clear All",
                            onPlusTap: () {
                              _selectedCategories.value = []; // notify!
                              _selectedSort.value = null;
                              _selectedStateId.value = null;
                              _selectedCityId.value = null;
                              minPriceController.clear();
                              maxPriceController.clear();
                              _selectedRange.value = RangeValues(
                                _minPrice,
                                _maxPrice,
                              );
                              if (_currentFilterTab.value == 4) {
                                _currentFilterTab.value = 0;
                              }
                              // fetch with no filters
                              context.read<ProductsCubit2>().getProducts(
                                subCategoryId: widget.subCategoryId,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomAppButton1(
                            text: "Apply",
                            onPlusTap: () {
                              final categoryIds = _selectedCategories.value;
                              final filters = {
                                "categoryId": categoryIds.isNotEmpty
                                    ? categoryIds.join(",")
                                    : null,
                                "sort_by": _selectedSort.value,
                                "state_id": _selectedStateId.value?.toString(),
                                "city_id": _selectedCityId.value?.toString(),
                                "minPrice": minPriceController.text.isNotEmpty
                                    ? minPriceController.text
                                    : _selectedRange.value.start
                                          .toInt()
                                          .toString(),
                                "maxPrice": maxPriceController.text.isNotEmpty
                                    ? maxPriceController.text
                                    : _selectedRange.value.end
                                          .toInt()
                                          .toString(),
                              };

                              context.read<ProductsCubit2>().getProducts(
                                subCategoryId: categoryIds.isEmpty
                                    ? widget.subCategoryId
                                    : null,
                                categoryId: categoryIds.isNotEmpty
                                    ? filters["categoryId"]
                                    : null,
                                sort_by: filters["sort_by"],
                                state_id: filters["state_id"],
                                city_id: filters["city_id"],
                                minPrice: filters["minPrice"],
                                maxPrice: filters["maxPrice"],
                              );

                              Navigator.pop(context); // close sheet
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final bgColor = ThemeHelper.backgroundColor(context);

    return FutureBuilder(
      future: AuthService.isGuest,
      builder: (context, asyncSnapshot) {
        final isGuest = asyncSnapshot.data ?? false;
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
              widget.subCategoryname.isNotEmpty
                  ? widget.subCategoryname
                  : "Products List",
              style: AppTextStyles.headlineSmall(textColor),
            ),
            actions: [
              // OPEN SHEET INSTEAD OF PUSHING A ROUTE
              GestureDetector(
                onTap: _openFiltersSheet,
                child: Icon(Icons.tune, color: textColor),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: BlocListener<AddToWishlistCubit, AddToWishlistStates>(
            listener: (context, state) {
              if (state is AddToWishlistLoaded) {
                context.read<ProductsCubit2>().updateWishlistStatus(
                  state.product_id,
                  state.addToWishlistModel.liked ?? false,
                );
              } else if (state is AddToWishlistFailure) {
                CustomSnackBar1.show(context, state.error);
              }
            },
            child: BlocBuilder<ProductsCubit2, ProductsStates2>(
              builder: (context, state) {
                if (state is Products2Loading) {
                  return Center(child: DottedProgressWithLogo());
                } else if (state is Products2Failure) {
                  return Center(child: Text(state.error));
                } else if (state is Products2Loaded ||
                    state is Products2LoadingMore) {
                  final productsModel = (state as dynamic).productsModel;
                  final products = productsModel.products ?? [];
                  final hasNextPage = (state as dynamic).hasNextPage;

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/nodata/no_data.png',
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: MediaQuery.of(context).size.height * 0.15,
                          ),
                          Text(
                            'No Products Found!',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: ThemeHelper.textColor(context),
                            ),
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
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            if (index == products.length) {
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
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ProductCard(
                                products: product,
                                onWishlistToggle: isGuest
                                    ? () => context.push("/login")
                                    : () async {
                                        if (product.id != null) {
                                          context.read<AddToWishlistCubit>().addToWishlist(product.id!);
                                          await MetaEventTracker.addToWishlist(
                                              product.id.toString()
                                          );
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
      },
    );
  }

  // -------------------------
  // FILTER WIDGETS (same logic as your FilterScreen)
  // -------------------------

  Widget _buildCategoryWidget() {
    return BlocBuilder<CategoriesCubit, CategoriesStates>(
      builder: (context, state) {
        if (state is CategoriesLoading) {
          return const Center(child: DottedProgressWithLogo());
        } else if (state is CategoriesLoaded) {
          final categories = state.categoryModel.categoriesList;
          final textColor = ThemeHelper.textColor(context);
          if (categories == null || categories.isEmpty) {
            return const Center(child: Text("No Categories Found"));
          }
          return ValueListenableBuilder<List<String>>(
            valueListenable: _selectedCategories,
            builder: (context, selected, _) {
              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final categoryItem = categories[index];
                  final idStr = categoryItem.categoryId.toString();
                  final isSelected = selected.contains(idStr);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      final updated = List<String>.from(selected);
                      if (val == true) {
                        updated.add(idStr);
                      } else {
                        updated.remove(idStr);
                      }
                      _selectedCategories.value = updated; // notify
                    },
                    title: Text(
                      categoryItem.name ?? "Unknown",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.blue : textColor,
                      ),
                    ),
                  );
                },
              );
            },
          );
        } else if (state is CategoriesFailure) {
          return Center(child: Text(state.error ?? "Something went wrong"));
        }
        return const Center(child: Text("No Data"));
      },
    );
  }

  // Widget _buildPriceWidget() {
  //   final priceRanges = [
  //     {"label": "Below Rs.1000", "min": 0, "max": 1000},
  //     {"label": "Rs.1001 - 5000", "min": 1001, "max": 5000},
  //     {"label": "Rs.5001 - 10000", "min": 5001, "max": 10000},
  //     {"label": "Rs.10001 - 25000", "min": 10001, "max": 25000},
  //     {"label": "Rs.25001 - 50000", "min": 25001, "max": 50000},
  //     {"label": "Above Rs.50000", "min": 50001, "max": 1000000},
  //   ];
  //
  //   return ValueListenableBuilder<RangeValues>(
  //     valueListenable: _selectedRange,
  //     builder: (context, range, _) {
  //       final textColor = ThemeHelper.textColor(context);
  //       return SingleChildScrollView(
  //         child: Column(
  //           children: [
  //             ...priceRanges.map((r) {
  //               final isSelected =
  //                   range.start.toInt() == r["min"] &&
  //                   (r["max"] == null || range.end.toInt() == r["max"]);
  //               return CheckboxListTile(
  //                 value: isSelected,
  //                 onChanged: (val) {
  //                   if (val == true) {
  //                     _selectedRange.value = RangeValues(
  //                       ((r["min"] as num?) ?? _minPrice).toDouble(),
  //                       ((r["max"] as num?) ?? _maxPrice).toDouble(),
  //                     );
  //                   } else {
  //                     _selectedRange.value = RangeValues(_minPrice, _maxPrice);
  //                   }
  //                 },
  //                 title: Text(
  //                   r["label"] as String,
  //                   style: AppTextStyles.titleSmall(textColor),
  //                 ),
  //               );
  //             }),
  //             const SizedBox(height: 20),
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: TextField(
  //                     style: TextStyle(color: textColor),
  //                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  //                     keyboardType: TextInputType.number,
  //                     controller: minPriceController,
  //                     decoration: const InputDecoration(
  //                       hintText: "Min",
  //                       border: OutlineInputBorder(),
  //                     ),
  //                     onChanged: (val) {
  //                       final minVal = int.tryParse(val) ?? _minPrice.toInt();
  //                       _selectedRange.value = RangeValues(
  //                         minVal.toDouble(),
  //                         range.end,
  //                       );
  //                     },
  //                   ),
  //                 ),
  //                 const SizedBox(width: 10),
  //                 Expanded(
  //                   child: TextField(
  //                     style: TextStyle(color: textColor),
  //                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  //                     keyboardType: TextInputType.number,
  //                     controller: maxPriceController,
  //                     decoration: const InputDecoration(
  //                       hintText: "Max",
  //                       border: OutlineInputBorder(),
  //                     ),
  //                     onChanged: (val) {
  //                       final maxVal = int.tryParse(val) ?? _maxPrice.toInt();
  //                       _selectedRange.value = RangeValues(
  //                         range.start,
  //                         maxVal.toDouble(),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildPriceWidget() {
    final double priceMin = _minPrice; // e.g., 100 (must be > 0 for log)
    final double priceMax = _maxPrice; // e.g., 10000000
    const double uiMin = 0.0;
    const double uiMax = 1000.0; // UI resolution
    const int uiDivisions = 1000; // increase for finer control

    // map rupee price -> UI position (log scale)
    double _toUi(double price) {
      final lp = math.log(price);
      final lmn = math.log(priceMin);
      final lmx = math.log(priceMax);
      final t = (lp - lmn) / (lmx - lmn); // 0..1
      return uiMin + t * (uiMax - uiMin); // 0..1000
    }

    // map UI position -> rupee price (log scale)
    double _fromUi(double ui) {
      final t = ((ui - uiMin) / (uiMax - uiMin)).clamp(0.0, 1.0);
      final lmn = math.log(priceMin);
      final lmx = math.log(priceMax);
      final val = math.exp(lmn + t * (lmx - lmn));
      return val;
    }

    String _fmt(num n) => "₹${n.toInt()}";

    return ValueListenableBuilder<RangeValues>(
      valueListenable: _selectedRange, // still storing rupees
      builder: (context, priceRange, _) {
        final textColor = ThemeHelper.textColor(context);

        final uiRange = RangeValues(
          _toUi(priceRange.start),
          _toUi(priceRange.end),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // live labels in rupees
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(priceRange.start),
                  style: AppTextStyles.titleSmall(textColor),
                ),
                Text(
                  _fmt(priceRange.end),
                  style: AppTextStyles.titleSmall(textColor),
                ),
              ],
            ),
            const SizedBox(height: 8),

            RangeSlider(
              min: uiMin,
              max: uiMax,
              divisions:
                  uiDivisions, // smooth, precise control across the whole range
              values: uiRange,
              labels: RangeLabels(_fmt(priceRange.start), _fmt(priceRange.end)),
              onChanged: (uiVals) {
                double s = _fromUi(uiVals.start).roundToDouble(); // snap to ₹1
                double e = _fromUi(uiVals.end).roundToDouble();
                if (s > e) s = e;
                // clamp for safety
                s = s.clamp(priceMin, priceMax);
                e = e.clamp(priceMin, priceMax);
                _selectedRange.value = RangeValues(s, e);
              },
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    _selectedRange.value = RangeValues(priceMin, priceMax),
                child: const Text("Reset"),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortByWidget() {
    final sortOptions = [
      {"label": "Low to High", "value": "low_to_high"},
      {"label": "High to Low", "value": "high_to_low"},
    ];
    return ValueListenableBuilder<String?>(
      valueListenable: _selectedSort,
      builder: (context, sort, _) {
        return ListView(
          children: sortOptions.map((option) {
            final isSelected = sort == option["value"];
            return CheckboxListTile(
              value: isSelected,
              onChanged: (val) {
                _selectedSort.value = val == true ? option["value"] : null;
              },
              title: Text(option["label"]!),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatesWidget() {
    final textColor = ThemeHelper.textColor(context);
    return BlocBuilder<SelectStatesCubit, SelectStates>(
      builder: (context, state) {
        if (state is SelectStatesLoading) {
          return const Center(child: DottedProgressWithLogo());
        } else if (state is SelectStatesFailure) {
          return Center(
            child: Text(
              state.error,
              style: AppTextStyles.bodyMedium(textColor),
            ),
          );
        } else if (state is SelectStatesLoaded) {
          final states = state.selectStatesModel.data ?? [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: TextField(
                          cursorColor: textColor,
                          controller: stateSearchController,
                          style: AppTextStyles.bodyMedium(textColor),
                          decoration: InputDecoration(
                            hintText: "Search state...",
                            hintStyle: AppTextStyles.bodyMedium(textColor),
                            prefixIcon: Icon(Icons.search, color: textColor),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            _debounce?.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 500),
                              () {
                                context
                                    .read<SelectStatesCubit>()
                                    .getSelectStates(value);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (states.isEmpty)
                _emptyMessage("No states found")
              else
                Expanded(
                  child: ValueListenableBuilder<int?>(
                    valueListenable: _selectedStateId,
                    builder: (context, stateId, _) {
                      return ListView.builder(
                        itemCount: states.length,
                        itemBuilder: (context, index) {
                          final s = states[index];
                          final isSelected = stateId == s.id;
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              _selectedStateId.value = val == true
                                  ? s.id
                                  : null;
                              // refresh city list for selected state
                              context.read<SelectCityCubit>().getSelectCity(
                                _selectedStateId.value ?? 0,
                                "",
                              );
                            },
                            title: Text(
                              s.name ?? "Unknown",
                              style: AppTextStyles.bodyMedium(
                                isSelected ? Colors.blue : textColor,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildCityWidget() {
    final textColor = ThemeHelper.textColor(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: citySearchController,
              style: AppTextStyles.bodyMedium(textColor),
              decoration: InputDecoration(
                hintText: "Search city...",
                hintStyle: AppTextStyles.bodyMedium(textColor),
                prefixIcon: Icon(Icons.search, color: textColor),

                // ⬇️ the cancel icon inside the field
                suffixIcon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: citySearchController.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          key: const ValueKey('city_clear'),
                          tooltip: 'Clear',
                          icon: Icon(Icons.close, color: textColor),
                          onPressed: () {
                            citySearchController.clear();
                            _debounce?.cancel();
                            context.read<SelectCityCubit>().getSelectCity(
                              _selectedStateId.value ?? 0,
                              "",
                            );
                            // setState is optional because of the listener, but harmless
                            setState(() {});
                          },
                        ),
                ),

                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  context.read<SelectCityCubit>().getSelectCity(
                    _selectedStateId.value ?? 0,
                    value,
                  );
                });
              },
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<SelectCityCubit, SelectCity>(
            builder: (context, state) {
              if (state is SelectCityLoading) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 0.8),
                );
              } else if (state is SelectCityFailure) {
                return Center(
                  child: Text(
                    state.error,
                    style: AppTextStyles.bodyMedium(textColor),
                  ),
                );
              } else if (state is SelectCityLoaded ||
                  state is SelectCityLoadingMore) {
                final model = state is SelectCityLoaded
                    ? state.selectCityModel
                    : (state as SelectCityLoadingMore).selectCityModel;

                final cities = model.data ?? [];
                if (cities.isEmpty) return _emptyMessage("No cities found");

                return ValueListenableBuilder<int?>(
                  valueListenable: _selectedCityId,
                  builder: (context, cityId, _) {
                    return NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels >=
                                scrollInfo.metrics.maxScrollExtent * 0.9 &&
                            state is SelectCityLoaded &&
                            state.hasNextPage) {
                          context.read<SelectCityCubit>().getMoreCities(
                            _selectedStateId.value ?? 0,
                            citySearchController.text,
                          );
                        }
                        return false;
                      },
                      child: ListView.builder(
                        itemCount:
                            cities.length +
                            (state is SelectCityLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == cities.length &&
                              state is SelectCityLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 0.8,
                                ),
                              ),
                            );
                          }
                          final c = cities[index];
                          final isSelected = cityId == c.id;
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              _selectedCityId.value = val == true ? c.id : null;
                            },
                            title: Text(
                              c.name ?? "Unknown",
                              style: AppTextStyles.bodyMedium(
                                isSelected ? Colors.blue : textColor,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }
              return const Center(child: Text("No Data"));
            },
          ),
        ),
      ],
    );
  }

  Widget _emptyMessage(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/nodata/no_data.png',
            width: MediaQuery.of(context).size.width * 0.22,
            height: MediaQuery.of(context).size.height * 0.12,
          ),
          const SizedBox(height: 12),
          Text(
            msg,
            style: AppTextStyles.bodyMedium(ThemeHelper.textColor(context)),
          ),
        ],
      ),
    );
  }
}
