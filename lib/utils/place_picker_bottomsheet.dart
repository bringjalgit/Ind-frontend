import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// ⬇️ bring your helpers
import '../theme/ThemeHelper.dart'; // adjust path
import '../theme/AppTextStyles.dart'; // adjust path

class PickedPlace {
  final String placeId;
  final String description;
  final String? formattedAddress;
  final double lat;
  final double lng;

  const PickedPlace({
    required this.placeId,
    required this.description,
    required this.lat,
    required this.lng,
    this.formattedAddress,
  });
}

Future<PickedPlace?> openPlacePickerBottomSheet({
  required BuildContext context,
  required String googleApiKey,
  required TextEditingController controller,
  bool appendToExisting = false,
  String? initialQuery,
  String? components,
  String language = 'en',
  String? stateName, // New parameter
}) {
  return showModalBottomSheet<PickedPlace>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlacePickerSheet(
      apiKey: googleApiKey,
      controllerToUpdate: controller,
      appendToExisting: appendToExisting,
      initialQuery: initialQuery ?? controller.text.trim(),
      components: components,
      language: language,
      stateName: stateName, // Pass stateNam
    ),
  );
}

class _PlacePickerSheet extends StatefulWidget {
  final String apiKey;
  final TextEditingController controllerToUpdate;
  final bool appendToExisting;
  final String initialQuery;
  final String? components;
  final String language;
  final String? stateName; // New parameter for state name

