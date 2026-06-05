import 'dart:async';

import 'package:classifieds/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/cubit/Location/location_cubit.dart';
import '../presentation/views/HoliHomeScreen.dart';
import '../presentation/views/Home.dart';
import '../theme/AppTextStyles.dart';
import '../theme/ThemeHelper.dart';

class LocationSelectionSheet extends StatefulWidget {
  const LocationSelectionSheet();

  @override
  State<LocationSelectionSheet> createState() => _LocationSelectionSheetState();
}

class Prediction {
  final String placeId;
  final String mainText;
  final String? secondaryText;

  Prediction({
    required this.placeId,
    required this.mainText,
    this.secondaryText,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      placeId: json["place_id"],
      mainText: json["structured_formatting"]["main_text"],
      secondaryText: json["structured_formatting"]["secondary_text"],
    );
  }
}

class _LocationSelectionSheetState extends State<LocationSelectionSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Dio _dio = Dio();

  List<Prediction> _predictions = [];
  bool _loading = false;
  Timer? _debounce;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchPredictions(value);
    });
  }

  Future<void> _fetchPredictions(String input) async {
    if (input.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    setState(() => _loading = true);

    final url = "https://maps.googleapis.com/maps/api/place/autocomplete/json";

    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          "input": input,
          "key": google_map_key,
          "components": "country:in",
        },
      );

      final data = response.data;
      final status = data["status"];

      if (status == "OK") {
        final preds = (data["predictions"] as List)
            .map((e) => Prediction.fromJson(e))
            .toList();

        setState(() {
          _predictions = preds;
          _loading = false;
        });
      } else {
        setState(() {
          _predictions = [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _predictions = [];
        _loading = false;
      });
    }
  }

  Future<void> _selectPrediction(Prediction p) async {
    final detailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json";

    final response = await _dio.get(
      detailsUrl,
      queryParameters: {
        "place_id": p.placeId,
        "fields": "formatted_address,geometry/location",
        "key": google_map_key,
      },
    );

    final result = response.data["result"];
    final location = result["geometry"]["location"];

    final lat = location["lat"];
    final lng = location["lng"];

    Navigator.pop(
      context,
      SelectedLocation(name: result["formatted_address"], latlng: "$lat,$lng"),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);
    final cardColor = ThemeHelper.cardColor(context);
    final isDark = ThemeHelper.isDarkMode(context);

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                  blurRadius: 22,
                  spreadRadius: 4,
                )
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                /// Drag Handle
                Container(
                  width: 45,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),

                /// Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: textColor),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Location",
                      style: AppTextStyles.titleLarge(textColor)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _searchCtrl,
                  onChanged: (value) {
                    _onSearchChanged(value);
                    setState(() {});
                  },
                  style: AppTextStyles.bodyLarge(textColor),
                  decoration: InputDecoration(
                    hintText: "Search city, area or neighbourhood",
                    hintStyle:
                    AppTextStyles.bodyMedium(textColor.withOpacity(0.5)),

                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade100,

                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),

                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: textColor.withOpacity(0.7),
                    ),

                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: textColor.withOpacity(0.7),
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                        setState(() {});
                      },
                    )
                        : null,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// RESULTS SECTION
                Expanded(
                  child: _searchCtrl.text.isNotEmpty
                      ? _loading
                      ? Center(
                    child: CircularProgressIndicator(
                      color: textColor,
                    ),
                  )
                      : _predictions.isEmpty
                      ? Center(
                    child: Text(
                      "No places found",
                      style: AppTextStyles.bodyLarge(textColor),
                    ),
                  )
                      : ListView.separated(
                    controller: controller,
                    itemCount: _predictions.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white10
                          : Colors.black12,
                    ),
                    itemBuilder: (_, i) {
                      final p = _predictions[i];
                      return ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark
                              ? const Color(0xFF2F2F2F)
                              : Colors.grey.shade200,
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: textColor,
                          ),
                        ),
                        title: Text(
                          p.mainText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium(
                              textColor),
                        ),
                        subtitle:
                        (p.secondaryText?.isNotEmpty ??
                            false)
                            ? Text(
                          p.secondaryText!,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          AppTextStyles.bodySmall(
                            textColor.withOpacity(0.7),
                          ),
                        )
                            : null,
                        onTap: () =>
                            _selectPrediction(p),
                      );
                    },
                  )
                      : ListView(
                    controller: controller,
                    children: [
                      ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        leading: Icon(
                          Icons.my_location,
                          color: Colors.blue,
                        ),
                        title: Text(
                          "Use current location",
                          style: AppTextStyles.titleMedium(
                              Colors.blue)
                              .copyWith(
                              fontWeight:
                              FontWeight.w600),
                        ),
                        onTap: () {
                          context
                              .read<LocationCubit>()
                              .requestLocationPermission();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
