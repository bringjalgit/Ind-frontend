import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/cubit/States/states_cubit.dart';
import '../data/cubit/States/states_state.dart';
import '../theme/AppTextStyles.dart';
import '../theme/ThemeHelper.dart';
import '../utils/media_query_helper.dart';

class SelectStateBottomSheet extends StatefulWidget {
  const SelectStateBottomSheet({Key? key}) : super(key: key);

  @override
  State<SelectStateBottomSheet> createState() => _SelectStateBottomSheetState();
}

class _SelectStateBottomSheetState extends State<SelectStateBottomSheet> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SelectStatesCubit>();
    cubit.getSelectStates(""); // fetch on open

    final textColor = ThemeHelper.textColor(context);
    final bgColor = ThemeHelper.backgroundColor(context);

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                "Select State",
                style: AppTextStyles.headlineSmall(
                  textColor,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                style: AppTextStyles.bodyMedium(textColor),
                decoration: InputDecoration(
                  hintText: "Search state...",
                  hintStyle: AppTextStyles.bodyMedium(
                    textColor.withOpacity(0.6),
                  ),
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
                    cubit.getSelectStates(value);
                  });
                },
              ),
            ),

            const SizedBox(height: 10),

            // ---- List of States ----
            Expanded(
              child: BlocBuilder<SelectStatesCubit, SelectStates>(
                builder: (context, state) {
                  if (state is SelectStatesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is SelectStatesFailure) {
                    return Center(
                      child: Text(
                        state.error,
                        style: AppTextStyles.bodyMedium(textColor),
                      ),
                    );
                  } else if (state is SelectStatesLoaded) {
                    final states = state.selectStatesModel.data ?? [];

                    if (states.isEmpty) {
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
                              "No states found",
                              style: AppTextStyles.bodyMedium(
                                ThemeHelper.textColor(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }


                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: CustomScrollView(
                        slivers: [
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = states[index];
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
                                    Navigator.pop(context, item);
                                  },
                                ),
                              );
                            }, childCount: states.length),
                          ),
                        ],
                      ),
                    );
                  }
                  return Center(
                    child: Text(
                      "Type to search states",
                      style: AppTextStyles.bodyMedium(textColor),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isDarkMode(BuildContext context) => ThemeHelper.isDarkMode(context);
}