  const _PlacePickerSheet({
    required this.apiKey,
    required this.controllerToUpdate,
    required this.appendToExisting,
    required this.initialQuery,
    this.components,
    required this.language,
    this.stateName, // Add stateName
  });

  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  List<_Prediction> _predictions = [];
  bool _loading = false;
  String _sessionToken = _randomSessionToken();
  Timer? _debounce;
  CancelToken? _runningToken;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialQuery;
    if (_searchCtrl.text.trim().isNotEmpty) {
      _fetchPredictions(_searchCtrl.text.trim());
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _runningToken?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _error = null;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchPredictions(value.trim());
    });
    setState(() {});
  }

  Future<void> _fetchPredictions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _error = null;
      });
      return;
    }

    _runningToken?.cancel("New query issued");
    _runningToken = CancelToken();

    setState(() {
      _loading = true;
      _error = null;
    });

    const url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    final params = <String, dynamic>{
      'input': widget.stateName != null && widget.stateName!.isNotEmpty
          ? '$query, ${widget.stateName}' // Append state name to query
          : query,
      'key': widget.apiKey,
      'sessiontoken': _sessionToken,
      'language': widget.language,
    };
    if (widget.components?.isNotEmpty == true) {
      params['components'] = widget.components;
    }

    try {
      final resp = await _dio.get(
        url,
        queryParameters: params,
        cancelToken: _runningToken,
      );
      final data = resp.data as Map<String, dynamic>?;

      if (data == null) throw Exception("Empty response");
      final status = data['status'] as String? ?? 'UNKNOWN_ERROR';
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        throw Exception(data['error_message'] ?? status);
      }

      var preds = (data['predictions'] as List<dynamic>? ?? [])
          .map((e) => _Prediction.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filter predictions by state name if provided
      if (widget.stateName != null && widget.stateName!.isNotEmpty) {
        final stateNameLower = widget.stateName!.toLowerCase();
        preds = preds.where((p) {
          final descriptionLower = p.description.toLowerCase();
          final secondaryTextLower = p.secondaryText?.toLowerCase() ?? '';
          return descriptionLower.contains(stateNameLower) ||
              secondaryTextLower.contains(stateNameLower);
        }).toList();
      }
      setState(() {
        _predictions = preds;
        _loading = false;
        _error = (status == 'ZERO_RESULTS') ? 'No places found' : null;
      });
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      setState(() {
        _loading = false;
        _error = e.message ?? 'Network error';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Unexpected error';
      });
    }
  }

  Future<void> _pickPrediction(_Prediction p) async {
    const detailsUrl =
        'https://maps.googleapis.com/maps/api/place/details/json';
    final params = {
      'place_id': p.placeId,
      'fields': 'formatted_address,geometry/location,name',
      'key': widget.apiKey,
      'sessiontoken': _sessionToken,
      'language': widget.language,
    };

    try {
      setState(() => _loading = true);
      final resp = await _dio.get(detailsUrl, queryParameters: params);
      final data = resp.data as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'UNKNOWN_ERROR';
      if (status != 'OK') throw Exception(data['error_message'] ?? status);

      final result = data['result'] as Map<String, dynamic>;
      final loc =
          (result['geometry']?['location'] ?? {}) as Map<String, dynamic>;
      final lat = (loc['lat'] as num?)?.toDouble();
      final lng = (loc['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) throw Exception('Location not available');
      final formatted = result['formatted_address'] as String?;

      final picked = PickedPlace(
        placeId: p.placeId,
        description: p.description,
        formattedAddress: formatted,
        lat: lat,
        lng: lng,
      );

      // Update your external controller using append/replace behavior
      final existing = widget.controllerToUpdate.text.trim();
      widget.controllerToUpdate.text =
          (widget.appendToExisting && existing.isNotEmpty)
          ? '$existing, ${picked.description}'
          : picked.description;

      widget.controllerToUpdate.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controllerToUpdate.text.length),
      );

      if (mounted) Navigator.of(context).pop(picked);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to fetch details';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = ThemeHelper.backgroundColor(context);
    final textColor = ThemeHelper.textColor(context);
    final cardColor = ThemeHelper.cardColor(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  ThemeHelper.isDarkMode(context) ? 0.4 : 0.12,
                ),
                blurRadius: 22,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              // Grab handle
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),

              // Header
              Row(
                children: [
                  Icon(Icons.place_outlined, color: textColor.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Text(
                    'Search Location',
                    style: AppTextStyles.titleLarge(
                      textColor,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: textColor),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Search field styled with your theme
              Container(
                decoration: BoxDecoration(
                  color: ThemeHelper.isDarkMode(context)
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: ThemeHelper.isDarkMode(context)
                        ? Colors.white10
                        : Colors.black12,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: textColor.withOpacity(0.8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _focusNode,
                        onChanged: _onChanged,
                        style: AppTextStyles.bodyLarge(textColor),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Type area, landmark, city...',
                          hintStyle: AppTextStyles.bodyMedium(
                            textColor.withOpacity(0.6),
                          ),
                          isDense: true,
                          fillColor: ThemeHelper.isDarkMode(context)
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade100,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          errorStyle: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          _onChanged('');
                        },
                        icon: Icon(
                          Icons.clear_rounded,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Results
              Expanded(
                child: _loading && _predictions.isEmpty
                    ? const _ShimmerList()
                    : (_error != null
                          ? Center(
                              child: Text(
                                _error!,
                                style: AppTextStyles.bodyLarge(textColor),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: _predictions.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: ThemeHelper.isDarkMode(context)
                                    ? Colors.white10
                                    : Colors.black12,
                              ),
                              itemBuilder: (_, i) {
                                final p = _predictions[i];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        ThemeHelper.isDarkMode(context)
                                        ? const Color(0xFF2F2F2F)
                                        : Colors.grey.shade200,
                                    child: Icon(
                                      Icons.location_on_outlined,
                                      size: 20,
                                      color: textColor,
                                    ),
                                  ),
                                  title: Text(
                                    p.primaryText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.titleMedium(textColor),
                                  ),
                                  subtitle:
                                      (p.secondaryText?.isNotEmpty ?? false)
                                      ? Text(
                                          p.secondaryText!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodySmall(
                                            textColor.withOpacity(0.8),
                                          ),
                                        )
                                      : null,
                                  onTap: () => _pickPrediction(p),
                                );
                              },
                            )),
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _Prediction {
  final String placeId;
  final String description;
  final String primaryText;
  final String? secondaryText;

  _Prediction({
    required this.placeId,
    required this.description,
    required this.primaryText,
    this.secondaryText,
  });

  factory _Prediction.fromJson(Map<String, dynamic> json) {
    final primary =
        json['structured_formatting']?['main_text'] as String? ??
        (json['terms'] is List && (json['terms'] as List).isNotEmpty
            ? (((json['terms'] as List).first as Map)['value'] as String? ?? '')
            : '');
    final secondary =
        json['structured_formatting']?['secondary_text'] as String?;
    return _Prediction(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      primaryText: primary ?? '',
      secondaryText: secondary,
    );
  }
}

// Minimal shimmer using theme
class _ShimmerList extends StatelessWidget {
  const _ShimmerList({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeHelper.isDarkMode(context)
        ? const Color(0xFF2A2A2A)
        : Colors.black12.withOpacity(0.06);
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (_, __) => Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

String _randomSessionToken() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final r = Random.secure();
  return List.generate(22, (_) => chars[r.nextInt(chars.length)]).join();
}
