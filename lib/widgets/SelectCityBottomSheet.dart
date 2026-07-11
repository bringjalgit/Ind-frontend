import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/cubit/City/city_cubit.dart';
import '../data/cubit/City/city_state.dart';
import '../theme/AppTextStyles.dart';
import '../theme/ThemeHelper.dart';
import '../utils/media_query_helper.dart';

// ---- BottomSheet for Cities ----
class SelectCityBottomSheet extends StatefulWidget {
  final int stateId; // Pass selected stateId

  const SelectCityBottomSheet({Key? key, required this.stateId})
    : super(key: key);

  @override
  State<SelectCityBottomSheet> createState() => _SelectCityBottomSheetState();
}

class _SelectCityBottomSheetState extends State<SelectCityBottomSheet> {
  final cityController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SelectCityCubit>();
    cubit.getSelectCity(widget.stateId, ""); // fetch on open

    final textColor = ThemeHelper.textColor(context);
    final bgColor = ThemeHelper.backgroundColor(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Drag Handle ----
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              height: 5,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // ---- Title ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Select City",
              style: AppTextStyles.headlineSmall(
                textColor,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          // ---- Search Bar ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              style: AppTextStyles.bodyMedium(textColor),
              controller: cityController,
              decoration: InputDecoration(
                hintText: "Search city...",
                hintStyle: AppTextStyles.bodyMedium(textColor.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: textColor),
                filled: true,
                fillColor: isDarkMode(context)
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  cubit.getSelectCity(widget.stateId, value);
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
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
                      ? (state as SelectCityLoaded).selectCityModel
                      : (state as SelectCityLoadingMore).selectCityModel;
                  final cities = citiesList.data ?? [];

                  if (cities.isEmpty) {
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
                            "No cities found",
                            style: AppTextStyles.bodyMedium(
                              ThemeHelper.textColor(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent * 0.9) {
                        if (state is SelectCityLoaded && state.hasNextPage) {
                          context.read<SelectCityCubit>().getMoreCities(
                            widget.stateId,
                            cityController.text,
                          );
                        }
                        return false;
                      }
                      return false;
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: CustomScrollView(
                        slivers: [
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = cities[index];
                              return Card(
                                color: isDarkMode(context)
                                    ? Colors.grey.shade900
                                    : Colors.white,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 5,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  title: Text(
                                    item.name ?? "",
                                    style: AppTextStyles.titleMedium(
                                      textColor,
                                    ).copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: textColor.withOpacity(0.6),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context, item); // return city
                                  },
                                ),
                              );
                            }, childCount: cities.length),
                          ),
                          if (state is SelectCityLoadingMore)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 0.8,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }
                return Center(
                  child: Text(
                    "Type to search cities",
                    style: AppTextStyles.bodyMedium(textColor),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool isDarkMode(BuildContext context) => ThemeHelper.isDarkMode(context);
}
