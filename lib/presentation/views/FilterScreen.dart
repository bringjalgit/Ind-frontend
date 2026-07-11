import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:classifieds/Components/CustomAppButton.dart';
import 'package:classifieds/Components/CutomAppBar.dart';
import 'package:classifieds/utils/media_query_helper.dart';
import '../../data/cubit/Categories/categories_cubit.dart';
import '../../data/cubit/Categories/categories_states.dart';
import '../../data/cubit/City/city_cubit.dart';
import '../../data/cubit/City/city_state.dart';
import '../../data/cubit/Products/Product_cubit2.dart';
import '../../data/cubit/Products/products_cubit.dart';
import '../../data/cubit/States/states_cubit.dart';
import '../../data/cubit/States/states_state.dart';
import '../../theme/AppTextStyles.dart';
import '../../theme/ThemeHelper.dart';
import '../../utils/color_constants.dart';
import '../../widgets/CommonLoader.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({Key? key}) : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final ValueNotifier<int> currentSelectedFilterIndex = ValueNotifier(0);
  final ValueNotifier<RangeValues> selectedRange = ValueNotifier(
    const RangeValues(100, 10000000),
  );
  final ValueNotifier<List<String>> selectedCategories = ValueNotifier([]);
  final ValueNotifier<String?> selectedSort = ValueNotifier(null);
  final ValueNotifier<int?> selectedStateId = ValueNotifier(null);
  final ValueNotifier<int?> selectedCityId = ValueNotifier(null);
  final minPriceController = TextEditingController();
  final maxPriceController = TextEditingController();
  final cityController = TextEditingController();
  final stateSearchController = TextEditingController();

  final double minPrice = 100;
  final double maxPrice = 10000000;

  Timer? _debounce;

  final List<String> lblFilterTypesList = [
    "Category",
    "Price",
    "Sort By",
    "States",
    "City",
  ];

  @override
  void initState() {
    super.initState();
    context.read<CategoriesCubit>().getCategories();
    context.read<SelectStatesCubit>().getSelectStates("");
  }

  @override
  void dispose() {
    currentSelectedFilterIndex.dispose();
    selectedRange.dispose();
    selectedCategories.dispose();
    selectedSort.dispose();
    selectedStateId.dispose();
    selectedCityId.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    cityController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.textColor(context);
    final backgroundColor = ThemeHelper.backgroundColor(context);
    return Scaffold(
      appBar: CustomAppBar1(title: "Filters", actions: []),
      body: Stack(
        children: [
          PositionedDirectional(
            top: 10,
            bottom: 10,
            start: 10,
            end: (SizeConfig.screenWidth * 0.6) - 10,
            child: ValueListenableBuilder<int>(
              valueListenable: currentSelectedFilterIndex,
              builder: (context, selectedIndex, _) {
                return ValueListenableBuilder<int?>(
                  valueListenable: selectedStateId,
                  builder: (context, stateId, __) {
                    final filters = lblFilterTypesList.where((item) {
                      if (item == "City" && stateId == null) return false;
                      return true;
                    }).toList();

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: filters.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                onTap: () {
                                  currentSelectedFilterIndex.value = index;
                                },
                                selected: selectedIndex == index,
                                selectedTileColor: Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.2),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadiusDirectional.only(
                                    topStart: Radius.circular(10),
                                    bottomStart: Radius.circular(10),
                                  ),
                                ),
                                title: Text(filters[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          PositionedDirectional(
            top: 0,
            bottom: 0,
            start: SizeConfig.screenWidth * 0.4,
            end: 0,
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              margin: EdgeInsetsDirectional.only(
                start: 5,
                top: 10,
                bottom: 10,
                end: 10,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ValueListenableBuilder<int>(
                        valueListenable: currentSelectedFilterIndex,
                        builder: (context, selectedIndex, _) {
                          switch (selectedIndex) {
                            case 0:
                              return _buildCategoryWidget();
                            case 1:
                              return _buildPriceWidget();
                            case 2:
                              return _buildSortByWidget();
                            case 3:
                              return _buildStatesWidget();
                            case 4:
                              if (selectedStateId.value == null) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/nodata/no_data.png',
                                        width: SizeConfig.screenWidth * 0.22,
                                        height: SizeConfig.screenHeight * 0.12,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        "Please select a state first",
                                        style: AppTextStyles.bodyMedium(
                                          ThemeHelper.textColor(context),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              }
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
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(
            spacing: 10,
            children: [
              Expanded(
                child: CustomAppButton(
                  text: "Clear All",
                  onPlusTap: () {
                    selectedCategories.value.clear();
                    selectedSort.value = null;
                    selectedStateId.value = null;
                    selectedCityId.value = null;
                    minPriceController.clear();
                    maxPriceController.clear();
                    selectedRange.value = RangeValues(minPrice, maxPrice);
                    if (currentSelectedFilterIndex.value == 4) {
                      currentSelectedFilterIndex.value = 0;
                    }
                    context.read<ProductsCubit>().getProducts();
                  },
                ),
              ),
              Expanded(
                child: CustomAppButton1(
                  text: "Apply",
                  onPlusTap: () {
                    final filters = {
                      "categoryId": selectedCategories.value.isNotEmpty
                          ? selectedCategories.value.join(",")
                          : null,
                      "sort_by": selectedSort.value,
                      "state_id": selectedStateId.value?.toString(),
                      "city_id": selectedCityId.value?.toString(),
                      "minPrice": minPriceController.text.isNotEmpty
                          ? minPriceController.text
                          : selectedRange.value.start.toInt().toString(),
                      "maxPrice": maxPriceController.text.isNotEmpty
                          ? maxPriceController.text
                          : selectedRange.value.end.toInt().toString(),
                    };

                    context.read<ProductsCubit2>().getProducts(
                      categoryId: filters["categoryId"],
                      sort_by: filters["sort_by"],
                      state_id: filters["state_id"],
                      city_id: filters["city_id"],
                      minPrice: filters["minPrice"],
                      maxPrice: filters["maxPrice"],
                    );

                    context.pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            valueListenable: selectedCategories,
            builder: (context, selected, _) {
              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final categoryItem = categories[index];
                  final isSelected = selected.contains(
                    categoryItem.categoryId.toString(),
                  );
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      final updated = List<String>.from(selected);
                      if (val == true) {
                        updated.add(categoryItem.categoryId.toString());
                      } else {
                        updated.remove(categoryItem.categoryId.toString());
                      }
                      selectedCategories.value = updated;
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

  Widget _buildPriceWidget() {
    final priceRanges = [
      {"label": "Below Rs.1000", "min": 0, "max": 1000},
      {"label": "Rs.1001 - 5000", "min": 1001, "max": 5000},
      {"label": "Rs.5001 - 10000", "min": 5001, "max": 10000},
      {"label": "Rs.10001 - 25000", "min": 10001, "max": 25000},
      {"label": "Rs.25001 - 50000", "min": 25001, "max": 50000},
      {"label": "Above Rs.50000", "min": 50001, "max": 1000000},
    ];

    return ValueListenableBuilder<RangeValues>(
      valueListenable: selectedRange,
      builder: (context, range, _) {
        final textColor = ThemeHelper.textColor(context);
        return SingleChildScrollView(
          child: Column(
            children: [
              ...priceRanges.map((r) {
                final isSelected =
                    range.start.toInt() == r["min"] &&
                    (r["max"] == null || range.end.toInt() == r["max"]);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (val) {
                    if (val == true) {
                      selectedRange.value = RangeValues(
                        ((r["min"] as num?) ?? minPrice).toDouble(),
                        ((r["max"] as num?) ?? maxPrice).toDouble(),
                      );
                    } else {
                      selectedRange.value = RangeValues(minPrice, maxPrice);
                    }
                  },
                  title: Text(r["label"] as String,style: AppTextStyles.titleSmall(textColor),),
                );
              }).toList(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: textColor),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                      controller: minPriceController,
                      decoration: InputDecoration(
                        hintText: "Min",
                        hintStyle: TextStyle(color: textColor),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        final minVal = int.tryParse(val) ?? minPrice.toInt();
                        selectedRange.value = RangeValues(
                          minVal.toDouble(),
                          range.end,
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: textColor),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                      controller: maxPriceController,
                      decoration: InputDecoration(
                        hintText: "Max",
                        hintStyle: TextStyle(color: textColor),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        final maxVal = int.tryParse(val) ?? maxPrice.toInt();
                        selectedRange.value = RangeValues(
                          range.start,
                          maxVal.toDouble(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      valueListenable: selectedSort,
      builder: (context, sort, _) {
        return ListView(
          children: sortOptions.map((option) {
            final isSelected = sort == option["value"];
            return CheckboxListTile(
              value: isSelected,
              onChanged: (val) {
                selectedSort.value = val == true ? option["value"] : null;
              },
              title: Text(option["label"]!),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatesWidget() {
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
          final textColor = ThemeHelper.textColor(context);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
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
                            if (_debounce?.isActive ?? false)
                              _debounce!.cancel();
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
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        stateSearchController.clear();
                        context.read<SelectStatesCubit>().getSelectStates("");
                      },
                    ),
                  ],
                ),
              ),
              if (states.isEmpty)
                Center(
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
                        "No states found",
                        style: AppTextStyles.bodyMedium(
                          ThemeHelper.textColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ValueListenableBuilder<int?>(
                    valueListenable: selectedStateId,
                    builder: (context, stateId, _) {
                      return ListView.builder(
                        itemCount: states.length,
                        itemBuilder: (context, index) {
                          final s = states[index];
                          final isSelected = stateId == s.id;
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              selectedStateId.value = val == true ? s.id : null;
                              context.read<SelectCityCubit>().getSelectCity(
                                selectedStateId.value ?? 0,
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
    return Expanded(
      child: BlocBuilder<SelectCityCubit, SelectCity>(
        builder: (context, state) {
          if (state is SelectCityLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SelectCityFailure) {
            return Center(
              child: Text(
                state.error,
                style: AppTextStyles.bodyMedium(textColor),
              ),
            );
          } else if (state is SelectCityLoaded ||
              state is SelectCityLoadingMore) {
            final citiesList = (state is SelectCityLoaded)
                ? state.selectCityModel
                : (state as SelectCityLoadingMore).selectCityModel;

            final cities = citiesList.data ?? [];
            final textColor = ThemeHelper.textColor(context);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: TextField(
                            controller: cityController,
                            style: AppTextStyles.bodyMedium(textColor),
                            decoration: InputDecoration(
                              hintText: "Search city...",
                              hintStyle: AppTextStyles.bodyMedium(textColor),
                              prefixIcon: Icon(Icons.search, color: textColor),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) {
                              if (_debounce?.isActive ?? false)
                                _debounce!.cancel();
                              _debounce = Timer(
                                const Duration(milliseconds: 500),
                                () {
                                  context.read<SelectCityCubit>().getSelectCity(
                                    selectedStateId.value ?? 0,
                                    value,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          cityController.clear();
                          context.read<SelectCityCubit>().getSelectCity(
                            selectedStateId.value ?? 0,
                            "",
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (cities.isEmpty)
                  Center(
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
                          "No cities found",
                          style: AppTextStyles.bodyMedium(
                            ThemeHelper.textColor(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: ValueListenableBuilder<int?>(
                      valueListenable: selectedCityId,
                      builder: (context, cityId, _) {
                        return NotificationListener<ScrollNotification>(
                          onNotification: (scrollInfo) {
                            if (scrollInfo.metrics.pixels >=
                                    scrollInfo.metrics.maxScrollExtent * 0.9 &&
                                state is SelectCityLoaded &&
                                state.hasNextPage) {
                              context.read<SelectCityCubit>().getMoreCities(
                                selectedStateId.value ?? 0,
                                cityController.text,
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
                                  padding: EdgeInsets.all(16.0),
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
                                  selectedCityId.value = val == true
                                      ? c.id
                                      : null;
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
                    ),
                  ),
              ],
            );
          }

          return const Center(child: Text("No Data"));
        },
      ),
    );
  }
}
